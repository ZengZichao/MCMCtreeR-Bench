# Validation, calibration helpers and result staleness hashing.

METHOD_SPECS <- list(
  cauchy = list(
    min = TRUE, max = TRUE,
    params = list(
      scale = list(type = "numeric", default = 1.5, min = 0, open_min = TRUE),
      offset = list(type = "numeric", default = 50, min = 0),
      minProb = list(type = "numeric", default = 0, min = 0, max = 1),
      maxProb = list(type = "numeric", default = 0.975, min = 0, max = 1),
      estimateScale = list(type = "logical", default = TRUE)
    )
  ),
  skewT = list(
    min = TRUE, max = TRUE,
    params = list(
      shape = list(type = "numeric", default = 50, min = 0, open_min = TRUE),
      scale = list(type = "numeric", default = 1.5, min = 0, open_min = TRUE),
      df = list(type = "numeric", default = 1, min = 0, open_min = TRUE),
      addMode = list(type = "numeric", default = 0, min = 0),
      minProb = list(type = "numeric", default = 0.003, min = 0, max = 1),
      maxProb = list(type = "numeric", default = 0.975, min = 0, max = 1),
      estimateScale = list(type = "logical", default = TRUE),
      estimateShape = list(type = "logical", default = FALSE),
      estimateMode = list(type = "logical", default = FALSE)
    )
  ),
  skewNormal = list(
    min = TRUE, max = TRUE,
    params = list(
      shape = list(type = "numeric", default = 50, min = 0, open_min = TRUE),
      scale = list(type = "numeric", default = 1.5, min = 0, open_min = TRUE),
      addMode = list(type = "numeric", default = 0, min = 0),
      minProb = list(type = "numeric", default = 0.003, min = 0, max = 1),
      maxProb = list(type = "numeric", default = 0.975, min = 0, max = 1),
      estimateScale = list(type = "logical", default = TRUE),
      estimateShape = list(type = "logical", default = FALSE),
      estimateMode = list(type = "logical", default = FALSE)
    )
  ),
  gamma = list(
    min = TRUE, max = TRUE,
    params = list(
      alpha = list(type = "numeric", default = 188, min = 0, open_min = TRUE),
      beta = list(type = "numeric", default = 2690, min = 0, open_min = TRUE),
      offset = list(type = "numeric", default = 0.1, min = 0),
      estimateAlpha = list(type = "logical", default = TRUE),
      estimateBeta = list(type = "logical", default = FALSE)
    )
  ),
  bound = list(
    min = TRUE, max = TRUE,
    params = list(
      minProb = list(type = "numeric", default = 0.025, min = 0, max = 1),
      rightTail = list(type = "numeric", default = 0.025, min = 0, max = 1)
    )
  ),
  upper = list(
    min = FALSE, max = TRUE,
    params = list(
      rightTail = list(type = "numeric", default = 0.025, min = 0, max = 1)
    )
  ),
  fixed = list(
    min = TRUE, max = FALSE,
    params = list()
  )
)

calibration_methods <- function() names(METHOD_SPECS)
calibration_method_labels <- function() {
  stats::setNames(calibration_methods(), calibration_methods())
}

missing_num <- function(x) {
  is.null(x) || length(x) == 0 || !is.finite(suppressWarnings(as.numeric(x))[1])
}

