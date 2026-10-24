# Application-level configuration and static resources.

app_sys <- function(...) {
  system.file(..., package = "mcmctreer")
}

app_www_dir <- function() {
  path <- app_sys("app", "www")
  if (is.null(path) || !nzchar(path) || !dir.exists(path)) {
    path <- file.path("inst", "app", "www")
  }
  path
}

app_theme <- function() {
  bslib::bs_theme(
    version = 5,
    primary = "#0D6EFD",
    secondary = "#6C757D",
    success = "#198754",
    info = "#0DCAF0",
    warning = "#B58100",
    danger = "#DC3545",
    base_font = "system-ui, -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
    code_font = "'SFMono-Regular', Consolas, 'Liberation Mono', monospace"
  )
}

golem_add_external_resources <- function() {
  htmltools::htmlDependency(
    name = "mcmctreer-assets",
    version = app_version(),
    src = app_www_dir(),
    script = "app.js",
    stylesheet = "custom.css",
    all_files = FALSE
  )
}
