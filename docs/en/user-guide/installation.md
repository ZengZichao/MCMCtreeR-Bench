# Installation

## Requirements

- R 4.1 or newer.
- A working C/C++ toolchain is not required for the GUI itself, but `ape`,
  `data.table`, `ragg` and `svglite` may need binary or source builds depending
  on your platform.
- Internet access for the first installation. The application itself runs
  locally after installation.

## Install the pinned upstream package

`MCMCtreeR` was archived from CRAN. Install the official GitHub commit that the
MCMCtreeR Bench is tested against:

```r
remotes::install_github(
  "PuttickMacroevolution/MCMCtreeR@2330e7a9916c3929513ee217d3854be993965f6b",
  build_vignettes = FALSE,
  upgrade = "never"
)
```

Check the metadata:

```r
stopifnot(packageDescription("MCMCtreeR")$RemoteType == "github")
stopifnot(startsWith(packageDescription("MCMCtreeR")$RemoteSha, "2330e7a"))
```

## Install the GUI

```r
remotes::install_github("ZengZichao/MCMCtreeR-Bench")
mcmctreer::run_app()
```

From a source checkout, run:

```r
pkgload::load_all()
mcmctreer::run_app()
```

## Reproducible restore

When `renv.lock` is present, restore the recorded library before starting:

```r
renv::restore()
```

The lock file records the same upstream `MCMCtreeR` commit as `DESCRIPTION`'s
`Remotes` field. Regenerate it only in an environment that can reach GitHub.

## Why install.packages() fails

`install.packages("MCMCtreeR")` asks CRAN for a package that has been archived.
It returns a 404-style failure. Use the pinned GitHub commit or a verified
mirror instead. The GUI never installs packages at runtime.

## Common installation problems

- **`there is no package called 'MCMCtreeR'`**: install the upstream commit
  first; the GUI does not vendor upstream source.
- **`Unsupported R version` on Posit Connect Cloud**: use the R version
  supported by the platform, then regenerate `renv.lock`.
- **`ragg` or `svglite` fails to build**: they are declared dependencies, but
  the application still starts. PNG falls back to
  `grDevices::png(type = "cairo")` and SVG to `grDevices::svg()` when Cairo is
  available. Install binary packages if your platform cannot compile them.
- **GitHub is unreachable**: install from a local checkout and record the commit
  manually; do not substitute a CRAN URL in `renv.lock`.
