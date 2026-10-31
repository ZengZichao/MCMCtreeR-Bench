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
      highlight = "#0066CC",
      accent = "#B00020",
      success = "#1B7A32",
      warning = "#7A5C00",
      density_fill = "#00000050",
      density_border = "#00000080",
      tip_bar = "#0066CC33",
      bar = "#0066CC"
    ),
    light = list(
      theme = "light",
      bg = "#FFFFFF",
      fg = "#1D1D1F",
      muted = "#6E6E73",
      grid = "#E8E8ED",
      highlight = "#0066CC",
      accent = "#D70015",
      success = "#248A3D",
      warning = "#8A6D00",
      density_fill = "#0066CC33",
      density_border = "#0066CC80",
      tip_bar = "#0066CC40",
      bar = "#0066CC"
    ),
    dark = list(
      theme = "dark",
      bg = "#171719",
      fg = "#F5F5F7",
      muted = "#A1A1A6",
      grid = "#3A3A3C",
      highlight = "#2997FF",
      accent = "#FF6961",
      success = "#30D158",
      warning = "#FFD60A",
      density_fill = "#2997FF44",
      density_border = "#2997FF99",
      tip_bar = "#2997FF55",
      bar = "#2997FF"
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

# MCMCtreeR hard-codes its geological band palette in the package namespace.
# Swap those bindings for neutral, theme-aware bands while the plot is drawn.
with_mcmctree_timescale <- function(cols, expr) {
  cols <- cols %||% plot_colors("print")
  ns <- asNamespace("MCMCtreeR")
  palette_names <- c(
    "Eon.colour", "Era.colour", "Period.colour",
    "Period2.colour", "Epoch.colour", "Age.colour"
  )
  palette_names <- palette_names[vapply(
    palette_names, exists, logical(1), envir = ns, inherits = FALSE
  )]
  old <- lapply(palette_names, get, envir = ns)
  names(old) <- palette_names
  band_cols <- if (identical(cols$theme, "dark")) {
    c("#3a3a3c", "#2a2a2c", "#48484a", "#323234")
  } else {
    c("#e8e8ed", "#f2f2f4", "#dcdce1", "#fafafc")
  }
  for (nm in palette_names) {
    original <- old[[nm]]
    replacement <- stats::setNames(
      rep(band_cols, length.out = length(original)),
      names(original)
    )
    if (bindingIsLocked(nm, ns)) unlockBinding(nm, ns)
    assign(nm, replacement, envir = ns)
    lockBinding(nm, ns)
  }
  on.exit({
    for (nm in palette_names) {
      if (bindingIsLocked(nm, ns)) unlockBinding(nm, ns)
      assign(nm, old[[nm]], envir = ns)
      lockBinding(nm, ns)
    }
  }, add = TRUE)
  force(expr)
}

# Quiet empty state: a line-art phylogeny watermarked at the centre of the
# canvas. The wording lives in the DOM above it, so nothing is drawn as text
# here and the placeholder stays translatable.
plot_empty_state <- function(cols) {
  cols <- cols %||% plot_colors("print")
  graphics::plot.new()
  line <- grDevices::adjustcolor(cols$highlight, alpha.f = 0.35)
  node <- grDevices::adjustcolor(cols$highlight, alpha.f = 0.55)
  # Four tips on a rooted tree, sized to about half the plot region so it reads
  # as a watermark rather than a half-drawn figure.
  graphics::segments(0.465, 0.266, 0.465, 0.410, col = line, lwd = 2)
  graphics::segments(0.465, 0.410, 0.267, 0.554, col = line, lwd = 2)
  graphics::segments(0.465, 0.410, 0.663, 0.554, col = line, lwd = 2)
  graphics::segments(0.267, 0.554, 0.267, 0.698, col = line, lwd = 2)
  graphics::segments(0.663, 0.554, 0.663, 0.644, col = line, lwd = 2)
  graphics::segments(0.663, 0.644, 0.537, 0.734, col = line, lwd = 2)
  graphics::segments(0.663, 0.644, 0.789, 0.734, col = line, lwd = 2)
  graphics::points(
    c(0.465, 0.267, 0.663, 0.537, 0.789),
    c(0.266, 0.698, 0.554, 0.734, 0.734),
    pch = 21, cex = 1.3, lwd = 1.4, col = node, bg = cols$bg
  )
}

# A small helper for empty strings meaning "use the automatic theme colour".
resolve_plot_colour <- function(value, auto, fallback = NULL) {
  value <- as.character(value %||% "")[1]
  if (is.na(value) || !nzchar(trimws(value))) {
    return(auto %||% fallback)
  }
  trimws(value)
}
