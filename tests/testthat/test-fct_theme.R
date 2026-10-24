test_that("plot colour palettes are complete and valid", {
  for (theme in c("light", "dark", "print")) {
    cols <- plot_colors(theme)
    expect_true(all(c("bg", "fg", "muted", "grid", "highlight", "accent") %in% names(cols)))
    for (name in c("bg", "fg", "muted", "grid", "highlight", "accent", "success", "warning")) {
      expect_silent(grDevices::col2rgb(cols[[name]]))
    }
  }
  expect_identical(effective_plot_theme("print", "dark"), "print")
  expect_identical(effective_plot_theme("match", "dark"), "dark")
  expect_identical(effective_plot_theme("match", "light"), "light")
})

test_that("plot themes restore par settings", {
  path <- tempfile(fileext = ".pdf")
  grDevices::pdf(path)
  on.exit({
    try(grDevices::dev.off(), silent = TRUE)
    unlink(path)
  }, add = TRUE)

  before <- graphics::par("bg")
  with_plot_theme(plot_colors("dark"), {
    expect_identical(graphics::par("bg"), plot_colors("dark")$bg)
  })
  expect_identical(graphics::par("bg"), before)
})

test_that("automatic colours fall back correctly", {
  expect_identical(resolve_plot_colour("", "auto"), "auto")
  expect_identical(resolve_plot_colour(NULL, "auto"), "auto")
  expect_identical(resolve_plot_colour("red", "auto"), "red")
})

test_that("render_to_file produces readable PDF, PNG and SVG files", {
  dir <- tempfile("export-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE, force = TRUE), add = TRUE)

  draw <- function(cols) graphics::plot(1:3, 1:3, col = cols$fg)

  pdf_path <- file.path(dir, "test.pdf")
  render_to_file(pdf_path, 6, 4, dev = "pdf", draw = draw)
  expect_gt(file.info(pdf_path)$size, 0)
  expect_identical(readLines(pdf_path, n = 1), "%PDF-1.4")
  expect_identical(pdf_page_count(pdf_path), 1)

  png_path <- file.path(dir, "test.png")
  render_to_file(png_path, 4, 3, res = 100, dev = "png", draw = draw)
  expect_gt(file.info(png_path)$size, 0)
  expect_identical(
    readBin(png_path, "raw", 8),
    as.raw(c(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a))
  )

  svg_path <- file.path(dir, "test.svg")
  render_to_file(svg_path, 4, 3, dev = "svg", draw = draw)
  expect_gt(file.info(svg_path)$size, 0)
  expect_true(any(grepl("<svg", readLines(svg_path, warn = FALSE))))
})

test_that("distribution PDFs have one page per node", {
  set.seed(3)
  phy <- ape::rcoal(10)
  nodes <- (ape::Ntip(phy) + 1):(ape::Ntip(phy) + 3)
  cal <- lapply(nodes, function(node) {
    one <- new_calibration(node, tip_des_safe(phy, node), "cauchy")
    one$minAge <- 0.5
    one$maxAge <- 1.5
    one
  })
  res <- run_estimation(phy, cal)

  path <- tempfile(fileext = ".pdf")
  on.exit(unlink(path), add = TRUE)
  export_distributions_pdf(path, res, width = 8, height = 6)
  expect_gt(file.info(path)$size, 0)
  expect_identical(pdf_page_count(path), 3)
})

test_that("distribution plots work for every method", {
  set.seed(11)
  phy <- ape::rcoal(12)
  nodes <- (ape::Ntip(phy) + 1):(ape::Ntip(phy) + 6)
  methods <- c("cauchy", "upper", "bound", "gamma", "skewNormal", "skewT", "fixed")
  # Reuse one internal node for the seventh method only in this plotting test.
  use_nodes <- c(nodes, nodes[1])
  cal <- lapply(seq_along(methods), function(i) {
    one <- new_calibration(use_nodes[i], tip_des_safe(phy, use_nodes[i]), methods[i])
    one$minAge <- c(1.5, NA, 0.8, 1.3, 0.5, 1.2, 0.4)[i]
    one$maxAge <- c(3, 1.2, 1.2, 2.0, 1.0, 2.0, NA)[i]
    one
  })
  res <- run_estimation(phy, cal)

  path <- tempfile(fileext = ".pdf")
  grDevices::pdf(path)
  on.exit({
    try(grDevices::dev.off(), silent = TRUE)
    unlink(path)
  }, add = TRUE)
  cols <- plot_colors("print")
  for (one in res$nodes) {
    expect_silent(plot_node_distribution(one, cols = cols))
  }
})

test_that("export colours default to print and can follow the interface", {
  fallback <- list(width = 9, height = 7, dpi = 200, format = "pdf", plot_theme = "print")
  values <- export_values(list(), fallback = fallback)
  expect_identical(values$plot_theme, "print")
  values <- export_values(
    list(export_plot_theme = "match", export_format = "png"),
    fallback = fallback
  )
  expect_identical(values$plot_theme, "match")
  expect_identical(values$format, "png")
})

test_that("theme preferences are session scoped", {
  testServer(mod_theme_server, {
    expect_identical(mode(), "light")
    expect_identical(plot_theme(), "match")
    session$setInputs(theme_mode = "dark")
    session$flushReact()
    expect_identical(mode(), "dark")
    session$setInputs(plot_theme = "print")
    session$flushReact()
    expect_identical(plot_theme(), "print")
  })
})
