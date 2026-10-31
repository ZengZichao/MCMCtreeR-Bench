# Graphics-device wrappers for PDF, PNG and SVG exports.
#
# Every device is closed on exit, including the error path. A zero-byte file
# is treated as a failed export. PNG and SVG fall back to grDevices when the
# optional ragg/svglite packages are not installed (for example on a local
# machine without harfbuzz headers).

open_export_device <- function(path, dev, width, height, res, cols) {
  if (identical(dev, "pdf")) {
    grDevices::pdf(
      path, width = width, height = height,
      family = "sans", bg = cols$bg
    )
    return(invisible(TRUE))
  }

  if (identical(dev, "png")) {
    if (requireNamespace("ragg", quietly = TRUE)) {
      ragg::agg_png(
        path, width = width, height = height, res = res,
        units = "in", background = cols$bg
      )
    } else {
      if (!isTRUE(capabilities("cairo"))) stop(app_error("err_export_failed"))
      grDevices::png(
        path, width = width, height = height, units = "in", res = res,
        type = "cairo", bg = cols$bg
      )
    }
    return(invisible(TRUE))
  }

  if (requireNamespace("svglite", quietly = TRUE)) {
    svglite::svglite(path, width = width, height = height, bg = cols$bg)
  } else {
    if (!isTRUE(capabilities("cairo"))) stop(app_error("err_export_failed"))
    grDevices::svg(path, width = width, height = height, bg = cols$bg, family = "sans")
  }
  invisible(TRUE)
}

render_to_file <- function(path, width, height, res = 200,
                           dev = c("pdf", "png", "svg"),
                           plot_theme = "print", mode = "light",
                           draw) {
  dev <- match.arg(dev)
  if (!is.function(draw)) stop(app_error("err_export_failed"))

  if (identical(dev, "pdf")) {
    check <- check_pdf_size(width, height)
  } else {
    check <- check_png_size(width, height, res)
  }
  if (!isTRUE(check$ok)) {
    stop(do.call(app_error, c(list(check$key), check$args)))
  }

  theme <- if (identical(dev, "pdf")) "print" else effective_plot_theme(plot_theme, mode)
  cols <- plot_colors(theme)

  opened <- FALSE
  on.exit({
    if (isTRUE(opened)) {
      try(grDevices::dev.off(), silent = TRUE)
    }
  }, add = TRUE)

  open_export_device(path, dev, width, height, res, cols)
  opened <- TRUE

  with_plot_theme(cols, draw(cols))

  grDevices::dev.off()
  opened <- FALSE

  info <- file.info(path)
  if (!file.exists(path) || is.na(info$size) || info$size <= 0) {
    unlink(path)
    stop(app_error("err_empty_file"))
  }
  invisible(path)
}

export_distributions_pdf <- function(path, results,
                                     width = 8, height = 6,
                                     plot_theme = "print", mode = "light",
                                     lang = "en") {
  render_to_file(
    path = path, width = width, height = height, dev = "pdf",
    plot_theme = plot_theme, mode = mode,
    draw = function(cols) {
      nodes <- results$nodes %||% list()
      if (!length(nodes)) {
        graphics::plot.new()
        graphics::text(0.5, 0.5, tr(lang, "plot_lbl_no_results"), col = cols$fg)
        return(invisible(NULL))
      }
      for (one in nodes) {
        plot_node_distribution(one, cols = cols, cex = 0.95, lang = lang)
      }
      invisible(NULL)
    }
  )
}

export_distributions_image <- function(path, results, dev = c("png", "svg"),
                                       width = 9, height = 6, res = 200,
                                       plot_theme = "print", mode = "light",
                                       lang = "en") {
  dev <- match.arg(dev)
  render_to_file(
    path = path, width = width, height = height, res = res, dev = dev,
    plot_theme = plot_theme, mode = mode,
    draw = function(cols) {
      plot_distribution_grid(
        results, cols = cols, max_cols = 2, cex = 0.85, lang = lang
      )
    }
  )
}

export_time_tree <- function(path, args, dev = c("pdf", "png", "svg"),
                             width = 9, height = 7, res = 200,
                             plot_theme = "print", mode = "light") {
  dev <- match.arg(dev)
  render_to_file(
    path = path, width = width, height = height, res = res, dev = dev,
    plot_theme = plot_theme, mode = mode,
    draw = function(cols) {
      with_mcmctree_timescale(cols, do.call(MCMCtreeR::MCMC.tree.plot, args))
    }
  )
}

assert_export_path <- function(path, workspace) {
  assert_in_workspace(path, workspace)
  info <- file.info(path)
  if (!file.exists(path) || is.na(info$size) || info$size <= 0) {
    stop(app_error("err_empty_file"))
  }
  path
}

ascii_filename <- function(name, fallback = "download.bin") {
  name <- as.character(name %||% fallback)[1]
  name <- gsub("[^A-Za-z0-9._-]", "_", name)
  if (!nzchar(name) || name %in% c(".", "..")) fallback else name
}
