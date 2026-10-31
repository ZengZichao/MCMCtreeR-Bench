# Assemble a validated call to MCMCtreeR::MCMC.tree.plot().
#
# The names of the returned list must be a subset of formals(MCMC.tree.plot);
# anything else would be swallowed by ... and silently ignored.

viz_defaults <- function() {
  list(
    plot_type = "phylogram",
    node_method = "bar",
    all_nodes_raw = "",
    add_time_scale = TRUE,
    add_abs_time = TRUE,
    scale_res = "Epoch",
    label_timescale_names = TRUE,
    time_correction = 1,
    col_age = "",
    tip_lengths = FALSE,
    density_col = "",
    density_border_col = "",
    cex_tips = 0.7,
    show_tip_label = TRUE,
    col_tree = "",
    tip_color = "",
    lwd_bar = 1,
    grey_bars = TRUE,
    cex_age = 0.8,
    cex_labels = 0.8,
    cex_names = 0.8,
    relative_height = 0.08,
    tip_bar_col = "",
    burn_in = 0.25,
    distribution_height = 0.8,
    abs_age_mgp = c(3, 0.35, 0),
    abs_age_mgp_raw = "3, 0.35, 0",
    abs_age_lwd_ticks = 0.7,
    abs_age_lwd = 0,
    tck_abs_age = -0.01,
    abs_age_line = -0.4,
    pos_age_auto = TRUE,
    pos_age = NULL,
    n_runs = 2,
    ladderize_tree = TRUE,
    build_tree = FALSE,
    plot_height_in = 7
  )
}

viz_ui_only_names <- function() {
  c("all_nodes_raw", "pos_age_auto", "abs_age_mgp_raw", "plot_height_in")
}

viz_auto_tip_cex <- function(n_tip) {
  n_tip <- as.numeric(n_tip)
  if (!is.finite(n_tip) || n_tip <= 0) return(0.7)
  if (n_tip > 200) 0.3 else if (n_tip > 150) 0.36 else if (n_tip > 100) 0.42 else if (n_tip > 60) 0.5 else if (n_tip > 30) 0.6 else 0.7
}

viz_auto_plot_height <- function(n_tip) {
  n_tip <- as.numeric(n_tip)
  if (!is.finite(n_tip) || n_tip <= 0) return(7)
  max(7, min(12, 4 + n_tip * 0.06))
}

viz_analysis_types <- function() {
  c("MCMCtree", "MrBayes", "RevBayes", "User")
}

viz_param_issues <- function(params, tree = NULL) {
  issues <- list()
  add <- function(key, ...) {
    issues <<- c(issues, list(list(key = key, args = list(...))))
  }

  if (!isTRUE(params$plot_type %in% c("phylogram", "cladogram", "distributions"))) {
    add("err_plot_type", params$plot_type)
  }
  if (!isTRUE(params$node_method %in% c("bar", "node.length", "full.length", "none"))) {
    add("err_node_method", params$node_method)
  }
  if (!length(params$scale_res) ||
      any(!params$scale_res %in% c("Eon", "Period", "Epoch", "Age"))) {
    add("err_scale_res")
  }

  numeric_checks <- list(
    cex_tips = c(0, 5),
    lwd_bar = c(0, 20),
    cex_age = c(0, 5),
    cex_labels = c(0, 5),
    cex_names = c(0, 5),
    relative_height = c(0, 1),
    distribution_height = c(0, 1),
    burn_in = c(0, 1),
    time_correction = c(0, 1e6),
    abs_age_lwd_ticks = c(0, 20),
    abs_age_lwd = c(0, 20),
    tck_abs_age = c(-1, 1),
    abs_age_line = c(-10, 10),
    n_runs = c(1, 20),
    plot_height_in = c(3, 12)
  )
  for (name in names(numeric_checks)) {
    value <- params[[name]]
    if (is.null(value) || length(value) != 1 || !is.finite(value) ||
        value < numeric_checks[[name]][1] || value > numeric_checks[[name]][2]) {
      add("err_numeric_param", name)
    }
  }

  if (is.null(params[["abs_age_mgp", exact = TRUE]]) ||
      length(params[["abs_age_mgp", exact = TRUE]]) != 3 ||
      any(!is.finite(params[["abs_age_mgp", exact = TRUE]]))) {
    add("err_numeric_param", "abs_age_mgp")
  }

  if (!isTRUE(params$pos_age_auto)) {
    pos_age_value <- params[["pos_age", exact = TRUE]]
    if (is.null(pos_age_value) || length(pos_age_value) != 1 ||
        !is.finite(pos_age_value)) {
      add("err_numeric_param", "pos_age")
    }
  }

  color_fields <- c("col_age", "density_col", "density_border_col",
                    "col_tree", "tip_color", "tip_bar_col")
  for (name in color_fields) {
    value <- as.character(params[[name]] %||% "")[1]
    if (nzchar(trimws(value)) && !is_valid_colour(value)) {
      add("err_color_invalid", value)
    }
  }

  all_nodes <- parse_all_nodes_param(params$all_nodes_raw, tree)
  if (length(all_nodes$invalid_text)) {
    add("err_all_nodes", paste(all_nodes$invalid_text, collapse = ", "))
  }
  if (length(all_nodes$invalid_nodes)) {
    add("err_all_nodes", paste(all_nodes$invalid_nodes, collapse = ", "))
  }
  if (length(all_nodes$tip_nodes)) {
    add("err_all_nodes", paste(all_nodes$tip_nodes, collapse = ", "))
  }

  list(issues = issues, all_nodes = all_nodes$values)
}

