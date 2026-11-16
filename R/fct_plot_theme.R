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
      bg = "#fcfcfc",
      fg = "#202020",
      muted = "#646464",
      grid = "#e0e0e0",
      highlight = "#0d74ce",
      accent = "#ce2c31",
      success = "#218358",
      warning = "#ab6400",
      density_fill = "#0090ff33",
      density_border = "#0090ff80",
      tip_bar = "#0090ff33",
      bar = "#0090ff"
    ),
    light = list(
      theme = "light",
      bg = "#fcfcfc",
      fg = "#202020",
      muted = "#646464",
      grid = "#e0e0e0",
      highlight = "#0d74ce",
      accent = "#ce2c31",
      success = "#218358",
      warning = "#ab6400",
      density_fill = "#0090ff33",
      density_border = "#0090ff80",
      tip_bar = "#0090ff40",
      bar = "#0090ff"
    ),
    dark = list(
      theme = "dark",
      bg = "#111111",
      fg = "#eeeeee",
      muted = "#b4b4b4",
      grid = "#3a3a3a",
      highlight = "#70b8ff",
      accent = "#ff9592",
      success = "#3dd68c",
      warning = "#ffca16",
      density_fill = "#70b8ff44",
      density_border = "#70b8ff99",
      tip_bar = "#70b8ff55",
      bar = "#70b8ff"
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
    col.sub = cols$fg,
    mar = c(5, 4, 3, 6.5)
  )
  force(expr)
}

# MCMCtreeR hard-codes its geological band palette in the package namespace and
# exposes no argument to override it. Rather than mutate that shared namespace
# (which R CMD check flags and which concurrent sessions could observe), the
# plot function is evaluated against a throwaway child environment that carries
# neutral, theme-aware bands. The child's parent is the MCMCtreeR namespace, so
# every other symbol still resolves exactly as before.
with_mcmctree_timescale <- function(cols, args) {
  cols <- cols %||% plot_colors("print")
  ns <- asNamespace("MCMCtreeR")
  palette_names <- c(
    "Eon.colour", "Era.colour", "Period.colour",
    "Period2.colour", "Epoch.colour", "Age.colour"
  )
  palette_names <- palette_names[vapply(
    palette_names, exists, logical(1), envir = ns, inherits = FALSE
  )]
  band_cols <- if (identical(cols$theme, "dark")) {
    c("#141414", "#121212", "#161616", "#181818")
  } else {
    c("#fcfcfc", "#fafafa", "#f7f7f7", "#f4f4f4")
  }
  shadow <- new.env(parent = ns)
  for (nm in palette_names) {
    original <- get(nm, envir = ns)
    assign(
      nm,
      stats::setNames(
        rep(band_cols, length.out = length(original)),
        names(original)
      ),
      envir = shadow
    )
  }
  plot_fn <- get("MCMC.tree.plot", envir = ns)
  environment(plot_fn) <- shadow
  do.call(plot_fn, args)
}

# Quiet empty state: a line-art phylogeny watermarked at the centre of the
# canvas. The wording lives in the DOM above it, so nothing is drawn as text
# here and the placeholder stays translatable. Strokes are hairlines to match
# the interface rules.
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
