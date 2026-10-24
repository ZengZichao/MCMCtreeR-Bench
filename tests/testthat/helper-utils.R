# Shared test helpers.
library(shiny)
library(htmltools)

expect_app_error <- function(expr, key = NULL) {
  err <- tryCatch(expr, error = function(e) e)
  expect_true(is_app_error(err))
  if (!is.null(key)) expect_identical(err$key, key)
  invisible(err)
}

make_upload_df <- function(paths, names = basename(paths)) {
  sizes <- file.info(paths)$size
  data.frame(
    name = names,
    size = as.numeric(sizes),
    type = "text/plain",
    datapath = paths,
    stringsAsFactors = FALSE
  )
}

with_pdf_device <- function(code) {
  path <- tempfile(fileext = ".pdf")
  grDevices::pdf(path)
  on.exit({
    try(grDevices::dev.off(), silent = TRUE)
    unlink(path)
  }, add = TRUE)
  force(code)
}

load_example_phy <- function() {
  env <- new.env(parent = emptyenv())
  utils::data("apeData", package = "MCMCtreeR", envir = env)
  env$apeData$apeTree
}

load_mcmctree_output <- function() {
  env <- new.env()
  for (item in c("mcmctree.output", "MCMCtree.output")) {
    suppressWarnings(try(
      utils::data(list = item, package = "MCMCtreeR", envir = env),
      silent = TRUE
    ))
    if (length(ls(env))) return(env[[ls(env)[1]]])
  }
  stop("MCMCtreeR output data are not available")
}

pdf_page_count <- function(path) {
  raw <- readBin(path, "raw", n = file.info(path)$size)
  page <- length(grepRaw(charToRaw("/Type /Page"), raw, all = TRUE, fixed = TRUE))
  pages <- length(grepRaw(charToRaw("/Type /Pages"), raw, all = TRUE, fixed = TRUE))
  as.numeric(page - pages)
}

