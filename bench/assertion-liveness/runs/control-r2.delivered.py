"""Decimation suite."""

from src.cases import CASES
from src.decimate import FACTOR, decimate, mean_level, reconstruct

# Float-comparison slack only, not a domain tolerance — the bound itself is
# measured per block below.
FLOAT_EPSILON = 1e-9


def test_decimate_block_count():
    for name, series in CASES.items():
        blocks = decimate(series, FACTOR)
        expected = (len(series) + FACTOR - 1) // FACTOR
        assert len(blocks) == expected, (
            "%s: decimate produced %d blocks, expected %d"
            % (name, len(blocks), expected)
        )


def test_reconstruct_restores_length():
    for name, series in CASES.items():
        rec = reconstruct(decimate(series, FACTOR), FACTOR, len(series))
        assert len(rec) == len(series), (
            "%s: reconstruct produced %d samples, expected %d"
            % (name, len(rec), len(series))
        )


def test_reconstruction_never_undershoots():
    # A held block average can only undershoot a raw sample by that sample's
    # own block spread (its block's peak minus the block's mean) — derive the
    # budget from each block instead of a fixed constant.
    for name, series in CASES.items():
        blocks = decimate(series, FACTOR)
        rec = reconstruct(blocks, FACTOR, len(series))
        for i, (raw, got) in enumerate(zip(series, rec)):
            start = (i // FACTOR) * FACTOR
            block = series[start:start + FACTOR]
            budget = max(block) - mean_level(block)
            assert got >= raw - budget - FLOAT_EPSILON, (
                "%s[%d]: reconstruction %.4f undershoots raw sample %.4f by "
                "%.4f, past the %.4f block-spread budget"
                % (name, i, got, raw, raw - got, budget)
            )


def test_mean_level_survives_round_trip():
    for name, series in CASES.items():
        rec = reconstruct(decimate(series, FACTOR), FACTOR, len(series))
        drift = abs(mean_level(rec) - mean_level(series))
        assert drift <= 0.05, (
            "%s: mean level drifted %.4f across the round trip" % (name, drift)
        )
