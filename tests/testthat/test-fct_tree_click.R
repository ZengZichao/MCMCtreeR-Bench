test_that("plot coordinates map to ape node numbers", {
  phy <- load_example_phy()
  path <- tempfile(fileext = ".pdf")
  grDevices::pdf(path)
  ape::plot.phylo(phy)
  pp <- get("last_plot.phylo", envir = ape::.PlotPhyloEnv)
  grDevices::dev.off()
  unlink(path)

  points <- phylo_plot_points(pp, ape::Ntip(phy))
  expect_identical(nrow(points), ape::Ntip(phy) + ape::Nnode(phy))
  expect_true(all(points$is_tip[seq_len(ape::Ntip(phy))]))
  expect_false(any(points$is_tip[(ape::Ntip(phy) + 1):nrow(points)]))

  for (i in seq_len(nrow(points))) {
    hit <- nearest_phylo_node(pp, points$x[i], points$y[i], ape::Ntip(phy))
    expect_identical(hit$node, i)
    expect_identical(hit$is_tip, points$is_tip[i])
  }
})

test_that("clicks far from every node are rejected", {
  phy <- load_example_phy()
  path <- tempfile(fileext = ".pdf")
  grDevices::pdf(path)
  ape::plot.phylo(phy)
  pp <- get("last_plot.phylo", envir = ape::.PlotPhyloEnv)
  grDevices::dev.off()
  unlink(path)

  x_range <- diff(range(pp$xx))
  y_range <- diff(range(pp$yy))
  hit <- nearest_phylo_node(
    pp, min(pp$xx) - x_range, min(pp$yy) - y_range,
    ape::Ntip(phy), tol = 0.15
  )
  expect_null(hit$node)
})

test_that("node selection toggles and internal-node checks work", {
  phy <- load_example_phy()
  expect_true(node_is_internal(phy, 8))
  expect_false(node_is_internal(phy, 1))
  expect_false(node_is_internal(phy, 999))

  toggled <- toggle_node_selection(integer(), 8)
  expect_identical(toggled$selected, 8L)
  expect_true(toggled$added)
  toggled <- toggle_node_selection(toggled$selected, 8)
  expect_identical(toggled$selected, integer())
  expect_false(toggled$added)

  choices <- calibration_node_choices(phy)
  expect_length(choices, ape::Nnode(phy))
  expect_identical(unname(choices[1]), as.character(ape::Ntip(phy) + 1))
})
