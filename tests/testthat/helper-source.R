# Locate the package source tree.
#
# Source-text assertions (CSS rules, UI markup) need the files on disk. In a
# checkout the tests run from tests/testthat, two levels below the package
# root; under R CMD check the tests are copied into a temporary directory and
# the source tree is no longer reachable, so those assertions skip cleanly
# instead of failing.

pkg_source_root <- function() {
  candidates <- c(
    testthat::test_path("..", ".."),
    normalizePath(file.path(getwd(), "..", ".."), mustWork = FALSE)
  )
  for (cand in candidates) {
    if (file.exists(file.path(cand, "DESCRIPTION"))) return(cand)
  }
  NA_character_
}

source_file <- function(...) {
  root <- pkg_source_root()
  if (is.na(root)) testthat::skip("source tree not available")
  path <- file.path(root, ...)
  if (!file.exists(path)) {
    testthat::skip("source file not available: ", paste(..., collapse = "/"))
  }
  path
}

source_r_files <- function() {
  root <- pkg_source_root()
  if (is.na(root)) testthat::skip("source R directory not available")
  list.files(file.path(root, "R"), pattern = "\\.R$", full.names = TRUE)
}
