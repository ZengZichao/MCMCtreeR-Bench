# Download helpers. Filenames are always ASCII.

content_type_for <- function(filename) {
  ext <- tolower(tools::file_ext(filename))
  switch(
    ext,
    pdf = "application/pdf",
    png = "image/png",
    svg = "image/svg+xml",
    tre = "text/plain; charset=utf-8",
    txt = "text/plain; charset=utf-8",
    "application/octet-stream"
  )
}

copy_download_file <- function(source, target, workspace) {
  source <- assert_export_path(source, workspace)
  ok <- file.copy(source, target, overwrite = TRUE)
  if (!isTRUE(ok)) stop(app_error("err_export_failed"))
  invisible(target)
}