validate_tree <- function(phy) {
  issues <- list()
  n_tip <- tryCatch(ape::Ntip(phy), error = function(e) NA_integer_)
  n_node <- tryCatch(ape::Nnode(phy), error = function(e) NA_integer_)
  has_bl <- FALSE
  is_binary <- FALSE
  dup_tips <- FALSE
  tip_labels <- character()

  if (!inherits(phy, "phylo")) {
    issues <- c(issues, list(list(key = "err_parse_tree", args = list())))
  } else {
    tip_labels <- phy$tip.label %||% character()
    dup_tips <- anyDuplicated(tip_labels) > 0
    has_bl <- !is.null(phy$edge.length) &&
      length(phy$edge.length) == nrow(phy$edge) &&
      all(!is.na(phy$edge.length))
    is_binary <- isTRUE(tryCatch(ape::is.binary(phy), error = function(e) FALSE))
    if (dup_tips) {
      issues <- c(issues, list(list(key = "err_duplicate_tips", args = list())))
    }
  }

  list(
    n_tip = n_tip,
    n_node = n_node,
    has_branch_lengths = has_bl,
    is_binary = is_binary,
    duplicate_tips = dup_tips,
    tip_labels = tip_labels,
    issues = issues
  )
}

read_tree_file <- function(path) {
  ext <- tolower(tools::file_ext(path))
  phy <- NULL
  multiple <- FALSE
  if (ext %in% c("nexus", "nex")) {
    phy <- tryCatch(ape::read.nexus(path), error = function(e) NULL)
  } else {
    phy <- tryCatch(ape::read.tree(path), error = function(e) NULL)
  }
  if (is.null(phy)) stop(app_error("err_parse_tree"))
  if (inherits(phy, "multiPhylo")) {
    multiple <- TRUE
    if (length(phy) == 0) stop(app_error("err_parse_tree"))
    phy <- phy[[1]]
  }
  list(phy = phy, multiple = multiple)
}

parse_newick <- function(text) {
  text <- paste(trimws(as.character(text %||% "")), collapse = "")
  if (!nzchar(text)) stop(app_error("err_parse_tree"))
  if (nchar(text) > 5 * 1024^2) stop(app_error("err_object_size"))
  if (!endsWith(text, ";")) text <- paste0(text, ";")
  phy <- tryCatch(ape::read.tree(text = text), error = function(e) NULL)
  if (is.null(phy)) stop(app_error("err_parse_tree"))
  if (inherits(phy, "multiPhylo")) {
    if (length(phy) == 0) stop(app_error("err_parse_tree"))
    return(list(phy = phy[[1]], multiple = TRUE))
  }
  list(phy = phy, multiple = FALSE)
}

new_calibration <- function(node, tips, method = "cauchy") {
  list(
    node = as.integer(node),
    tips = as.character(tips),
    minAge = NA_real_,
    maxAge = NA_real_,
    method = method,
    adv = list(),
    adv_raw = list()
  )
}

add_calibration <- function(calibrated, node, tips, method = "cauchy") {
  node <- as.integer(node)
  if (any(vapply(calibrated, function(x) identical(as.integer(x$node), node), logical(1)))) {
    return(calibrated)
  }
  c(calibrated, list(new_calibration(node, tips, method)))
}

remove_calibration <- function(calibrated, node) {
  node <- as.integer(node)
  calibrated[!vapply(calibrated, function(x) identical(as.integer(x$node), node), logical(1))]
}

update_calibration <- function(calibrated, node, ..., clear_adv = FALSE) {
  node <- as.integer(node)
  fields <- list(...)
  for (i in seq_along(calibrated)) {
    if (!identical(as.integer(calibrated[[i]]$node), node)) next
    method_changed <- !is.null(fields$method) &&
      !identical(fields$method, calibrated[[i]]$method)
    for (name in names(fields)) {
      calibrated[[i]][[name]] <- fields[[name]]
    }
    if (method_changed) {
      spec <- METHOD_SPECS[[calibrated[[i]]$method]]
      if (identical(calibrated[[i]]$method, "upper")) calibrated[[i]]$minAge <- NA_real_
      if (identical(calibrated[[i]]$method, "fixed")) calibrated[[i]]$maxAge <- NA_real_
      allowed <- if (is.null(spec)) character() else names(spec$params)
      calibrated[[i]]$adv_raw <- calibrated[[i]]$adv_raw[intersect(names(calibrated[[i]]$adv_raw), allowed)]
      calibrated[[i]]$adv <- calibrated[[i]]$adv[intersect(names(calibrated[[i]]$adv), allowed)]
    }
    if (isTRUE(clear_adv)) {
      calibrated[[i]]$adv <- list()
      calibrated[[i]]$adv_raw <- list()
    }
  }
  calibrated
}

