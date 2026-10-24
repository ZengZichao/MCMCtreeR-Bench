# Troubleshooting

## Tree loading

- **The tree is rejected as not binary**: calibration can still be attempted,
  but MCMCtree expects a fully resolved tree. Resolve polytomies before export.
- **No branch lengths**: Module A plotting still works; Module B time-tree
  plotting requires branch lengths.
- **Duplicated tip labels**: make tip names unique. A calibration that names a
  duplicated tip is ambiguous.
- **Multiple trees in one Nexus file**: only the first tree is used. Split the
  file if you need another tree.

## Calibration and estimation

- **Export is disabled**: the inputs changed after the last run, or no run has
  happened. Rerun the estimation.
- **A node cannot be estimated**: check that the minimum is smaller than the
  maximum and that the node is internal. The error message includes the node
  number.
- **`gamma` alpha does not follow the setting**: the GUI calls `estimateGamma()`
  directly. The upstream `MCMCtreePhy()` wrapper does not honour
  `estimateAlpha = FALSE`; the GUI does not use that path.
- **Known node.label warning**: the upstream functions emit a warning about the
  node.label length. It is classified as a known upstream warning and does not
  invalidate the result.

## Module B data sources

- **MrBayes files are rejected**: require exactly one literal `.con.tre` and a
  matching `.run1.t`. The upload file names are preserved because the upstream
  function derives sibling paths from them.
- **RevBayes files are rejected**: provide one `.nex`/`.nexus` and at least one
  `.trees` file in the same upload.
- **The posterior table has no `t_n` columns**: the chain must contain columns
  named `t_n1`, `t_n2`, and so on.
- **The User node-age table is incomplete**: cover every internal node. The
  upstream User branch indexes all nodes, so a partial table fails.
- **`distributions` needs posterior samples**: use a posterior table for
  MCMCtree, or a node-age table for User data.

## Downloads

- **The file is empty**: graphics devices are closed on both success and error
  paths. If the error persists, check the plot status message and retry with a
  smaller canvas.
- **A download is blocked by the browser**: copy the `.tre` text from the
  preview block.
- **A PDF opens but looks blank**: choose the print theme and check that the
  data source loaded successfully.

## Known upstream behaviour

- `nodeToPhy()` writes a short `node.labels` vector; `ape::write.tree()` then
  recycles a single label across all nodes. The GUI rebuilds a full-length label
  vector so only calibrated nodes are labelled.
- `MCMC.tree.plot()` documents `plot`/`pdfOutput` arguments that do not exist.
  The GUI controls the graphics device itself.
- `MCMC.tree.plot()` treats `directory.files` as a file path, not a directory.

## Getting help

Open a GitHub issue with the exact input type, the node numbers, the error text
and whether the problem reproduces with the bundled example. Do not include
sensitive data. Security issues should follow `SECURITY.md`.
