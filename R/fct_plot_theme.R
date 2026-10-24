# Base-graphics colour themes.
#
# The interface theme and the plot theme are separate: a dark UI can still
# export a white PDF. with_plot_theme() always restores par() on exit, even
# when the drawing expression fails.

plot_colors <- function(theme = c("light", "dark", "print")) {
  theme <- match.arg(theme)
  switch(
    theme,
    print = list(
      theme = "print",
      bg = "#FFFFFF",
      fg = "#000000",
      muted = "#4A4A4A",
      grid = "#D9D9D9",
      highlight = "#0B5ED7",
      accent = "#B02A37",
      success = "#198754",
      warning = "#8A6700",
      density_fill = "#00000050",
      density_border = "#00000080",
      tip_bar = "#FF000050",
      bar = "#1F77B4"
    ),
    light = list(
      theme = "light",
      bg = "#FFFFFF",
      fg = "#101214",
      muted = "#5C636A",
      grid = "#DEE2E6",
      highlight = "#0D6EFD",
      accent = "#DC3545",
      success = "#198754",
      warning = "#8A6700",
      density_fill = "#0D6EFD33",
      density_border = "#0D6EFD80",
      tip_bar = "#DC354560",
      bar = "#0D6EFD"
    ),
    dark = list(
      theme = "dark",
      bg = "#0F1115",
      fg = "#F1F3F5",
      muted = "#ADB5BD",
      grid = "#3A3F47",
      highlight = "#7CC4FF",
      accent = "#FF8A9B",
      success = "#75D1A0",
      warning = "#FFD166",
      density_fill = "#FFFFFF55",
      density_border = "#FFFFFF99",
      tip_bar = "#7CC4FF55",
      bar = "#7CC4FF"
    )
  )
}

effective_plot_theme <- function(plot_theme = "match", mode = "light") {
  plot_theme <- as.character(plot_theme %||% "match")[1]
  if (identical(plot_theme, "print")) return("print")
  if (identical(mode, "dark")) "dark" else "light"
}

plot_colors_for <- function(ui_prefs = NULL) {
  plot_theme <- "match"
  mode <- "light"
  if (!is.null(ui_prefs)) {
    if (!is.null(ui_prefs$theme)) {
      plot_theme <- tryCatch(ui_prefs$theme$plot_theme(), error = function(e) "match")
      mode <- tryCatch(ui_prefs$theme$mode(), error = function(e) "light")
    }
  }
  plot_colors(effective_plot_theme(plot_theme, mode))
}

with_plot_theme <- function(cols, expr) {
  cols <- cols %||% plot_colors("print")
  old <- graphics::par(no.readonly = TRUE)
  on.exit(suppressWarnings(graphics::par(old)), add = TRUE)
  graphics::par(
    bg = cols$bg,
    fg = cols$fg,
    col = cols$fg,
    col.axis = cols$fg,
    col.lab = cols$fg,
    col.main = cols$fg,
    col.sub = cols$fg
  )
  force(expr)
}

# A small helper for empty strings meaning "use the automatic theme colour".
resolve_plot_colour <- function(value, auto, fallback = NULL) {
  value <- as.character(value %||% "")[1]
  if (is.na(value) || !nzchar(trimws(value))) {
    return(auto %||% fallback)
  }
  trimws(value)
}