is_valid_colour <- function(value) {
  value <- as.character(value %||% "")[1]
  if (!nzchar(trimws(value))) return(TRUE)
  tryCatch({
    grDevices::col2rgb(trimws(value))
    TRUE
  }, error = function(e) FALSE)
}

parse_all_nodes_param <- function(text, tree = NULL) {
  text <- as.character(text %||% "")[1]
  if (!nzchar(trimws(text)) || is.na(text)) {
    return(list(values = NULL, invalid_text = character(),
                invalid_nodes = integer(), tip_nodes = integer()))
  }
  parsed <- parse_node_list(text, tree)
  list(
    values = if (length(parsed$values)) parsed$values else NULL,
    invalid_text = parsed$invalid_text,
    invalid_nodes = parsed$invalid_nodes,
    tip_nodes = parsed$tip_nodes
  )
}

viz_tree_for_validation <- function(b) {
  if (!is.null(b$phy)) {
    if (inherits(b$phy, "MCMCtreer")) return(b$phy$apePhy)
    if (inherits(b$phy, "phylo")) return(b$phy)
  }
  report <- b$source_report
  if (!is.null(report) && isTRUE(report$ok) &&
      is.finite(report$n_tip %||% NA_integer_) &&
      is.finite(report$n_node %||% NA_integer_)) {
    return(structure(
      list(
        tip.label = rep("", as.integer(report$n_tip)),
        edge = matrix(0L, nrow = 0, ncol = 2),
        Nnode = as.integer(report$n_node)
      ),
      class = "phylo"
    ))
  }
  NULL
}

build_viz_call <- function(b, cols = plot_colors("print")) {
  if (!isTRUE(b$data_ready)) stop(app_error("err_no_data_source"))
  analysis <- as.character(b$analysis_type %||% "")[1]
  if (!analysis %in% viz_analysis_types()) {
    stop(app_error("err_analysis_type", analysis))
  }

  params <- modifyList(viz_defaults(), b$params %||% list())
  tree <- viz_tree_for_validation(b)
  validation <- viz_param_issues(params, tree)
  if (length(validation$issues)) {
    first <- validation$issues[[1]]
    stop(do.call(app_error, c(list(first$key), first$args)))
  }

  plot_type <- params$plot_type
  if (identical(plot_type, "cladogram") && !identical(analysis, "MCMCtree")) {
    stop(app_error("err_cladogram_mcmctree"))
  }

  source_kind <- b$source_kind %||% ""
  chain <- b$chain
  if (identical(plot_type, "distributions")) {
    if (identical(analysis, "MCMCtree") &&
        identical(source_kind, "figtree") && is.null(chain)) {
      stop(app_error("err_missing_chain"))
    }
    if (identical(source_kind, "user") || identical(source_kind, "revbayes")) {
      # Upstream's guard requires a non-NULL MCMC.chain before dispatching to
      # the User/RevBayes distribution branches, even though those branches
      # never read it. A one-cell placeholder is therefore supplied.
      chain <- matrix(0, nrow = 1, ncol = 1)
    }
  }

  if (identical(analysis, "MCMCtree") && isTRUE(params$build_tree) &&
      identical(source_kind, "posterior") && is.null(chain)) {
    stop(app_error("err_missing_chain"))
  }

  if (identical(analysis, "MrBayes") && !is.null(b$source_report$n_runs) &&
      !is.na(b$source_report$n_runs) &&
      as.integer(params$n_runs) > as.integer(b$source_report$n_runs)) {
    stop(app_error(
      "err_mrbayes_runs",
      sprintf(".run%s.t", as.integer(b$source_report$n_runs) + 1L)
    ))
  }

  args <- list(
    phy = NULL,
    analysis.type = analysis,
    MCMC.chain = chain,
    node.ages = NULL,
    directory.files = NULL,
    plot.type = plot_type,
    build.tree = isTRUE(params$build_tree) && identical(analysis, "MCMCtree"),
    node.method = params$node_method,
    all.nodes = validation$all_nodes,
    add.time.scale = isTRUE(params$add_time_scale),
    add.abs.time = isTRUE(params$add_abs_time),
    scale.res = as.character(params$scale_res),
    label.timescale.names = isTRUE(params$label_timescale_names),
    time.correction = as.numeric(params$time_correction),
    col.age = resolve_plot_colour(params$col_age, cols$highlight),
    tip.lengths = isTRUE(params$tip_lengths),
    density.col = resolve_plot_colour(params$density_col, cols$density_fill),
    density.border.col = resolve_plot_colour(params$density_border_col, cols$density_border),
    cex.tips = as.numeric(params$cex_tips),
    show.tip.label = isTRUE(params$show_tip_label),
    col.tree = resolve_plot_colour(params$col_tree, cols$fg),
    tip.color = resolve_plot_colour(params$tip_color, cols$fg),
    lwd.bar = as.numeric(params$lwd_bar),
    grey.bars = isTRUE(params$grey_bars),
    cex.age = as.numeric(params$cex_age),
    cex.labels = as.numeric(params$cex_labels),
    cex.names = as.numeric(params$cex_names),
    relative.height = as.numeric(params$relative_height),
    tip.bar.col = resolve_plot_colour(params$tip_bar_col, cols$tip_bar),
    burn.in = as.numeric(params$burn_in),
    distribution.height = as.numeric(params$distribution_height),
    abs.age.mgp = as.numeric(params[["abs_age_mgp", exact = TRUE]]),
    abs.age.lwd.ticks = as.numeric(params$abs_age_lwd_ticks),
    abs.age.lwd = as.numeric(params$abs_age_lwd),
    tck.abs.age = as.numeric(params$tck_abs_age),
    abs.age.line = as.numeric(params$abs_age_line),
    pos.age = if (isTRUE(params$pos_age_auto)) NULL else as.numeric(params[["pos_age", exact = TRUE]]),
    n.runs = as.integer(params$n_runs),
    ladderize.tree = isTRUE(params$ladderize_tree)
  )

  if (identical(analysis, "MCMCtree")) {
    args$phy <- b$phy
    args$MCMC.chain <- b$chain
    args$build.tree <- isTRUE(params$build_tree) && identical(source_kind, "posterior")
  } else if (identical(analysis, "User")) {
    args$phy <- b$phy
    args$node.ages <- b$node_ages
  } else if (analysis %in% c("MrBayes", "RevBayes")) {
    args$directory.files <- b$directory.files
    args$phy <- NULL
    args$MCMC.chain <- chain
  }

  formals_names <- names(formals(MCMCtreeR::MCMC.tree.plot))
  unknown <- setdiff(names(args), formals_names)
  if (length(unknown)) {
    stop(app_error("err_viz_param", paste(unknown, collapse = ", ")))
  }
  args
}

