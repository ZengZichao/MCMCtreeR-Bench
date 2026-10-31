# Session-scoped workspace helpers.
#
# All files written by the app live under tempdir()/<session token>/<subdir>.
# No path is ever derived from user input without basename() and validation.

session_token <- function(session = NULL, token = NULL) {
  value <- token
  if (is.null(value) && !is.null(session)) {
    value <- tryCatch(session$token, error = function(e) NULL)
  }
  value <- as.character(value %||% "session")[1]
  value <- gsub("[^A-Za-z0-9._-]", "_", value)
  if (!nzchar(value)) value <- "session"
  value
}

session_workspace <- function(session = NULL, sub = "uploads",
                              root = tempdir(), token = NULL) {
  ws <- file.path(
    root,
    session_token(session = session, token = token),
    gsub("[^A-Za-z0-9._-]", "_", as.character(sub)[1] %||% "uploads")
  )
  dir.create(ws, showWarnings = FALSE, recursive = TRUE)
  if (!dir.exists(ws)) stop(app_error("err_no_workspace"))
  ws
}

clean_session_workspace <- function(session = NULL, root = tempdir(), token = NULL) {
  path <- file.path(root, session_token(session = session, token = token))
  if (dir.exists(path)) unlink(path, recursive = TRUE, force = TRUE)
  invisible(!dir.exists(path))
}

safe_upload_name <- function(name) {
  name <- enc2utf8(as.character(name)[1])
  if (is.na(name)) stop(app_error("err_bad_filename", "<NA>"))
  name <- basename(name)
  if (!nzchar(name) || name %in% c(".", "..") ||
      grepl("[/\\\\]", name) || grepl("[[:cntrl:]]", name)) {
    stop(app_error("err_bad_filename", name))
  }
  name
}

has_allowed_extension <- function(name, allowed = allowed_upload_extensions()) {
  name <- tolower(basename(as.character(name)[1]))
  any(vapply(allowed, function(ext) endsWith(name, tolower(ext)), logical(1)))
}

stage_uploaded_files <- function(files, workspace, allowed = allowed_upload_extensions()) {
  if (is.null(files)) stop(app_error("err_no_file_selected"))
  if (nrow(files) == 0) stop(app_error("err_file_empty"))
  dest_paths <- character(nrow(files))
  sizes <- numeric(nrow(files))

  for (i in seq_len(nrow(files))) {
    name <- safe_upload_name(files$name[i])
    if (!has_allowed_extension(name, allowed)) {
      stop(app_error("err_bad_extension", name, paste(allowed, collapse = ", ")))
    }
    dest <- file.path(workspace, name)
    ok <- file.copy(files$datapath[i], dest, overwrite = TRUE)
    if (!isTRUE(ok)) stop(app_error("err_file_read", name))
    dest_paths[i] <- dest
    sizes[i] <- as.numeric(file.info(dest)$size %||% 0)
  }

  data.frame(
    name = vapply(files$name, safe_upload_name, character(1)),
    path = dest_paths,
    size = sizes,
    stringsAsFactors = FALSE
  )
}

assert_in_workspace <- function(path, workspace) {
  path <- normalizePath(path, mustWork = TRUE)
  ws <- normalizePath(workspace, mustWork = TRUE)
  if (identical(path, ws)) return(path)
  if (!startsWith(path, paste0(ws, .Platform$file.sep))) {
    stop(app_error("err_path_outside"))
  }
  path
}

list_workspace_files <- function(workspace) {
  list.files(workspace, full.names = TRUE, recursive = FALSE)
}

require_literal_suffix <- function(names, suffix) {
  names <- as.character(names)
  keep <- endsWith(tolower(names), tolower(suffix))
  names[keep]
}

write_text_file <- function(path, text) {
  con <- file(path, open = "wb")
  on.exit(close(con), add = TRUE)
  writeLines(enc2utf8(text), con = con, useBytes = TRUE)
  invisible(path)
}
