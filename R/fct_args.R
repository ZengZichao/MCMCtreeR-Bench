# Build per-node argument lists and run the upstream estimation functions.
#
# GUI main path: one estimateXxx() call per node. MCMCtreePhy() is only used
# as a reference in integration tests (it drops apePhy/MCMCtree and has a
# gamma/estimateAlpha bug in the upstream source).

build_node_args <- function(one, phy) {
  common <- list(
    phy = phy,
    monoGroups = list(as.character(one$tips))
  )
  ages <- switch(
    one$method,
    upper = list(maxAge = as.numeric(one$maxAge)),
    fixed = list(minAge = as.numeric(one$minAge)),
    list(
      minAge = as.numeric(one$minAge),
      maxAge = as.numeric(one$maxAge)
    )
  )
  adv <- one$adv %||% list()
  args <- c(common, ages, adv)
  duplicates <- names(args)[duplicated(names(args))]
  duplicates <- setdiff(duplicates, "phy")
  if (length(duplicates)) {
    stop(app_error("err_adv_range", one$node, paste(duplicates, collapse = ", ")))
  }
  args
}

estimate_one_node <- function(one, phy) {
  args <- build_node_args(one, phy)
  switch(
    one$method,
    cauchy = do.call(
      MCMCtreeR::estimateCauchy,
      c(args, list(plot = FALSE, writeMCMCtree = FALSE))
    ),
    upper = do.call(
      MCMCtreeR::estimateUpper,
      c(args, list(writeMCMCtree = FALSE))
    ),
    bound = do.call(
      MCMCtreeR::estimateBound,
      c(args, list(plot = FALSE, writeMCMCtree = FALSE))
    ),
    fixed = do.call(
      MCMCtreeR::estimateFixed,
      c(args, list(writeMCMCtree = FALSE))
    ),
    gamma = do.call(
      MCMCtreeR::estimateGamma,
      c(args, list(plot = FALSE, writeMCMCtree = FALSE))
    ),
    skewNormal = do.call(
      MCMCtreeR::estimateSkewNormal,
      c(args, list(plot = FALSE, writeMCMCtree = FALSE))
    ),
    skewT = do.call(
      MCMCtreeR::estimateSkewT,
      c(args, list(plot = FALSE, writeMCMCtree = FALSE))
    ),
    stop(app_error("err_unknown_method", one$method))
  )
}

run_estimation <- function(phy, calibrated, progress = NULL) {
  if (is.null(phy)) stop(app_error("err_no_tree"))
  if (!calibration_valid(calibrated)) {
    first <- calibration_issues(calibrated)[[1]]
    stop(do.call(app_error, c(list(first$key), first$args)))
  }

  nodes <- vector("list", length(calibrated))
  labels_by_node <- list()
  all_warnings <- character()

  for (i in seq_along(calibrated)) {
    one <- calibrated[[i]]
    if (is.function(progress)) progress(i, length(calibrated), one$node)

    outcome <- tryCatch(
      run_with_warnings(
        estimate_one_node(one, phy),
        logger = function(msg) {
          if (!known_upstream_warning(msg)) {
            message("[upstream warning] ", msg)
          }
        }
      ),
      error = function(e) e
    )
    if (inherits(outcome, "error")) {
      detail <- if (is_app_error(outcome)) outcome$key else conditionMessage(outcome)
      stop(app_error("err_estimate_node", one$node, detail = detail))
    }

    result <- outcome$value
    if (!is.list(result) || is.null(result$parameters) || is.null(result$MCMCtree)) {
      stop(app_error("err_estimate_node", one$node))
    }

    label <- as.character(result$nodeLabels)[1]
    labels_by_node[[as.character(one$node)]] <- label
    clean_phy <- apply_node_labels(phy, labels_by_node)

    all_warnings <- c(all_warnings, outcome$warnings)
    nodes[[i]] <- list(
      node = as.integer(one$node),
      method = one$method,
      tips = as.character(one$tips),
      minAge = one$minAge,
      maxAge = one$maxAge,
      adv = one$adv %||% list(),
      parameters = result$parameters,
      nodeLabels = label,
      apePhy = clean_phy,
      MCMCtree = mcmctree_tree_df(clean_phy),
      warnings = outcome$warnings
    )
  }

  list(
    nodes = nodes,
    final_phy = nodes[[length(nodes)]]$apePhy,
    final_tre = nodes[[length(nodes)]]$MCMCtree,
    warnings = unique(all_warnings),
    warning_class = classify_warnings(all_warnings),
    input_hash = hash_business_inputs(phy, calibrated),
    run_at = as.character(Sys.time())
  )
}

