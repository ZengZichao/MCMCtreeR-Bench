test_that("build_mono_groups always returns a list", {
  phy <- load_example_phy()
  one <- build_mono_groups(phy, 8)
  expect_type(one, "list")
  expect_length(one, 1)
  expect_identical(names(one), "8")
  expect_gt(length(one[[1]]), 1)
  expect_type(one[[1]], "character")

  many <- build_mono_groups(phy, c(8, 10))
  expect_length(many, 2)
  expect_identical(names(many), c("8", "10"))
  expect_identical(many[["10"]], MCMCtreeR::tipDes(phy, 10))
})

test_that("invalid calibration nodes are rejected", {
  phy <- load_example_phy()
  expect_app_error(build_mono_groups(phy, 1), "err_invalid_node")
  expect_app_error(build_mono_groups(phy, 999), "err_invalid_node")
  expect_app_error(build_mono_groups(phy, integer()), "err_no_nodes")

  expect_app_error(tip_des_safe(phy, 1), "err_invalid_node")
  expect_type(tip_des_safe(phy, 8), "character")
})

test_that("nodes with the same tips keep their order", {
  phy <- load_example_phy()
  groups <- build_mono_groups(phy, c(13, 8, 10))
  expect_identical(names(groups), c("13", "8", "10"))
  expect_identical(groups[["8"]], tip_des_safe(phy, 8))
})
