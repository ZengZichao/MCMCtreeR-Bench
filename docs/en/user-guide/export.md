# Export

## MCMCtree .tre

The `.tre` file is produced from the calibrated tree, not reconstructed from
the parameter table. It contains every calibration label and the complete tree
topology. The same text is shown in the preview block, so it can be copied even
when browser downloads are restricted.

## PDF

Module A exports one distribution page per calibrated node. Module B exports the
current time-tree plot on one page. PDF uses the print theme with a white
background and black tree lines. The maximum page size is 16 x 12 inches.

## PNG and SVG

PNG is intended for single-figure insertion in manuscripts and slides. It is
limited to 12 x 9 inches at 200 dpi. SVG is vector output suitable for later
editing. PNG and SVG follow the export colour control, which defaults to the
print theme; choose **Match interface** if you want the current light or dark
interface colours.

## Download behaviour

Downloaded files use ASCII names, such as `mcmctree_priors.tre`,
`node_distributions.pdf` or `time_tree.svg`. The server writes to a temporary
file in the session workspace, closes the graphics device, checks that the file
is non-empty, and only then sends it. Files are not stored between sessions.

## Staleness guard

The application hashes the tree, calibration nodes, ages, distributions and
advanced parameters after each estimation run. If any of those business inputs
changes, the result is marked stale and export buttons are disabled until the
estimation is rerun. Language and theme changes do not invalidate results.
