test_that("server paths are redacted", {
  message <- paste("failed in", tempdir(), "during read")
  redacted <- sanitize_paths(message)
  expect_false(grepl(tempdir(), redacted, fixed = TRUE))
  expect_true(grepl("<tmp>", redacted, fixed = TRUE))
  expect_identical(sanitize_paths(""), "")
})

test_that("app errors are translated and keep actionable details", {
  stub <- list(tr = function(key, ...) tr("en", key, ...))
  err <- app_error("err_bad_extension", "x.zip", ".tre, .nwk")
  fmt <- format_error(err, stub)
  expect_identical(fmt$key, "err_bad_extension")
  expect_true(grepl("x.zip", fmt$text, fixed = TRUE))
  expect_true(grepl(".tre", fmt$text, fixed = TRUE))

  tech <- simpleError(paste("boom in", tempdir()))
  fmt <- format_error(tech, stub, fallback = "err_export_failed")
  expect_true(grepl("boom", fmt$detail, fixed = TRUE))
  expect_false(grepl(tempdir(), fmt$detail, fixed = TRUE))
  expect_identical(error_text(fmt), paste(fmt$text, fmt$detail, sep = " - "))
})

test_that("upstream warnings are muffled but retained", {
  result <- run_with_warnings({
    warning("Length of node.label does not match number of nodes.")
    42
  }, logger = function(x) NULL)
  expect_identical(result$value, 42)
  expect_length(result$warnings, 1)

  classes <- classify_warnings(result$warnings)
  expect_length(classes$known, 1)
  expect_length(classes$unknown, 0)
})

test_that("button click detection ignores initial values", {
  expect_false(is_button_click(NULL))
  expect_false(is_button_click(0))
  expect_false(is_button_click("0"))
  expect_true(is_button_click(1))
  expect_true(is_button_click("2"))
  expect_false(is_button_click(c(1, 2)))
})

test_that("bslib task buttons count as clicks", {
  # input_task_button sends list(value = n, autoReset = TRUE); the numeric-only
  # check used to treat every task button as untouched.
  expect_true(is_button_click(list(value = 1, autoReset = TRUE)))
  expect_false(is_button_click(list(value = 0, autoReset = TRUE)))
  expect_false(is_button_click(list(value = numeric(), autoReset = TRUE)))
})
