# Quick start

## Online use

Open
<https://zengzichao-mcmctreer-bench.share.connect.posit.cloud/>.
The application runs on a shared academic instance on Posit Connect Cloud.
Download your outputs before you close the page.

## Local use

```r
remotes::install_github(
  "PuttickMacroevolution/MCMCtreeR@2330e7a9916c3929513ee217d3854be993965f6b",
  build_vignettes = FALSE
)
remotes::install_github("ZengZichao/MCMCtreeR-Bench")
mcmctreer::run_app()
```

## Module A workflow

1. **Load tree**: upload a file, paste Newick, or load the example tree.
2. **Select nodes**: click internal nodes or choose node numbers. Each selection
   shows its descendant tips.
3. **Calibrations**: choose a distribution and enter minimum and maximum ages.
   `upper` ignores the minimum; `fixed` ignores the maximum.
4. **Advanced parameters**: optional. Empty fields use upstream defaults.
5. **Estimate**: run the per-node estimation. The panel shows parameters and a
   prior curve for each node.
6. **Preview and export**: inspect the `.tre` text and download it, together
   with a distribution figure.

## Module B workflow

1. Choose MCMCtree, MrBayes, RevBayes or User.
2. Provide the data source and press **Load data source**.
3. Adjust the plot type, time scale, uncertainty style and appearance.
4. Use automatic redraw for small data; switch to manual redraw for large
   posteriors.
5. Download PDF, PNG or SVG.

## Download your results

The server does not preserve files between sessions. Download the `.tre` file,
the distribution figure and any time-tree figure before closing the page. The
`.tre` text is also visible in a read-only block and can be copied manually if a
download is blocked.
