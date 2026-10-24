# Testing

## Unit tests

The unit suite covers:

- `tipDes()` list/vector normalisation and invalid nodes;
- plot-coordinate to node-number mapping;
- per-node argument construction and the distribution matrix;
- stable and sensitive input hashing;
- parameter validation and range checks;
- session workspace isolation, file-name safety and path assertions;
- upload, tree, posterior, object and image limits;
- error sanitisation and known-warning classification;
- PDF, PNG and SVG export, page counts and device cleanup;
- bilingual key parity and session-scoped language state.

## Integration tests

The integration tests compare GUI estimates with the upstream `MCMCtreePhy()`
reference for non-gamma methods and call `estimateGamma()` directly for gamma.
They also exercise the three supported Module B data paths with bundled data.

```r
pkgload::load_all()
testthat::test_local()
```

## Application smoke tests

`shiny::testServer()` drives the example workflow: load tree, add node, enter
ages, run estimation, open the export step, and verify that a later input change
marks the result stale. A second smoke test loads a FigTree source into Module B.

## Documentation gates

`test-docs_parity.R` checks that `docs/en` and `docs/zh` contain the same paths,
the same heading counts, identical code fences, resolvable internal links, and
no placeholder text. `mkdocs build --strict` is the second gate.

## Browser matrix

Before a release, test Chrome, Safari and Firefox, light and dark modes, Chinese
and English, and two concurrent incognito sessions. Confirm that uploads do not
cross sessions and that downloads use ASCII names.
