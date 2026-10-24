# Local deployment

## Install dependencies

```r
remotes::install_github(
  "PuttickMacroevolution/MCMCtreeR@2330e7a9916c3929513ee217d3854be993965f6b",
  build_vignettes = FALSE
)
remotes::install_github("ZengZichao/MCMCtreeR-Bench")
```

## Start the app

From an installed package:

```r
mcmctreer::run_app()
```

From a source checkout:

```r
pkgload::load_all()
mcmctreer::run_app()
```

## Run the tests

```r
pkgload::load_all()
testthat::test_local()
```

The suite covers calibration construction, estimation, plot arguments, session
workspaces, limits, exports, bilingual key parity, documentation parity and an
application smoke flow.

## Production-mode check

```r
shiny::runApp(".", port = 7788, launch.browser = FALSE)
```

This sources the root `app.R`, loads the package through `pkgload`, enables the
production options and launches the same server used on Posit Connect Cloud. Check the
first screen, the example workflow, uploads and downloads before deploying.
