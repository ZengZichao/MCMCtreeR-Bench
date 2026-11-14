# Application-level configuration and static resources.

app_sys <- function(...) {
  system.file(..., package = "mcmctreer")
}

# Bundled example inputs. The upstream MCMCtreeR::apeData tree is topology-only,
# so it cannot exercise anything that needs branch lengths; these two files are
# a derived, ultrametric version plus a matching posterior chain.
example_tree_file <- function() {
  path <- app_sys("extdata", "example_tree.tre")
  if (!nzchar(path) || !file.exists(path)) {
    path <- file.path("inst", "extdata", "example_tree.tre")
  }
  path
}

example_chain_file <- function() {
  path <- app_sys("extdata", "example_chain.tsv")
  if (!nzchar(path) || !file.exists(path)) {
    path <- file.path("inst", "extdata", "example_chain.tsv")
  }
  path
}

app_www_dir <- function() {
  path <- app_sys("app", "www")
  if (is.null(path) || !nzchar(path) || !dir.exists(path)) {
    path <- file.path("inst", "app", "www")
  }
  path
}

app_custom_css <- function() {
  path <- file.path(app_www_dir(), "custom.css")
  if (!file.exists(path)) return("")
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

app_theme <- function() {
  # Radix UI Colors, light steps. The interface CSS owns the full token set and
  # the dark scale; these values seed Bootstrap so components outside the sheet
  # (native controls, validation states) stay on the same palette.
  theme <- bslib::bs_theme(
    version = 5,
    primary = "#0090ff",
    secondary = "#646464",
    success = "#218358",
    info = "#0d74ce",
    warning = "#ab6400",
    danger = "#ce2c31",
    bg = "#fcfcfc",
    fg = "#202020",
    base_font = paste(
      "-apple-system", "BlinkMacSystemFont", "\"Segoe UI\"", "\"Helvetica Neue\"",
      "\"PingFang SC\"", "\"Noto Sans CJK SC\"", "Inter", "sans-serif",
      sep = ", "
    ),
    heading_font = paste(
      "\"Bodoni 72\"", "\"Playfair Display\"", "\"Iowan Old Style\"",
      "\"Songti SC\"", "\"Noto Serif CJK SC\"", "Georgia", "serif",
      sep = ", "
    ),
    code_font = paste(
      "\"SF Mono\"", "SFMono-Regular", "ui-monospace", "Menlo", "monospace",
      sep = ", "
    )
  )
  # Bundling the rules into the theme keeps them after Bootstrap in the cascade,
  # so component overrides do not depend on stylesheet load order.
  bslib::bs_add_rules(theme, app_custom_css())
}

app_assets_version <- function() {
  files <- file.path(app_www_dir(), c("custom.css", "app.js"))
  mtimes <- suppressWarnings(file.info(files)$mtime)
  stamp <- if (all(is.na(mtimes))) 0 else as.integer(max(mtimes, na.rm = TRUE))
  paste0(app_version(), ".", stamp)
}

golem_add_external_resources <- function() {
  htmltools::htmlDependency(
    name = "mcmctreer-assets",
    version = app_assets_version(),
    src = app_www_dir(),
    script = "app.js",
    all_files = FALSE
  )
}
