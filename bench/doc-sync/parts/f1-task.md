## Your job

Judge the five scope docs against the diff above — does any of them narrate a posture, default, or contract that this diff makes stale or under-specified? Then run the diff-scoped new-assertion residual over the diff's new asserting lines.

Return `stale-docs` with path + what looks outdated + the relevant diff hunk per candidate, or `clean`.
