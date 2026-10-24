# Contributing

## Development environment

Install the pinned upstream package and load this package from source:

```r
remotes::install_github(
  "PuttickMacroevolution/MCMCtreeR@2330e7a9916c3929513ee217d3854be993965f6b",
  build_vignettes = FALSE
)
pkgload::load_all()
mcmctreer::run_app()
```

## Branch and pull requests

- Use a focused branch.
- Describe the user-visible change and the tests that cover it.
- Do not copy `MCMCtreeR` source into this repository. Use the pinned `Remotes`
  dependency.
- If an upstream defect requires a GUI workaround, document it and add a
  regression test.

## Tests and checks

```r
pkgload::load_all()
testthat::test_local()
```

Run `R CMD check --no-manual` before a release. Lint findings are informational;
correctness fixes should not be blocked by style warnings.

## Bilingual documentation

Update `docs/en` and `docs/zh` in the same pull request. Headings and code fences
must match. Screenshots must come from a real running application and must not
contain local paths, tokens or private data.

## Security

Do not commit `.Renviron`, `~/.rsconnect`, deployment tokens or uploaded data.
Report vulnerabilities privately as described in `SECURITY.md`.
