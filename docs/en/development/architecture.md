# Architecture

## Module layout

The application is a golem package with two `nav_panel` modules:

- `mod_a_wizard.R` assembles the six priors steps and the persistent preview.
- `mod_b_viz.R` assembles the settings sidebar, live plot and export.
- Shared modules provide session-scoped language, theme and export controls.
- Pure helpers handle tree groups, argument assembly, estimation, validation,
  workspaces, limits, errors, exports and metadata.

`app.R` is the production entry point. It loads the package with `pkgload`,
sets request-size and error-sanitising options, and calls `run_app()`.

## State model

`app_server.R` owns one `reactiveValues` object with independent `a` and `b`
subtrees. Every write goes through `set_a()` or `set_b()` and replaces the whole
subtree:

```r
a <- state$a
a$calibrated <- update_calibration(a$calibrated, node = 8, minAge = 1.5)
set_a(a)
```

Direct nested assignment such as `state$a$calibrated[[1]]$minAge <- 1.5` would
not invalidate reactive consumers and is therefore avoided.

## Internationalisation and theme

Language and theme are presentation preferences. They live in `moduleServer()`
scopes, not in `state`, and never participate in the result hash. The dictionary
is pure data; `tr(lang, key, ...)` is a pure function with an English fallback
and a visible `⟨key⟩` marker for missing entries. UI text is rendered from the
current session language, and dynamic controls are backfilled from state so a
language switch does not reset user input.

## Session workspace

All user files live under `tempdir()/session$token/<subdir>`. Uploaded names are
sanitised, original names are preserved where upstream derives sibling paths,
and paths used for downloads are checked with `assert_in_workspace()`. The whole
token directory is removed in `onSessionEnded()`.

## Error handling

Expected problems use `app_error("key", ...)`. Modules translate the key and
arguments. Unexpected errors keep their technical text after `tempdir()` paths
are replaced with `<tmp>`. Upstream warnings about `node.label` length are
classified as known, logged, and never shown as a failed run.

## Upstream workarounds

The GUI does not modify `MCMCtreeR`. It calls one `estimateXxx()` per node
instead of `MCMCtreePhy()`, rebuilds a full-length node-label vector to avoid
label recycling, supplies a placeholder chain where the upstream distribution
guard incorrectly requires one, and controls graphics devices for every export.
