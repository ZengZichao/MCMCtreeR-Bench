# Lightweight internationalisation helpers.
#
# This file contains pure functions and pure data only. It deliberately does
# not create a package-level reactiveVal: language is session state and lives
# in mod_shared_i18n.R.

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || (length(x) == 1 && is.na(x))) y else x
}

normalize_lang <- function(value) {
  value <- as.character(value %||% "en")[1]
  if (is.na(value) || !nzchar(value)) return("en")
  if (grepl("^zh", value, ignore.case = TRUE)) "zh" else "en"
}

sort_named_list <- function(x) {
  if (is.null(x) || !length(x)) return(list())
  nms <- names(x) %||% rep("", length(x))
  x[order(nms)]
}

translation_keys <- function(lang = NULL) {
  if (is.null(lang)) {
    return(sort(unique(c(names(TRANSLATIONS$en), names(TRANSLATIONS$zh)))))
  }
  sort(names(TRANSLATIONS[[normalize_lang(lang)]]))
}

tr <- function(lang, key, ...) {
  lang <- normalize_lang(lang)
  dict <- TRANSLATIONS[[lang]] %||% TRANSLATIONS$en
  msg <- dict[[key]] %||% TRANSLATIONS$en[[key]]
  if (is.null(msg)) msg <- paste0("\u27e8", key, "\u27e9")
  if (...length() > 0) {
    msg <- tryCatch(sprintf(msg, ...), error = function(e) msg)
  }
  msg
}

# Returns a data.frame describing dictionary problems. Used by tests and by
# the development checks; never shown to end users.
check_translations <- function() {
  en <- TRANSLATIONS$en
  zh <- TRANSLATIONS$zh
  problems <- character()

  missing_en <- setdiff(names(zh), names(en))
  missing_zh <- setdiff(names(en), names(zh))
  if (length(missing_en)) {
    problems <- c(problems, paste0("keys missing in en: ", paste(missing_en, collapse = ", ")))
  }
  if (length(missing_zh)) {
    problems <- c(problems, paste0("keys missing in zh: ", paste(missing_zh, collapse = ", ")))
  }

  for (key in intersect(names(en), names(zh))) {
    n_en <- lengths(regmatches(en[[key]], gregexpr("%s", en[[key]], fixed = TRUE)))
    n_zh <- lengths(regmatches(zh[[key]], gregexpr("%s", zh[[key]], fixed = TRUE)))
    if (!identical(n_en, n_zh)) {
      problems <- c(problems, paste0("placeholder mismatch for '", key, "'"))
    }
  }

  duplicated_en <- names(en)[duplicated(names(en))]
  duplicated_zh <- names(zh)[duplicated(names(zh))]
  if (length(duplicated_en)) {
    problems <- c(problems, paste0("duplicated en keys: ", paste(duplicated_en, collapse = ", ")))
  }
  if (length(duplicated_zh)) {
    problems <- c(problems, paste0("duplicated zh keys: ", paste(duplicated_zh, collapse = ", ")))
  }

  problems
}