set_adv_raw <- function(calibrated, node, raw) {
  node <- as.integer(node)
  for (i in seq_along(calibrated)) {
    if (!identical(as.integer(calibrated[[i]]$node), node)) next
    calibrated[[i]]$adv_raw <- raw
    calibrated[[i]]$adv <- parse_adv_raw(calibrated[[i]]$method, raw)$values
  }
  calibrated
}

parse_optional_number <- function(value) {
  value <- trimws(as.character(value %||% "")[1])
  if (!nzchar(value) || is.na(value)) return(list(value = NULL, error = NULL))
  number <- suppressWarnings(as.numeric(value))
  if (is.na(number) || !is.finite(number)) {
    return(list(value = NULL, error = "err_adv_numeric"))
  }
  list(value = number, error = NULL)
}

parse_optional_logical <- function(value) {
  value <- toupper(trimws(as.character(value %||% "")[1]))
  if (!nzchar(value) || is.na(value)) return(list(value = NULL, error = NULL))
  if (value %in% c("TRUE", "T", "1")) return(list(value = TRUE, error = NULL))
  if (value %in% c("FALSE", "F", "0")) return(list(value = FALSE, error = NULL))
  list(value = NULL, error = "err_adv_logical")
}

parse_adv_raw <- function(method, raw) {
  spec <- METHOD_SPECS[[method]]
  values <- list()
  if (is.null(spec) || length(spec$params) == 0) {
    return(list(values = values, errors = list()))
  }
  errors <- list()
  for (param in names(spec$params)) {
    info <- spec$params[[param]]
    parsed <- if (identical(info$type, "logical")) {
      parse_optional_logical(raw[[param]])
    } else {
      parse_optional_number(raw[[param]])
    }
    if (!is.null(parsed$error)) {
      errors[[param]] <- parsed$error
      next
    }
    value <- parsed$value
    if (is.null(value)) next
    if (identical(info$type, "numeric")) {
      if (!is.null(info$min) && value < info$min) {
        errors[[param]] <- "err_adv_range"; next
      }
      if (isTRUE(info$open_min) && value <= info$min) {
        errors[[param]] <- "err_adv_range"; next
      }
      if (!is.null(info$max) && value > info$max) {
        errors[[param]] <- "err_adv_range"; next
      }
    }
    values[[param]] <- value
  }
  list(values = values, errors = errors)
}

adv_field_issues <- function(one) {
  spec <- METHOD_SPECS[[one$method]]
  if (is.null(spec)) return(list())
  parsed <- parse_adv_raw(one$method, one$adv_raw %||% list())
  parsed$errors
}

advanced_issues <- function(calibrated) {
  issues <- list()
  for (one in calibrated) {
    for (param in names(adv_field_issues(one))) {
      issues <- c(issues, list(list(
        key = adv_field_issues(one)[[param]],
        args = list(one$node, param)
      )))
    }
  }
  issues
}

