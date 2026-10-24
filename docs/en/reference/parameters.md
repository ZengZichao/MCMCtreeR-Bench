# Parameter reference

## Analysis types

| GUI label | Upstream value | Required input |
| --- | --- | --- |
| MCMCtree | `MCMCtree` | FigTree output or posterior table + tree |
| MrBayes | `MrBayes` | `.con.tre` and run files |
| RevBayes | `RevBayes` | Nexus and `.trees` files |
| User | `User` | time tree and node-age table |

## Module A distributions

| Distribution | Function | Parameters |
| --- | --- | --- |
| `cauchy` | `estimateCauchy` | `scale`, `offset`, `minProb`, `maxProb`, `estimateScale` |
| `skewT` | `estimateSkewT` | `shape`, `scale`, `df`, `addMode`, `minProb`, `maxProb`, `estimateScale`, `estimateShape`, `estimateMode` |
| `skewNormal` | `estimateSkewNormal` | `shape`, `scale`, `addMode`, `minProb`, `maxProb`, `estimateScale`, `estimateShape`, `estimateMode` |
| `gamma` | `estimateGamma` | `alpha`, `beta`, `offset`, `estimateAlpha`, `estimateBeta` |
| `bound` | `estimateBound` | `minProb`, `rightTail` |
| `upper` | `estimateUpper` | `rightTail` |
| `fixed` | `estimateFixed` | none |

## Module A advanced parameters

| Parameter | Type | Default | Range |
| --- | --- | --- | --- |
| `scale` | numeric | 1.5 | > 0 |
| `offset` | numeric | 50 or 0.1 | >= 0 |
| `shape` | numeric | 50 | > 0 |
| `df` | numeric | 1 | > 0 |
| `alpha` | numeric | 188 | > 0 |
| `beta` | numeric | 2690 | > 0 |
| `minProb` | numeric | 0, 0.003 or 0.025 | 0 to 1 |
| `maxProb` | numeric | 0.975 | 0 to 1 |
| `rightTail` | numeric | 0.025 | 0 to 1 |
| `addMode` | numeric | 0 | >= 0 |
| `estimateScale` | logical | `TRUE` | `TRUE` / `FALSE` |
| `estimateShape` | logical | `FALSE` | `TRUE` / `FALSE` |
| `estimateMode` | logical | `FALSE` | `TRUE` / `FALSE` |
| `estimateAlpha` | logical | `TRUE` | `TRUE` / `FALSE` |
| `estimateBeta` | logical | `FALSE` | `TRUE` / `FALSE` |

## Module B parameters

| Group | Parameters |
| --- | --- |
| Data source | `analysis.type`, `MCMC.chain`, `node.ages`, `directory.files`, `build.tree` |
| Plot type | `plot.type`, `all.nodes` |
| Time scale | `add.time.scale`, `add.abs.time`, `scale.res`, `label.timescale.names`, `grey.bars`, `relative.height`, `cex.age`, `cex.labels`, `cex.names`, `pos.age`, `abs.age.mgp`, `abs.age.lwd`, `abs.age.lwd.ticks`, `tck.abs.age`, `abs.age.line` |
| Node uncertainty | `node.method`, `col.age`, `lwd.bar`, `tip.lengths`, `tip.bar.col`, `distribution.height`, `density.col`, `density.border.col` |
| Appearance | `cex.tips`, `show.tip.label`, `col.tree`, `tip.color`, `ladderize.tree`, `time.correction` |
| Analysis | `burn.in`, `n.runs` |

## Defaults and validation

The GUI stores user overrides only. Empty advanced fields are omitted from the
upstream call. Every emitted argument name is checked against
`formals(MCMC.tree.plot)` by the test suite, so a misspelled argument cannot be
silently swallowed by the function's `...`.
