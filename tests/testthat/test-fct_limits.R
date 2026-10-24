test_that("upload limits are enforced", {
  path <- tempfile()
  writeBin(as.raw(1:10), path)
  on.exit(unlink(path), add = TRUE)

  ok <- check_upload_files(make_upload_df(path, "small.txt"))
  expect_true(ok$ok)

  big <- make_upload_df(path, "big.txt")
  big$size <- LIMITS$max_upload_bytes + 1
  result <- check_upload_files(big)
  expect_false(result$ok)
  expect_identical(result$key, "err_upload_too_big")

  empty <- make_upload_df(path, "empty.txt")
  empty$size <- 0
  expect_identical(check_upload_files(empty)$key, "err_file_empty")

  none <- data.frame(name = character(), size = numeric(), datapath = character())
  expect_identical(check_upload_files(none)$key, "err_file_empty")
})

test_that("tree limits are enforced", {
  phy <- load_example_phy()
  expect_true(check_tree_limits(phy)$ok)

  huge <- structure(
    list(
      tip.label = as.character(seq_len(LIMITS$max_tree_tips + 1)),
      edge = matrix(0L, nrow = 0, ncol = 2),
      Nnode = LIMITS$max_tree_nodes + 1L
    ),
    class = "phylo"
  )
  result <- check_tree_limits(huge)
  expect_false(result$ok)
  expect_true(result$key %in% c("err_tree_tips", "err_tree_nodes"))
})

test_that("posterior row limits are enforced", {
  ok <- check_posterior_limits(data.frame(x = seq_len(10)))
  expect_true(ok$ok)
  expect_identical(ok$n_rows, 10L)

  big <- data.frame(x = seq_len(LIMITS$max_posterior_rows + 1))
  result <- check_posterior_limits(big)
  expect_false(result$ok)
  expect_identical(result$key, "err_posterior_rows")
})

test_that("image dimensions are limited", {
  expect_true(check_pdf_size(16, 12)$ok)
  expect_false(check_pdf_size(17, 12)$ok)
  expect_false(check_pdf_size(10, 13)$ok)
  expect_true(check_png_size(12, 9, 200)$ok)
  expect_false(check_png_size(13, 9, 200)$ok)
  expect_false(check_png_size(10, 9, 300)$ok)
  expect_false(check_png_size(10, 9, NA)$ok)
})

test_that("object size checks are informative", {
  expect_true(check_object_size(list(1, 2, 3))$ok)
  expect_identical(format_mb(1024^2), 1)
})