# Upstream nodeToPhy() writes phy$node.labels (plural) as a short vector.
# ape::write.tree() then recycles a single label across every internal node.
# Rebuilding a full-length node.label vector keeps only calibrated nodes
# labelled, without modifying the upstream package.
apply_node_labels <- function(phy, labels_by_node) {
  n_tip <- ape::Ntip(phy)
  n_node <- ape::Nnode(phy)
  labels <- rep("", n_node)
  for (node_text in names(labels_by_node)) {
    node <- suppressWarnings(as.integer(node_text))
    position <- node - n_tip
    if (is.finite(position) && position >= 1 && position <= n_node) {
      labels[position] <- as.character(labels_by_node[[node_text]])[1]
    }
  }
  out <- phy
  out$node.label <- labels
  out$node.labels <- NULL
  out
}

mcmctree_tree_df <- function(phy) {
  tree_text <- ape::write.tree(phy)
  tree_text <- gsub(")NA", ")", tree_text)
  tree_text <- gsub("\\[", "(", tree_text)
  tree_text <- gsub("\\]", ")", tree_text)
  tree_text <- gsub("~", ",", tree_text)
  names(tree_text) <- NULL
  out <- data.frame(
    cbind(paste(ape::Ntip(phy), "1"), tree_text, "//end of file"),
    stringsAsFactors = FALSE
  )
  colnames(out) <- c("", "", "")
  out
}

# Reference implementation used only by integration tests for non-gamma
# methods. The GUI never calls this function.
reference_estimates <- function(phy, calibrated) {
  methods <- vapply(calibrated, `[[`, character(1), "method")
  if (any(methods == "gamma")) {
    stop("MCMCtreePhy is not a valid reference for gamma; call estimateGamma() directly.")
  }
  n <- length(calibrated)
  params <- list(
    offset = numeric(n), df = numeric(n), shape = numeric(n), scale = numeric(n),
    minProb = numeric(n), addMode = numeric(n), maxProb = numeric(n),
    rightTail = numeric(n), alpha = numeric(n), beta = numeric(n),
    estimateScale = logical(n), estimateShape = logical(n), estimateMode = logical(n),
    estimateAlpha = logical(n), estimateBeta = logical(n)
  )
  for (i in seq_len(n)) {
    for (param in names(params)) {
      if (param %in% names(calibrated[[i]]$adv)) {
        params[[param]][i] <- calibrated[[i]]$adv[[param]]
      } else {
        def <- default_param_value(methods[i], param)
        params[[param]][i] <- if (is.null(def)) NA else def
      }
    }
  }
  min_ages <- vapply(calibrated, function(x) as.numeric(x$minAge), numeric(1))
  max_ages <- vapply(calibrated, function(x) as.numeric(x$maxAge), numeric(1))
  groups <- build_mono_groups(phy, vapply(calibrated, `[[`, integer(1), "node"))

  args <- c(
    list(
      phy = phy, minAges = min_ages, maxAges = max_ages,
      monoGroups = groups, method = methods, plot = FALSE,
      writeMCMCtree = FALSE
    ),
    params
  )
  do.call(MCMCtreeR::MCMCtreePhy, args)
}

default_param_value <- function(method, param) {
  spec <- METHOD_SPECS[[method]]
  if (is.null(spec) || is.null(spec$params[[param]])) return(NA)
  spec$params[[param]]$default
}