calibration_issues <- function(calibrated, include_adv = TRUE) {
  issues <- list()
  if (length(calibrated) == 0) {
    return(list(list(key = "err_no_nodes", args = list())))
  }
  for (one in calibrated) {
    method <- one$method %||% ""
    if (!nzchar(method) || is.null(METHOD_SPECS[[method]])) {
      issues <- c(issues, list(list(key = "err_method_required", args = list(one$node))))
      next
    }
    spec <- METHOD_SPECS[[method]]
    min_missing <- missing_num(one$minAge)
    max_missing <- missing_num(one$maxAge)
    if (isTRUE(spec$min)) {
      if (min_missing) {
        issues <- c(issues, list(list(key = "err_min_required", args = list(one$node))))
      } else if (as.numeric(one$minAge) < 0) {
        issues <- c(issues, list(list(key = "err_age_negative", args = list(one$node))))
      }
    }
    if (isTRUE(spec$max)) {
      if (max_missing) {
        issues <- c(issues, list(list(key = "err_max_required", args = list(one$node))))
      } else if (as.numeric(one$maxAge) < 0) {
        issues <- c(issues, list(list(key = "err_age_negative", args = list(one$node))))
      }
    }
    if (isTRUE(spec$min) && isTRUE(spec$max) && !min_missing && !max_missing) {
      if (as.numeric(one$minAge) >= as.numeric(one$maxAge)) {
        issues <- c(issues, list(list(key = "err_min_lt_max", args = list(one$node))))
      }
    }
    if (isTRUE(include_adv)) {
      for (param in names(adv_field_issues(one))) {
        issues <- c(issues, list(list(
          key = adv_field_issues(one)[[param]],
          args = list(one$node, param)
        )))
      }
    }
  }
  issues
}

calibration_valid <- function(calibrated, include_adv = TRUE) {
  length(calibrated) > 0 && length(calibration_issues(calibrated, include_adv = include_adv)) == 0
}

advanced_valid <- function(calibrated) {
  length(advanced_issues(calibrated)) == 0
}

issue_text <- function(issue, i18n) {
  tryCatch(
    do.call(i18n$tr, c(list(issue$key), issue$args)),
    error = function(e) issue$key
  )
}

parse_numeric_vector <- function(text) {
  text <- trimws(as.character(text %||% "")[1])
  if (!nzchar(text) || is.na(text)) return(list(values = numeric(), invalid = character()))
  pieces <- trimws(unlist(strsplit(text, "[,;[:space:]]+")))
  pieces <- pieces[nzchar(pieces)]
  values <- suppressWarnings(as.numeric(pieces))
  invalid <- pieces[is.na(values)]
  list(values = values[!is.na(values)], invalid = invalid)
}

parse_node_list <- function(text, phy = NULL) {
  parsed <- parse_numeric_vector(text)
  values <- unique(as.integer(parsed$values))
  invalid_nodes <- integer()
  tip_nodes <- integer()
  if (!is.null(phy)) {
    n_tip <- ape::Ntip(phy)
    max_node <- n_tip + ape::Nnode(phy)
    invalid_nodes <- values[values < 1 | values > max_node]
    tip_nodes <- values[values >= 1 & values <= n_tip]
    values <- values[values > n_tip & values <= max_node]
  }
  list(
    values = sort(values),
    invalid_text = parsed$invalid,
    invalid_nodes = invalid_nodes,
    tip_nodes = tip_nodes
  )
}

parse_node_ages_table <- function(path, phy = NULL) {
  table <- tryCatch(
    data.table::fread(path, data.table = FALSE, check.names = FALSE),
    error = function(e) NULL
  )
  if (is.null(table) || nrow(table) == 0 || ncol(table) < 2) {
    stop(app_error("err_nodeages_format"))
  }
  first <- tolower(names(table)[1])
  if (!first %in% c("node", "nodes", "node_number")) {
    stop(app_error("err_nodeages_format"))
  }
  node_values <- suppressWarnings(as.integer(table[[1]]))
  if (anyNA(node_values)) stop(app_error("err_nodeages_format"))

  if (ncol(table) == 2) {
    ages <- suppressWarnings(as.numeric(table[[2]]))
    if (anyNA(ages)) stop(app_error("err_nodeages_format"))
    by_node <- split(ages, node_values)
    node_ages <- lapply(by_node, function(x) as.numeric(x))
  } else {
    sample_matrix <- suppressWarnings(as.matrix(table[, -1, drop = FALSE]))
    sample_matrix <- apply(sample_matrix, 2, as.numeric)
    if (anyNA(sample_matrix)) stop(app_error("err_nodeages_format"))
    node_ages <- lapply(seq_len(nrow(sample_matrix)), function(i) as.numeric(sample_matrix[i, ]))
    names(node_ages) <- as.character(node_values)
  }

  names(node_ages) <- as.character(as.integer(names(node_ages)))
  if (any(vapply(node_ages, length, integer(1)) < 2)) {
    stop(app_error("err_nodeages_format"))
  }
  if (!is.null(phy)) {
    internal <- (ape::Ntip(phy) + 1):(ape::Ntip(phy) + ape::Nnode(phy))
    bad <- setdiff(as.integer(names(node_ages)), internal)
    if (length(bad)) {
      stop(app_error("err_nodeages_nodes", paste(bad, collapse = ", ")))
    }
    missing <- setdiff(internal, as.integer(names(node_ages)))
    if (length(missing)) {
      stop(app_error("err_nodeages_missing", paste(missing, collapse = ", ")))
    }
  }
  list(node_ages = node_ages, n_nodes = length(node_ages))
}

