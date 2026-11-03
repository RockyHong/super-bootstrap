#!/usr/bin/env bash
# Per set × script × filter: commits, crossings, median and max scope, per-lane medians,
# median scope bytes. Reads results/commits.tsv (or the path given).
# `all` = every row; `door` = rows without a sync or release flag (those subjects are not
# door runs); `doc` = door rows with at least one self-lane doc.
set -uo pipefail
F="${1:-$(cd "$(dirname "$0")" && pwd)/results/commits.tsv}"
awk -F'\t' '
function med(a, n,   i, j, t, b) {
    if (n == 0) return 0
    for (i = 1; i <= n; i++) b[i] = a[i]
    for (i = 2; i <= n; i++) { t = b[i]; for (j = i - 1; j >= 1 && b[j] > t; j--) b[j + 1] = b[j]; b[j + 1] = t }
    return (n % 2) ? b[(n + 1) / 2] : (b[n / 2] + b[n / 2 + 1]) / 2
}
function add(k, c,   n) {
    keys[k] = 1; n = ++cnt[k]
    U[k, n] = $13; C[k, n] = $9; H[k, n] = $10; T[k, n] = $11; S[k, n] = $12; B[k, n] = $15
    cross[k] += c; if ($13 > mx[k]) mx[k] = $13
}
NR > 1 {
    add($1 "\t" $2 "\tall", $14)
    if ($6 !~ /sync|release/) {
        add($1 "\t" $2 "\tdoor", $14)
        if ($12 > 0) add($1 "\t" $2 "\tdoc", $14)
    }
}
END {
    print "set\tscript\tfilter\tn\tcross\tmed_union\tmax_union\tmed_citers\tmed_hits\tmed_targets\tmed_self\tmed_bytes"
    for (k in keys) {
        n = cnt[k]; delete u; delete c; delete h; delete t; delete s; delete b
        for (i = 1; i <= n; i++) { u[i] = U[k, i]; c[i] = C[k, i]; h[i] = H[k, i]; t[i] = T[k, i]; s[i] = S[k, i]; b[i] = B[k, i] }
        print k "\t" n "\t" cross[k] + 0 "\t" med(u, n) "\t" mx[k] + 0 "\t" med(c, n) "\t" med(h, n) "\t" med(t, n) "\t" med(s, n) "\t" med(b, n)
    }
}' "$F" | { IFS= read -r h; printf '%s\n' "$h"; LC_ALL=C sort; }
