test_that("build_node_args only passes legal arguments", {
  phy <- load_example_phy()
  spec_fun <- list(
    cauchy = MCMCtreeR::estimateCauchy,
    skewT = MCMCtreeR::estimateSkewT,
    skewNormal = MCMCtreeR::estimateSkewNormal,
    gamma = MCMCtreeR::estimateGamma,
    bound = MCMCtreeR::estimateBound,
    upper = MCMCtreeR::estimateUpper,
    fixed = MCMCtreeR::estimateFixed
  )
  for (method in names(spec_fun)) {
    one <- new_calibration(8, tip_des_safe(phy, 8), method)
    one$minAge <- 1.5
    one$maxAge <- 3
    args <- build_node_args(one, phy)
    expect_true(all(names(args) %in% c(names(formals(spec_fun[[method]])), "phy", "monoGroups")))
    if (identical(method, "upper")) expect_false("minAge" %in% names(args))
    if (identical(method, "fixed")) expect_false("maxAge" %in% names(args))
  }
})

test_that("GUI estimates are identical to direct upstream estimate calls", {
  phy <- load_example_phy()
  tips <- list(as.character(tip_des_safe(phy, 8)))
  cases <- list(
    cauchy = list(MCMCtreeR::estimateCauchy, list(minAge = 1.5, maxAge = 3, plot = FALSE)),
    skewT = list(MCMCtreeR::estimateSkewT, list(minAge = 1.5, maxAge = 3, plot = FALSE)),
    skewNormal = list(MCMCtreeR::estimateSkewNormal, list(minAge = 1.5, maxAge = 3, plot = FALSE)),
    gamma = list(MCMCtreeR::estimateGamma, list(minAge = 1.5, maxAge = 3, plot = FALSE)),
    bound = list(MCMCtreeR::estimateBound, list(minAge = 1.5, maxAge = 3, plot = FALSE)),
    upper = list(MCMCtreeR::estimateUpper, list(maxAge = 3)),
    fixed = list(MCMCtreeR::estimateFixed, list(minAge = 1.5))
  )
  for (method in names(cases)) {
    one <- new_calibration(8, tips[[1]], method)
    one$minAge <- 1.5
    one$maxAge <- 3
    gui <- run_estimation(phy, list(one))
    direct <- suppressWarnings(do.call(
      cases[[method]][[1]],
      c(list(phy = phy, monoGroups = tips), cases[[method]][[2]],
        list(writeMCMCtree = FALSE))
    ))
    expect_identical(gui$nodes[[1]]$parameters, direct$parameters, info = method)
    expect_identical(
      as.character(gui$nodes[[1]]$nodeLabels),
      as.character(direct$nodeLabels)[1],
      info = method
    )
    expected_tre <- mcmctree_tree_df(apply_node_labels(
      phy, stats::setNames(list(as.character(direct$nodeLabels)[1]), "8")
    ))
    expect_identical(gui$final_tre, expected_tre, info = method)
  }
})

test_that("MCMCtreePhy reference agrees with the GUI for non-gamma methods", {
  phy <- load_example_phy()
  one <- new_calibration(8, tip_des_safe(phy, 8), "cauchy")
  one$minAge <- 1.5
  one$maxAge <- 3
  gui <- run_estimation(phy, list(one))
  reference <- suppressWarnings(reference_estimates(phy, list(one)))
  expect_identical(unname(as.numeric(gui$nodes[[1]]$parameters)), unname(as.numeric(reference[[1]])))
})

test_that("advanced values are merged into the node args", {
  phy <- load_example_phy()
  one <- new_calibration(8, tip_des_safe(phy, 8), "cauchy")
  one$minAge <- 1.5
  one$maxAge <- 3
  one$adv <- list(scale = 2, offset = 0.5, estimateScale = FALSE)
  args <- build_node_args(one, phy)
  expect_identical(args$scale, 2)
  expect_identical(args$offset, 0.5)
  expect_false(args$estimateScale)
})

