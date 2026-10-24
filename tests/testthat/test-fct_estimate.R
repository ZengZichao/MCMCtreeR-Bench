test_that("all seven distributions estimate and accumulate labels", {
  set.seed(42)
  phy <- ape::rcoal(12)
  nodes <- (ape::Ntip(phy) + 1):(ape::Ntip(phy) + ape::Nnode(phy))
  methods <- c("cauchy", "upper", "bound", "gamma", "skewNormal", "skewT", "fixed")
  cal <- lapply(seq_along(methods), function(i) {
    new_calibration(nodes[i], tip_des_safe(phy, nodes[i]), methods[i])
  })
  mins <- c(1.5, NA, 0.8, 1.3, 0.5, 1.2, 0.4)
  maxs <- c(3, 1.2, 1.2, 2.0, 1.0, 2.0, NA)
  for (i in seq_along(cal)) {
    cal[[i]]$minAge <- mins[i]
    cal[[i]]$maxAge <- maxs[i]
  }

  res <- run_estimation(phy, cal)
  expect_length(res$nodes, 7)
  expect_identical(
    vapply(res$nodes, function(x) x$method, character(1)),
    methods
  )
  for (node in res$nodes) {
    expect_true(is.matrix(node$parameters) || is.numeric(node$parameters))
    expect_gt(length(node$parameters), 0)
    expect_true(nzchar(node$nodeLabels))
  }
  expect_identical(sum(nzchar(res$final_phy$node.label)), 7L)
  expect_identical(which(nzchar(res$final_phy$node.label)), seq_len(7))

  text <- tre_text(res$final_tre)
  expect_true(grepl("L\\(", text))
  expect_true(grepl("U\\(", text))
  expect_true(grepl("B\\(", text))
  expect_true(grepl("G\\(", text))
  expect_true(grepl("SN\\(", text))
  expect_true(grepl("ST\\(", text))
  expect_true(grepl("=0.4", text))
  expect_identical(nrow(parameter_summary(res)), 7L)
})

test_that("gamma estimation honours estimateAlpha = FALSE", {
  phy <- load_example_phy()
  one <- new_calibration(8, tip_des_safe(phy, 8), "gamma")
  one$minAge <- 1.5
  one$maxAge <- 3
  one$adv <- list(alpha = 188, beta = 100, estimateAlpha = FALSE, estimateBeta = FALSE)
  result <- suppressWarnings(estimate_one_node(one, phy))
  expect_identical(unname(result$parameters[1, "alpha"]), 188)
  expect_identical(unname(result$parameters[1, "beta"]), 100)
})

test_that("GUI estimates match MCMCtreePhy for non-gamma methods", {
  set.seed(7)
  phy <- ape::rcoal(10)
  nodes <- (ape::Ntip(phy) + 1):(ape::Ntip(phy) + 5)
  methods <- c("cauchy", "upper", "bound", "skewNormal", "skewT")
  cal <- lapply(seq_along(methods), function(i) {
    new_calibration(nodes[i], tip_des_safe(phy, nodes[i]), methods[i])
  })
  mins <- c(1.5, NA, 0.8, 0.5, 1.2)
  maxs <- c(3, 1.2, 1.4, 1.0, 2.0)
  for (i in seq_along(cal)) {
    cal[[i]]$minAge <- mins[i]
    cal[[i]]$maxAge <- maxs[i]
  }

  gui <- run_estimation(phy, cal)
  ref <- suppressWarnings(reference_estimates(phy, cal))
  for (i in seq_along(cal)) {
    expect_equal(
      as.numeric(gui$nodes[[i]]$parameters),
      as.numeric(ref[[i]]),
      tolerance = 1e-6
    )
  }
})

test_that("fixed is accepted as a reference method", {
  phy <- load_example_phy()
  cal <- list(new_calibration(8, tip_des_safe(phy, 8), "fixed"))
  cal[[1]]$minAge <- 1.2
  expect_length(calibration_issues(cal), 0)
  ref <- suppressWarnings(reference_estimates(phy, cal))
  expect_length(ref, 1)
})

test_that("gamma is rejected by the MCMCtreePhy reference helper", {
  phy <- load_example_phy()
  cal <- list(new_calibration(8, tip_des_safe(phy, 8), "gamma"))
  cal[[1]]$minAge <- 1.5
  cal[[1]]$maxAge <- 3
  expect_error(reference_estimates(phy, cal), "gamma")
})

test_that("upstream node.label warnings are classified as known", {
  phy <- load_example_phy()
  warn <- "Length of node.label does not match number of nodes."
  classified <- classify_warnings(c(warn, "some unexpected warning"))
  expect_identical(classified$known, warn)
  expect_identical(classified$unknown, "some unexpected warning")
})

test_that("apply_node_labels only labels calibrated nodes", {
  phy <- load_example_phy()
  labels <- list(`8` = "'L[1~0.1~1~0]'")
  out <- apply_node_labels(phy, labels)
  expect_length(out$node.label, ape::Nnode(phy))
  expect_identical(sum(nzchar(out$node.label)), 1L)
  expect_identical(out$node.label[1], labels[["8"]])
  expect_null(out$node.labels)
})
