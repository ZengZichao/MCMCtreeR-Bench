make_figtree_b <- function() {
  output <- load_mcmctree_output()
  obj <- MCMCtreeR::readMCMCtree(output$MCMCtree.phy, from.file = FALSE)
  list(
    analysis_type = "MCMCtree",
    source_kind = "figtree",
    phy = obj,
    chain = NULL,
    node_ages = NULL,
    directory.files = NULL,
    data_ready = TRUE,
    params = viz_defaults(),
    source_report = list(
      ok = TRUE,
      n_tip = ape::Ntip(obj$apePhy),
      n_node = ape::Nnode(obj$apePhy)
    )
  )
}

test_that("plot call names match MCMC.tree.plot", {
  formals_names <- names(formals(MCMCtreeR::MCMC.tree.plot))
  b <- make_figtree_b()
  args <- build_viz_call(b, plot_colors("print"))
  expect_true(all(names(args) %in% formals_names))
  expect_false("..." %in% names(args))
  expect_identical(args$analysis.type, "MCMCtree")
  expect_identical(args$plot.type, "phylogram")
})

test_that("all four analysis types produce legal calls", {
  formals_names <- names(formals(MCMCtreeR::MCMC.tree.plot))
  b <- make_figtree_b()

  # Posterior mode
  tree <- b$phy$apePhy
  chain <- data.frame(t_n1 = 1:5, t_n2 = 2:6)
  posterior <- modifyList(b, list(
    source_kind = "posterior",
    phy = tree,
    chain = chain,
    params = modifyList(viz_defaults(), list(build_tree = TRUE)),
    source_report = list(ok = TRUE, n_tip = ape::Ntip(tree), n_node = ape::Nnode(tree), n_rows = 5)
  ))
  expect_true(all(names(build_viz_call(posterior)) %in% formals_names))
  expect_true(build_viz_call(posterior)$build.tree)

  # User mode
  phy <- load_example_phy()
  internal <- (ape::Ntip(phy) + 1):(ape::Ntip(phy) + ape::Nnode(phy))
  ages <- stats::setNames(lapply(internal, function(i) rep(1, 5)), as.character(internal))
  user <- list(
    analysis_type = "User", source_kind = "user", phy = phy, chain = NULL,
    node_ages = ages, directory.files = NULL, data_ready = TRUE,
    params = viz_defaults(),
    source_report = list(ok = TRUE, n_tip = ape::Ntip(phy), n_node = ape::Nnode(phy))
  )
  args_user <- build_viz_call(user)
  expect_true(all(names(args_user) %in% formals_names))
  expect_identical(args_user$phy, phy)
  expect_identical(args_user$node.ages, ages)

  # MrBayes and RevBayes use directory.files
  for (type in c("MrBayes", "RevBayes")) {
    mb <- list(
      analysis_type = type, source_kind = tolower(type), phy = NULL, chain = NULL,
      node_ages = NULL, directory.files = "example.con.tre", data_ready = TRUE,
      params = viz_defaults(),
      source_report = list(ok = TRUE, n_tip = 10, n_node = 9, n_runs = 2)
    )
    args_mb <- build_viz_call(mb)
    expect_true(all(names(args_mb) %in% formals_names))
    expect_identical(args_mb$directory.files, "example.con.tre")
    expect_null(args_mb$phy)
  }
})

test_that("distributions supply a placeholder chain where upstream needs one", {
  phy <- load_example_phy()
  internal <- (ape::Ntip(phy) + 1):(ape::Ntip(phy) + ape::Nnode(phy))
  ages <- stats::setNames(lapply(internal, function(i) rep(1, 5)), as.character(internal))
  user <- list(
    analysis_type = "User", source_kind = "user", phy = phy, chain = NULL,
    node_ages = ages, directory.files = NULL, data_ready = TRUE,
    params = modifyList(viz_defaults(), list(plot_type = "distributions")),
    source_report = list(ok = TRUE, n_tip = ape::Ntip(phy), n_node = ape::Nnode(phy))
  )
  args <- build_viz_call(user)
  expect_false(is.null(args$MCMC.chain))
})