chain_tn_columns <- function(names) {
  which(grepl("^t_n[0-9]+$", as.character(names)))
}

hash_business_inputs <- function(phy, calibrated, dir = tempdir()) {
  canonical <- list(
    tree = list(
      tip.label = phy$tip.label %||% character(),
      edge = phy$edge %||% matrix(integer(), 0, 2),
      edge.length = phy$edge.length %||% numeric(),
      Nnode = phy$Nnode %||% 0L
    ),
    calibrated = lapply(calibrated, function(one) {
      adv <- sort_named_list(one$adv %||% list())
      list(
        node = as.integer(one$node),
        tips = as.character(one$tips),
        minAge = if (missing_num(one$minAge)) NA_real_ else as.numeric(one$minAge),
        maxAge = if (missing_num(one$maxAge)) NA_real_ else as.numeric(one$maxAge),
        method = as.character(one$method),
        adv = adv
      )
    })
  )
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  path <- tempfile("state-hash-", tmpdir = dir, fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(canonical, path)
  unname(tools::md5sum(path))
}

is_stale <- function(results_input, current_hash) {
  if (is.null(results_input) || is.null(current_hash)) return(TRUE)
  !identical(as.character(results_input)[1], as.character(current_hash)[1])
}

tre_text <- function(tre) {
  if (is.null(tre)) return("")
  if (is.data.frame(tre)) {
    lines <- utils::capture.output(
      utils::write.table(tre, quote = FALSE, row.names = FALSE, col.names = FALSE)
    )
    return(paste(lines, collapse = "\n"))
  }
  paste(as.character(tre), collapse = "\n")
}

has_unsaved_state <- function(a, b) {
  a <- a %||% list()
  b <- b %||% list()
  a_loaded <- !is.null(a$phy) ||
    (is.character(a$tree_paste_text) && any(nzchar(a$tree_paste_text))) ||
    length(a$calibrated) > 0L
  b_loaded <- !is.null(b$phy) || !is.null(b$chain) ||
    !is.null(b$node_ages) || !is.null(b$directory.files)
  isTRUE(a_loaded || b_loaded)
}

parameter_summary <- function(results) {
  if (is.null(results) || length(results$nodes) == 0) {
    return(data.frame(node = integer(), method = character(), parameters = character()))
  }
  rows <- lapply(results$nodes, function(one) {
    params <- one$parameters
    values <- as.numeric(params)
    labels <- colnames(params)
    if (is.null(labels) || length(labels) != length(values)) {
      labels <- names(params)
    }
    if (is.null(labels) || length(labels) != length(values)) {
      labels <- paste0("p", seq_along(values))
    }
    text <- paste(
      paste0(labels, "=", format(values, trim = TRUE)),
      collapse = ", "
    )
    data.frame(
      node = as.integer(one$node),
      method = one$method,
      parameters = text,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}