viz_state_params <- function(params) {
  params[setdiff(names(params), viz_ui_only_names())]
}

# Read the module-B inputs into a params list. Missing inputs (hidden by a
# conditional panel) keep their previous value.
collect_viz_params <- function(input, current = NULL) {
  params <- modifyList(viz_defaults(), current %||% list())

  numeric_ids <- c(
    "relative_height", "cex_age", "cex_labels", "cex_names",
    "abs_age_lwd", "abs_age_lwd_ticks", "tck_abs_age", "abs_age_line",
    "lwd_bar", "distribution_height", "cex_tips", "time_correction",
    "burn_in", "n_runs", "plot_height_in"
  )
  for (id in numeric_ids) {
    value <- input[[id]]
    if (!is.null(value) && length(value) == 1 && is.finite(value)) {
      params[[id]] <- as.numeric(value)
    }
  }

  logical_ids <- c(
    "add_time_scale", "add_abs_time", "label_timescale_names", "grey_bars",
    "tip_lengths", "show_tip_label", "ladderize_tree", "build_tree"
  )
  for (id in logical_ids) {
    value <- input[[id]]
    if (!is.null(value)) params[[id]] <- isTRUE(value)
  }

  text_ids <- c(
    "all_nodes_raw", "col_age", "density_col", "density_border_col",
    "col_tree", "tip_color", "tip_bar_col"
  )
  for (id in text_ids) {
    value <- input[[id]]
    if (!is.null(value)) params[[id]] <- as.character(value)[1]
  }

  if (!is.null(input$plot_type)) params$plot_type <- as.character(input$plot_type)[1]
  if (!is.null(input$node_method)) params$node_method <- as.character(input$node_method)[1]
  if (!is.null(input$scale_res)) params$scale_res <- as.character(input$scale_res)

  mgp_raw <- input$abs_age_mgp
  if (!is.null(mgp_raw)) {
    params$abs_age_mgp_raw <- as.character(mgp_raw)[1]
    parsed <- parse_numeric_vector(params$abs_age_mgp_raw)
    if (length(parsed$values) == 3 && !length(parsed$invalid)) {
      params$abs_age_mgp <- parsed$values
    } else {
      params["abs_age_mgp"] <- list(NULL)
    }
  }

  if (!is.null(input$pos_age_auto)) params$pos_age_auto <- isTRUE(input$pos_age_auto)
  if (isTRUE(params$pos_age_auto)) {
    params["pos_age"] <- list(NULL)
  } else if (!is.null(input$pos_age) && length(input$pos_age) == 1 &&
             is.finite(input$pos_age)) {
    params$pos_age <- as.numeric(input$pos_age)
  }

  params
}
