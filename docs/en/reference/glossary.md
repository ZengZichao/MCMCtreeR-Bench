# Glossary

## Terms

| Term | Meaning |
| --- | --- |
| calibration node | an internal node whose age is constrained by fossil or other evidence |
| tip | a terminal taxon; tips cannot be calibration nodes in this GUI |
| internal node | a node with at least one descendant edge; ape numbers these after the tips |
| `monoGroups` | the list of descendant tip names that defines each calibrated clade |
| prior | the distribution placed on a node age before the MCMC analysis |
| posterior | samples of node ages from a Bayesian divergence-time analysis |
| HPD | highest posterior density interval |
| FigTree output | the tab-separated tree export from MCMCtree that `readMCMCtree()` parses |
| stale result | an estimation whose input hash no longer matches the current inputs |
| print theme | white background and black lines, used for every PDF export |

## Notation

- `Ma` means millions of years ago.
- `tL` and `tU` are the lower and upper age bounds in MCMCtree labels.
- `pL`, `pR` and `pU` are tail probabilities in MCMCtree labels.
- `node_1`, `node_2` are row names in upstream parameter matrices; the GUI maps
  them back to ape node numbers in its own tables.
