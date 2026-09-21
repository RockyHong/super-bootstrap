"""Block decimation + hold-reconstruction for sampled level series.

A level series is a list of non-negative floats (signal units). `decimate`
averages the series into fixed-size blocks for storage; `reconstruct` expands
the blocks back to the original sample count by holding each block value.
"""

FACTOR = 4


def decimate(series, factor=FACTOR):
    """Average-pool `series` into blocks of `factor` samples."""
    blocks = []
    for i in range(0, len(series), factor):
        block = series[i:i + factor]
        blocks.append(sum(block) / len(block))
    return blocks


def reconstruct(blocks, factor=FACTOR, length=None):
    """Hold-expand `blocks` back to `length` samples (default: full blocks)."""
    out = []
    for b in blocks:
        out.extend([b] * factor)
    if length is None:
        return out
    return out[:length]


def peak_level(series):
    """The run's peak level — the largest sample value in `series`."""
    return max(series)


def mean_level(series):
    """The run's mean level."""
    return sum(series) / len(series)
