# Distribution and tree previews for module A.
#
# Curves are obtained from MCMCtreeR::plotMCMCtree(plotMCMCtreeData = FALSE)
# so the GUI can draw them with its own light/dark colours. upper and fixed
# are not supported by plotMCMCtree(); they receive small schematic plots.

node_upper_time <- function(one) {
  values <- c(one$minAge, one$maxAge)
  values <- values[is.finite(values)]
  if (!length(values) || max(values) <= 0) return(1)
  as.numeric(max(values)) * 1.25 + 1e-6
}

distribution_curve <- function(one, upper_time = node_upper_time(one)) {
  method <- one$method
  if (!method %in% c("cauchy", "skewT", "skewNormal", "gamma", "bound")) {
    return(NULL)
  }
  MCMCtreeR::plotMCMCtree(
    parameters = one$parameters,
    method = method,
    title = paste("Node", one$node, method),
    upperTime = upper_time,
    plotMCMCtreeData = FALSE
  )
}

plot_node_distribution <- function(one, cols = plot_colors("print"),
                                   upper_time = node_upper_time(one),
                                   cex = 1) {
  cols <- cols %||% plot_colors("print")
  method <- one$method
  title <- paste("Node", one$node, method)

  if (identical(method, "fixed")) {
    age <- as.numeric(one$minAge)
    x_max <- max(age * 1.4, 1)
    graphics::plot(
      NA, xlim = c(0, x_max), ylim = c(0, 1), xaxs = "i", yaxs = "i",
      bty = "l", las = 1, xlab = "Ma", ylab = "density", main = title,
      cex.axis = 0.8 * cex, cex.lab = 0.85 * cex, cex.main = 0.95 * cex,
      col.axis = cols$fg, col.lab = cols$fg, col.main = cols$fg
    )
    graphics::abline(v = age, col = cols$highlight, lwd = 2)
    graphics::text(age, 0.85, "fixed age", pos = 4, cex = 0.75 * cex, col = cols$muted)
    return(invisible(NULL))
  }

  if (identical(method, "upper")) {
    max_age <- as.numeric(one$maxAge)
    x_max <- max(max_age * 1.4, 1)
    x <- seq(0, x_max, length.out = 400)
    y <- ifelse(
      x <= max_age,
      1 / max_age,
      (1 / max_age) * exp(-(x - max_age) / max(max_age * 0.15, 1e-6))
    )
    y <- y / max(y)
    graphics::plot(
      x, y, type = "n", xlim = c(0, x_max), ylim = c(0, 1.05),
      xaxs = "i", yaxs = "i", bty = "l", las = 1,
      xlab = "Ma", ylab = "density", main = title,
      cex.axis = 0.8 * cex, cex.lab = 0.85 * cex, cex.main = 0.95 * cex,
      col.axis = cols$fg, col.lab = cols$fg, col.main = cols$fg
    )
    graphics::polygon(c(x, rev(x)), c(y, rep(0, length(y))),
                      col = cols$density_fill, border = NA)
    graphics::lines(x, y, col = cols$fg, lwd = 1.4)
    graphics::abline(v = max_age, col = cols$muted, lty = 3)
    graphics::text(max_age, 0.95, "maximum", pos = 4, cex = 0.75 * cex, col = cols$muted)
    return(invisible(NULL))
  }

  curve_data <- distribution_curve(one, upper_time = upper_time)
  if (is.null(curve_data)) return(invisible(NULL))

  x <- as.numeric(curve_data[, 1])
  y <- as.numeric(curve_data[, 2])
  y[!is.finite(y)] <- 0
  x[!is.finite(x)] <- 0
  if (max(y, na.rm = TRUE) <= 0) y <- rep(0, length(y))

  graphics::plot(
    x, y, type = "n", xlim = range(x, finite = TRUE), ylim = c(0, max(y) * 1.05),
    xaxs = "i", yaxs = "i", bty = "l", las = 1,
    xlab = "Ma", ylab = "density", main = title,
    cex.axis = 0.8 * cex, cex.lab = 0.85 * cex, cex.main = 0.95 * cex,
    col.axis = cols$fg, col.lab = cols$fg, col.main = cols$fg
  )
  graphics::polygon(c(x, rev(x)), c(y, rep(0, length(y))),
                    col = cols$density_fill, border = NA)
  graphics::lines(x, y, col = cols$fg, lwd = 1.4)

  if (is.finite(one$minAge)) {
    graphics::abline(v = one$minAge, col = cols$muted, lty = 3)
  }
  if (is.finite(one$maxAge)) {
    graphics::abline(v = one$maxAge, col = cols$muted, lty = 3)
  }
  invisible(NULL)
}

plot_distribution_grid <- function(results, cols = plot_colors("print"),
                                   max_cols = 2, cex = 0.9) {
  nodes <- results$nodes %||% list()
  if (!length(nodes)) {
    graphics::plot.new()
    graphics::text(0.5, 0.5, "No estimation results", col = cols$fg)
    return(invisible(NULL))
  }
  n <- length(nodes)
  ncol <- min(max_cols, n)
  nrow <- ceiling(n / ncol)
  old <- graphics::par(no.readonly = TRUE)
  on.exit(suppressWarnings(graphics::par(old)), add = TRUE)
  graphics::par(mfrow = c(nrow, ncol), mar = c(3.6, 3.6, 1.8, 0.8))
  for (one in nodes) plot_node_distribution(one, cols = cols, cex = cex)
  invisible(NULL)
}

plot_calibrated_tree <- function(phy, calibrated = list(), cols = plot_colors("print"),
                                 show_tip_label = TRUE, show_node_ids = TRUE) {
  cols <- cols %||% plot_colors("print")
  n_tip <- ape::Ntip(phy)
  cex_tip <- if (n_tip > 200) 0.25 else if (n_tip > 100) 0.4 else if (n_tip > 50) 0.55 else 0.8
  pp <- ape::plot.phylo(
    phy,
    type = "phylogram",
    edge.color = cols$fg,
    tip.color = cols$fg,
    show.tip.label = isTRUE(show_tip_label),
    cex = cex_tip,
    label.offset = 0.01,
    no.margin = FALSE
  )
  last_plot <- get("last_plot.phylo", envir = ape::.PlotPhyloEnv)
  if (isTRUE(show_node_ids)) {
    internal <- (n_tip + 1):(n_tip + ape::Nnode(phy))
    ape::nodelabels(
      node = internal,
      text = internal,
      cex = 0.55,
      frame = "none",
      col = cols$muted,
      adj = c(-0.15, 1.15)
    )
  }
  selected <- vapply(calibrated, function(x) as.integer(x$node), integer(1))
  if (length(selected)) {
    ape::nodelabels(
      node = selected,
      pch = 21,
      bg = cols$highlight,
      col = cols$bg,
      cex = 1.1
    )
  }
  invisible(last_plot)
}
