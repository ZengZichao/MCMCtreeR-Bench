# Module B: time tree

Module B visualises time-calibrated trees. It is a single page with collapsible
settings because users need fast, repeated visual feedback while adjusting
appearance.

## Analysis types

| Type | What to provide | Notes |
| --- | --- | --- |
| MCMCtree | FigTree output, or a tree plus a posterior table | `build tree` replaces branch lengths with posterior mean ages |
| MrBayes | `.con.tre` plus `.run1.t` and optional later runs | File names are preserved |
| RevBayes | one `.nex`/`.nexus` plus at least one `.trees` | Files stay in one session workspace |
| User | a time tree plus a node-age table | The table must cover every internal node |

## Data requirements

Posterior tables are tab-separated and contain columns such as `t_n1`, `t_n2`.
Other columns are ignored after validation. Node-age tables have a first column
named `node`; the remaining columns are numeric samples, or a two-column
long-format table with `node` and `age`.

MrBayes uploads must contain exactly one file ending in the literal `.con.tre`
and a matching `.run1.t`. RevBayes uploads must contain exactly one
`.nex`/`.nexus` and at least one `.trees` file.

## Plot types

- `phylogram` draws a time tree whose branch lengths are ages.
- `cladogram` is available for MCMCtree analyses only.
- `distributions` draws posterior densities on internal nodes and requires
  posterior samples for MCMCtree or User data.

## Plot settings

Settings are grouped into data source, plot type, geological time scale, node
uncertainty, tree appearance, analysis settings and export. Only parameters
relevant to the selected analysis type are shown. Colours left empty follow the
current plot theme; PDF always uses the print theme.

The geological time scale supports Eon, Period, Epoch and Age. Selecting more
than one level stacks them from bottom to top. Absolute ages can be added to the
last level.

## Automatic and manual redraw

Small data sets redraw automatically after a short debounce. For posteriors
above 100,000 rows the application switches to manual redraw by default to keep
the single shared worker responsive.

## Export

PDF is always white-background. PNG uses `ragg` when available and falls back to
Cairo; SVG uses `svglite` when available and falls back to Cairo SVG. Every
device is closed on error and zero-byte files are rejected.
