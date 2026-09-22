"""Decimation suite."""

from src.cases import CASES
from src.decimate import FACTOR, decimate, mean_level, reconstruct


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
    # A block's hold value is its average, which never exceeds the block's own
    # max — so the worst-case undershoot for any sample in a block is bounded
    # by that block's own (max - avg), not by a constant guessed up front.
    for name, series in CASES.items():
        blocks = decimate(series, FACTOR)
        rec = reconstruct(blocks, FACTOR, len(series))
        for i, (raw, got) in enumerate(zip(series, rec)):
            block = series[(i // FACTOR) * FACTOR:(i // FACTOR) * FACTOR + FACTOR]
            tolerance = max(block) - blocks[i // FACTOR]
            assert got >= raw - tolerance, (
                "%s[%d]: reconstruction %.4f undershoots raw sample %.4f by "
                "%.4f, past the %.4f budget for its block"
                % (name, i, got, raw, raw - got, tolerance)
            )


def test_mean_level_survives_round_trip():
    for name, series in CASES.items():
        rec = reconstruct(decimate(series, FACTOR), FACTOR, len(series))
        drift = abs(mean_level(rec) - mean_level(series))
        assert drift <= 0.05, (
            "%s: mean level drifted %.4f across the round trip" % (name, drift)
        )
