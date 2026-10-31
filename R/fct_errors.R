# User-facing errors and warning classification.
#
# Internal code signals expected problems with app_error("key", ...). Modules
# translate the key and arguments. Unexpected errors keep their original text
# (useful for bug reports) after server paths have been redacted.

app_error <- function(key, ..., detail = NULL) {
  args <- list(...)
  structure(
    list(message = key, key = key, args = args, detail = detail),
    class = c("mcmctreer_error", "error", "condition")
  )
}

is_app_error <- function(x) inherits(x, "mcmctreer_error")

is_button_click <- function(value) {
  if (is.null(value) || length(value) != 1) return(FALSE)
  value <- suppressWarnings(as.numeric(value))
  is.finite(value) && value > 0
}

sanitize_paths <- function(message) {
  message <- as.character(message %||% "")[1]
  if (!nzchar(message)) return(message)
  candidates <- unique(c(
    tryCatch(normalizePath(tempdir(), mustWork = FALSE), error = function(e) NULL),
    tempdir()
  ))
  for (path in candidates) {
    if (!is.null(path) && nzchar(path)) {
      message <- gsub(path, "<tmp>", message, fixed = TRUE)
    }
  }
  # macOS exposes /var as a symlink to /private/var; redact both spellings.
  message <- gsub("/private/var/folders/[^[:space:]]+", "<tmp>", message)
  message <- gsub("/var/folders/[^[:space:]]+", "<tmp>", message)
  message
}

format_error <- function(err, i18n = NULL, fallback = "err_plot_failed") {
  tr_fun <- if (is.null(i18n)) {
    function(key, ...) tr("en", key, ...)
  } else {
    i18n$tr
  }

  if (is_app_error(err)) {
    text <- tryCatch(
      do.call(tr_fun, c(list(err$key), err$args)),
      error = function(e) err$key
    )
    detail <- if (is.null(err$detail)) NULL else sanitize_paths(err$detail)
    return(list(text = text, detail = detail, key = err$key))
  }

  detail <- sanitize_paths(conditionMessage(err))
  list(
    text = tr_fun(fallback),
    detail = detail,
    key = fallback
  )
}

error_text <- function(fmt) {
  parts <- c(fmt$text, fmt$detail)
  parts <- parts[!vapply(parts, is.null, logical(1))]
  paste(parts, collapse = " - ")
}

run_with_warnings <- function(expr, logger = function(x) message("[upstream warning] ", x)) {
  warnings <- character()
  value <- withCallingHandlers(
    expr,
    warning = function(w) {
      msg <- conditionMessage(w)
      warnings <<- c(warnings, msg)
      try(logger(msg), silent = TRUE)
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = unique(warnings))
}

known_upstream_warning <- function(message) {
  grepl("Length of node.label does not match number of nodes", message, fixed = TRUE) ||
    grepl("warning - .* parameter value recycled", message) ||
    grepl("warning - .* argument recycled", message)
}

classify_warnings <- function(warnings) {
  warnings <- as.character(warnings %||% character())
  known <- warnings[vapply(warnings, known_upstream_warning, logical(1))]
  unknown <- setdiff(warnings, known)
  list(known = unique(known), unknown = unique(unknown))
}

user_notification <- function(message, type = "message", duration = 4) {
  # Successful actions already update the workbench inline; keep the floating
  # layer reserved for warnings and errors so it never competes with the work.
  if (identical(type, "message")) return(invisible(NULL))
  shiny::showNotification(
    shiny::HTML(htmltools::htmlEscape(message)),
    type = type,
    duration = duration
  )
}
