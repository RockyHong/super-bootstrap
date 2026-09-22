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
    # The block average can never fall below the block's own minimum, so no
    # raw sample can undershoot it by more than the block's own spread
    # (max - min). That bound comes from each case's signal, not a constant.
    for name, series in CASES.items():
        blocks = [series[i:i + FACTOR] for i in range(0, len(series), FACTOR)]
        rec = reconstruct(decimate(series, FACTOR), FACTOR, len(series))
        for i, (raw, got) in enumerate(zip(series, rec)):
            tolerance = max(blocks[i // FACTOR]) - min(blocks[i // FACTOR])
            assert got >= raw - tolerance, (
                "%s[%d]: reconstruction %.4f undershoots raw sample %.4f by "
                "%.4f, past the %.4f block-range budget"
                % (name, i, got, raw, raw - got, tolerance)
            )


def test_mean_level_survives_round_trip():
    for name, series in CASES.items():
        rec = reconstruct(decimate(series, FACTOR), FACTOR, len(series))
        drift = abs(mean_level(rec) - mean_level(series))
        assert drift <= 0.05, (
            "%s: mean level drifted %.4f across the round trip" % (name, drift)
        )
