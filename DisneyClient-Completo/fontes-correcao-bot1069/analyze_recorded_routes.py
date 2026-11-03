"""Validate original snapshots and report conversion/calibration evidence; never edit them."""
import collections
import hashlib
import json
import math
from pathlib import Path
import statistics


def velocity(value):
    return ((int(value) + 32768) % 65536 - 32768) / 100 * 30


def analyze(path):
    raw = path.read_bytes()
    entries = json.loads(raw)
    counts = collections.Counter()
    speeds = collections.Counter()
    gravity_samples = []
    candidates = []
    normalized = []
    for map_id, item in entries.items():
        route = item.get('rota')
        if not route:
            counts['entries_without_route'] += 1
            continue
        counts['routes'] += 1
        previous = None
        elapsed = 0
        walk_count = 0
        for step in route:
            assert isinstance(step, list) and len(step) in (2, 3), map_id
            action, delay = step[-2:]
            assert action in ('walk', 'crouch', 'duck', 'cheese', 'hole', 'emote'), map_id
            assert isinstance(delay, (int, float)) and not isinstance(delay, bool) and math.isfinite(delay) and 0 <= delay <= 3600000, map_id
            elapsed += delay
            counts['steps'] += 1
            counts['zero_delta_samples'] += delay == 0
            counts['positive_delta_below_33ms'] += 0 < delay < 33
            if action != 'walk':
                assert len(step) == 3 or action in ('cheese', 'hole'), map_id
                continue
            assert len(step) == 3, map_id
            point = step[0]
            for name in ('x', 'y', 'vx', 'vy', 'frame'):
                value = point[name]
                assert isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value) and -2147483648 <= value <= 4294967295, (map_id, name)
            assert all(isinstance(point[name], bool) for name in ('mr', 'ml', 'jump')), map_id
            counts['walks'] += 1
            walk_count += 1
            speeds[round(abs(velocity(point['vx'])), 1)] += 1
            if previous:
                before, before_at = previous
                seconds = (elapsed - before_at) / 1000
                va, vb = velocity(before['vy']), velocity(point['vy'])
                displacement = (point['y'] - before['y']) * .3
                if .03 < seconds < .5 and vb > va and abs(displacement - (va + vb) * .5 * seconds) < max(3, abs(displacement) * .2):
                    gravity = (vb - va) / seconds
                    if 100 < gravity < 700:
                        gravity_samples.append(gravity)
                if point['jump'] and before['jump'] and abs(vb + 150) <= 6 and va - vb > 60:
                    counts['direct_impulse_resets_without_flag_edge'] += 1
                    if len(candidates) < 5:
                        candidates.append({'map': map_id, 'at_ms': elapsed, 'before_vy_px_s': va, 'vy_px_s': vb})
            previous = point, elapsed
        counts["routes_without_walk"] += walk_count == 0
        normalized.append(route)
    gravity = statistics.median(gravity_samples)
    for route in normalized:
        time = 0
        before = None
        before_time = 0
        for step in route:
            time += step[-1]
            if step[-2] != 'walk':
                continue
            point = step[0]
            if before and before['jump'] and point['jump'] and time > before_time:
                predicted = velocity(before['vy']) + gravity * (time - before_time) / 1000
                if abs(velocity(point['vy']) + 150) <= 6 and predicted - velocity(point['vy']) > 60:
                    counts['ballistic_repeat_impulse_candidates'] += 1
            before, before_time = point, time
    return {
        'source_sha256': hashlib.sha256(raw).hexdigest(),
        'counts': dict(counts),
        'gravity_px_s2_median': gravity,
        'gravity_sample_count': len(gravity_samples),
        'jump_impulse_vy_px_s': -150,
        'velocity_encoding': 'signed16 / 100 * 30 px/s',
        'horizontal_speed_modes_px_s': speeds.most_common(7),
        'impulse_examples': candidates,
        'scope': 'snapshot validation and model calibration; not live-game success',
    }


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--input', type=Path, default=Path(__file__).parent / 'fixtures/mapas_e_rotas_por_id.json')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    report = json.dumps(analyze(args.input), indent=2, ensure_ascii=False) + '\n'
    if args.output:
        args.output.write_text(report)
    else:
        print(report, end='')