test_that("unsupported plot combinations fail with actionable errors", {
  b <- make_figtree_b()
  b$params$plot_type <- "distributions"
  expect_app_error(build_viz_call(b), "err_missing_chain")

  user <- list(
    analysis_type = "User", source_kind = "user", phy = load_example_phy(),
    chain = NULL, node_ages = list(), directory.files = NULL, data_ready = TRUE,
    params = modifyList(viz_defaults(), list(plot_type = "cladogram")),
    source_report = list(ok = TRUE, n_tip = 7, n_node = 6)
  )
  expect_app_error(build_viz_call(user), "err_cladogram_mcmctree")

  mb <- list(
    analysis_type = "MrBayes", source_kind = "mrbayes", phy = NULL, chain = NULL,
    node_ages = NULL, directory.files = "x.con.tre", data_ready = TRUE,
    params = modifyList(viz_defaults(), list(n_runs = 3)),
    source_report = list(ok = TRUE, n_tip = 10, n_node = 9, n_runs = 1)
  )
  expect_app_error(build_viz_call(mb), "err_mrbayes_runs")
})

test_that("parameter validation catches invalid values", {
  params <- viz_defaults()
  params$plot_type <- "not-a-plot"
  params$node_method <- "not-a-method"
  params$scale_res <- character()
  params$cex_tips <- -1
  params$col_tree <- "not-a-colour"
  params$all_nodes_raw <- "8, 1, 999"
  issues <- viz_param_issues(params, load_example_phy())$issues
  keys <- vapply(issues, `[[`, character(1), "key")
  expect_true("err_plot_type" %in% keys)
  expect_true("err_node_method" %in% keys)
  expect_true("err_scale_res" %in% keys)
  expect_true("err_numeric_param" %in% keys)
  expect_true("err_color_invalid" %in% keys)
  expect_true("err_all_nodes" %in% keys)
})

test_that("all node parsing accepts internal nodes and rejects tips", {
  phy <- load_example_phy()
  expect_identical(parse_all_nodes_param("8,10", phy)$values, c(8L, 10L))
  expect_null(parse_all_nodes_param("", phy)$values)
  expect_true(length(parse_all_nodes_param("1", phy)$tip_nodes) == 1)
})

test_that("collect_viz_params maps inputs and keeps defaults", {
  params <- collect_viz_params(
    list(
      plot_type = "distributions",
      node_method = "none",
      scale_res = c("Eon", "Period"),
      all_nodes_raw = "8, 10",
      abs_age_mgp = "3, 0.35, 0",
      pos_age_auto = TRUE,
      add_time_scale = FALSE,
      cex_tips = 0.4
    ),
    viz_defaults()
  )
  expect_identical(params$plot_type, "distributions")
  expect_identical(params$node_method, "none")
  expect_identical(params$scale_res, c("Eon", "Period"))
  expect_identical(params$all_nodes_raw, "8, 10")
  expect_identical(params$abs_age_mgp, c(3, 0.35, 0))
  expect_null(params$pos_age)
  expect_false(params$add_time_scale)
  expect_identical(params$cex_tips, 0.4)

  invalid <- collect_viz_params(list(abs_age_mgp = "3, nope, 0"), viz_defaults())
  expect_null(invalid$abs_age_mgp)
  expect_identical(invalid$abs_age_mgp_raw, "3, nope, 0")
})

test_that("UI-only parameters are removed from the plot state", {
  params <- viz_defaults()
  cleaned <- viz_state_params(params)
  expect_false("all_nodes_raw" %in% names(cleaned))
  expect_false("pos_age_auto" %in% names(cleaned))
  expect_false("abs_age_mgp_raw" %in% names(cleaned))
  expect_false("plot_height_in" %in% names(cleaned))
  expect_true("plot_type" %in% names(cleaned))
})
