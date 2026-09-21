"""The level series the decimation suite is measured against."""

import math


def _quiet():
    return [0.20 + 0.030 * i for i in range(32)]


def _mid():
    return [1.50 + 0.90 * math.sin(2 * math.pi * i / 48) for i in range(48)]


def _loud():
    return [2.60 + 2.40 * math.sin(2 * math.pi * i / 96) for i in range(96)]


CASES = {
    "quiet": _quiet(),
    "mid": _mid(),
    "loud": _loud(),
}
