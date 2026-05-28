#!/usr/bin/env python3
"""Drive oracle session + my emulator with identical inputs; compare framebuffers.

Usage: validate.py <rom> <frames> [schedule]
  schedule: comma-separated frame:hexkeys, e.g. "100:0x008,106:0,200:0x001,205:0"
Compares at checkpoints every ~max(30,frames//10).
"""
import sys, os, subprocess, json, struct

def read_ppm(p):
    d = open(p, 'rb').read()
    idx = 2; v = []
    while len(v) < 3:
        while d[idx] in b' \t\n\r': idx += 1
        s = idx
        while d[idx] not in b' \t\n\r': idx += 1
        v.append(int(d[s:idx]))
    return d[idx+1:]

def main():
    rom = sys.argv[1]
    frames = int(sys.argv[2])
    sched = []
    if len(sys.argv) > 3 and sys.argv[3]:
        for tok in sys.argv[3].split(','):
            f, k = tok.split(':')
            sched.append((int(f), int(k, 16) if k.startswith('0x') else int(k)))
    sched.sort()

    # Write replay file for my harness.
    replay = '/tmp/val_replay.txt'
    with open(replay, 'w') as fh:
        for f, k in sched:
            fh.write(f"{f} 0x{k:03x}\n")

    ckpt = max(30, frames // 10)
    checkpoints = list(range(ckpt-1, frames, ckpt))
    if frames-1 not in checkpoints: checkpoints.append(frames-1)

    # Run mine.
    mine_dir = '/tmp/val_mine'
    os.system(f'rm -rf {mine_dir}')
    env = dict(os.environ, ALLF='1')
    subprocess.run(['cargo','run','--release','--quiet','--example','cmp','--',
                    rom, str(frames), mine_dir, replay], env=env,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

    # Drive oracle session.
    def osess(*args):
        return subprocess.run(['oracle','session',*args], capture_output=True).stdout
    sid = json.loads(osess('start', rom))['id']
    cur = 0
    keys = 0
    si = 0
    results = {}
    # Build per-frame: run frame by frame? Too slow. Run in segments split by sched+checkpoints.
    events = sorted(set([f for f,_ in sched] + [c+1 for c in checkpoints] + [frames]))
    # We'll step the session, applying key changes, and capture at checkpoints.
    keymap = {f:k for f,k in sched}
    # Capture happens AFTER running frame c (i.e., after c+1 frames executed).
    # Boundaries: apply key at frame f BEFORE running it; capture after frame c.
    boundaries = sorted(set([f for f,_ in sched] + [c+1 for c in checkpoints] + [0]))
    cap_after = {c+1: c for c in checkpoints}  # after running up to frame c+1 total
    executed = 0
    while executed < frames:
        if executed in keymap:
            osess('set-keys', sid, f'0x{keymap[executed]:x}')
        # find next stop: next key change or next capture point
        nexts = [f for f,_ in sched if f > executed] + [c+1 for c in checkpoints if c+1 > executed] + [frames]
        stop = min(nexts)
        n = stop - executed
        osess('run-frame', sid, str(n))
        executed = stop
        # if we just finished a checkpoint frame
        cframe = executed - 1
        if cframe in checkpoints:
            fb = subprocess.run(['oracle','session','framebuffer',sid], capture_output=True).stdout
            results[cframe] = fb
    osess('end', sid)

    # Compare.
    worst = 0
    for c in checkpoints:
        mf = f'{mine_dir}/frame_{c:05d}.ppm'
        if c not in results or not os.path.exists(mf):
            print(f'f{c}: MISSING'); continue
        ob = results[c]
        m = read_ppm(mf)
        diff = 0
        for i in range(240*160):
            if (ob[i*4],ob[i*4+1],ob[i*4+2]) != (m[i*3],m[i*3+1],m[i*3+2]):
                diff += 1
        worst = max(worst, diff)
        print(f'f{c}: {diff}/38400 ({100*diff/38400:.2f}%)')
    print(f'WORST: {worst} ({100*worst/38400:.2f}%)')

main()