test_that("calibration validation follows the method matrix", {
  phy <- load_example_phy()
  one <- new_calibration(8, tip_des_safe(phy, 8), "cauchy")
  expect_true(length(calibration_issues(list(one), include_adv = FALSE)) >= 2)

  one$minAge <- 2
  one$maxAge <- 3
  expect_length(calibration_issues(list(one), include_adv = FALSE), 0)

  upper <- new_calibration(10, tip_des_safe(phy, 10), "upper")
  upper$maxAge <- 1.2
  expect_length(calibration_issues(list(upper), include_adv = FALSE), 0)

  fixed <- new_calibration(11, tip_des_safe(phy, 11), "fixed")
  fixed$minAge <- 0.8
  expect_length(calibration_issues(list(fixed), include_adv = FALSE), 0)

  bad <- one
  bad$minAge <- 4
  bad$maxAge <- 3
  issues <- calibration_issues(list(bad), include_adv = FALSE)
  expect_true(any(vapply(issues, function(x) x$key == "err_min_lt_max", logical(1))))
})

test_that("advanced parameter parsing validates ranges and types", {
  parsed <- parse_adv_raw("cauchy", list(scale = "2", offset = "-1", minProb = "2"))
  expect_identical(parsed$values$scale, 2)
  expect_identical(parsed$errors$offset, "err_adv_range")
  expect_identical(parsed$errors$minProb, "err_adv_range")
  expect_identical(parse_adv_raw("cauchy", list(scale = "abc"))$errors$scale, "err_adv_numeric")
  expect_identical(
    parse_adv_raw("cauchy", list(estimateScale = "maybe"))$errors$estimateScale,
    "err_adv_logical"
  )
  expect_identical(parse_adv_raw("cauchy", list(estimateScale = "FALSE"))$values$estimateScale, FALSE)
})

test_that("calibration updates preserve order and filter advanced keys", {
  phy <- load_example_phy()
  cal <- list(
    new_calibration(8, tip_des_safe(phy, 8), "cauchy"),
    new_calibration(10, tip_des_safe(phy, 10), "cauchy")
  )
  cal[[1]]$adv_raw <- list(scale = "2", offset = "0.5")
  cal <- update_calibration(cal, 8, method = "upper")
  expect_identical(cal[[1]]$method, "upper")
  expect_true(is.na(cal[[1]]$minAge))
  expect_length(cal[[1]]$adv_raw, 0)
  expect_length(cal[[1]]$adv, 0)

  cal <- add_calibration(cal, 8, tip_des_safe(phy, 8))
  expect_length(cal, 2)
  cal <- remove_calibration(cal, 10)
  expect_length(cal, 1)
  expect_identical(cal[[1]]$node, 8L)
})

test_that("state hashing is stable and sensitive", {
  phy <- load_example_phy()
  cal <- list(new_calibration(8, tip_des_safe(phy, 8), "cauchy"))
  cal[[1]]$minAge <- 1.5
  cal[[1]]$maxAge <- 3

  h1 <- hash_business_inputs(phy, cal)
  h2 <- hash_business_inputs(phy, cal)
  expect_identical(h1, h2)
  expect_false(is_stale(h1, h2))

  cal[[1]]$minAge <- 1.6
  h3 <- hash_business_inputs(phy, cal)
  expect_false(identical(h1, h3))
  expect_true(is_stale(h1, h3))

  cal[[1]]$adv <- list(scale = 2)
  h4 <- hash_business_inputs(phy, cal)
  expect_false(identical(h3, h4))
})

test_that("node list parsing separates text, tips and internal nodes", {
  phy <- load_example_phy()
  parsed <- parse_node_list("8, 10, abc, 1, 999", phy)
  expect_identical(parsed$values, c(8L, 10L))
  expect_identical(parsed$invalid_text, "abc")
  expect_true(1L %in% parsed$tip_nodes)
  expect_true(999L %in% parsed$invalid_nodes)

  expect_length(parse_node_list("", phy)$values, 0)
})
