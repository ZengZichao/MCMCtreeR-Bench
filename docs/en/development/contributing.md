# Contributing

## Development environment

Install the pinned upstream package, then load this package from source:

```r
remotes::install_github(
  "PuttickMacroevolution/MCMCtreeR@2330e7a9916c3929513ee217d3854be993965f6b",
  build_vignettes = FALSE
)
pkgload::load_all()
mcmctreer::run_app()
```

## Branch and pull requests

Use a focused branch and describe the user-visible change in the pull request.
Keep the upstream package boundary intact: do not copy upstream source into this
repository. If an upstream defect affects the GUI, document the workaround and
add a regression test.

## Tests and checks

```r
pkgload::load_all()
testthat::test_local()
```

Run `R CMD check --no-manual` before proposing a release. Lint warnings are
informational and should not block correctness fixes.

## Bilingual documentation

Every user-facing change needs an English and a Chinese update in the same pull
request. Headings and code fences must match across `docs/en` and `docs/zh`.
Screenshots must come from a real running application, use example data, and
avoid local paths or tokens.

## Security

Do not commit `.Renviron`, `~/.rsconnect`, deployment tokens or uploaded data.
Report vulnerabilities privately according to `SECURITY.md`. Do not open a
public issue containing a working exploit.
