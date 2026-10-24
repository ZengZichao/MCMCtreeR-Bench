# Module B data-source panel and parser.

b_data_source_panel_ui <- function(ns, i18n, b) {
  analysis <- b$analysis_type %||% "MCMCtree"
  source_mode <- b$source_mode %||% "figtree"
  htmltools::tagList(
    shiny::selectInput(
      inputId = ns("analysis_type"),
      label = i18n$tr("b_analysis_type"),
      choices = stats::setNames(
        c("MCMCtree", "MrBayes", "RevBayes", "User"),
        c(
          i18n$tr("b_analysis_mcmctree"), i18n$tr("b_analysis_mrbayes"),
          i18n$tr("b_analysis_revbayes"), i18n$tr("b_analysis_user")
        )
      ),
      selected = analysis,
      width = "100%"
    ),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] === 'MCMCtree'", ns("analysis_type")),
      shiny::radioButtons(
        inputId = ns("source_mode"),
        label = i18n$tr("b_source_mode"),
        choiceNames = list(
          i18n$tr("b_source_figtree"),
          i18n$tr("b_source_posterior")
        ),
        choiceValues = list("figtree", "posterior"),
        selected = source_mode,
        inline = TRUE
      ),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] === 'figtree'", ns("source_mode")),
        shiny::fileInput(
          inputId = ns("figtree_file"),
          label = i18n$tr("b_figtree_file"),
          accept = c(".tre", ".txt"),
          buttonLabel = i18n$tr("browse"),
          placeholder = i18n$tr("upload_none"),
          width = "100%"
        ),
        htmltools::tags$p(class = "form-hint", i18n$tr("b_figtree_hint"))
      ),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] === 'posterior'", ns("source_mode")),
        shiny::fileInput(
          inputId = ns("b_tree_file"),
          label = i18n$tr("b_tree_file"),
          accept = c(".tre", ".nwk", ".newick", ".nexus", ".nex", ".txt"),
          buttonLabel = i18n$tr("browse"),
          placeholder = i18n$tr("upload_none"),
          width = "100%"
        ),
        shiny::fileInput(
          inputId = ns("b_chain_file"),
          label = i18n$tr("b_chain_file"),
          accept = c(".tsv", ".txt", ".csv"),
          buttonLabel = i18n$tr("browse"),
          placeholder = i18n$tr("upload_none"),
          width = "100%"
        ),
        htmltools::tags$p(class = "form-hint", i18n$tr("b_chain_hint")),
        htmltools::tags$p(class = "form-hint", i18n$tr("b_build_tree_hint"))
      )
    ),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] === 'MrBayes'", ns("analysis_type")),
      shiny::fileInput(
        inputId = ns("mrbayes_files"),
        label = i18n$tr("b_mrbayes_files"),
        accept = c(".con.tre", ".run1.t", ".run2.t", ".run3.t", ".run4.t"),
        multiple = TRUE,
        buttonLabel = i18n$tr("browse"),
        placeholder = i18n$tr("upload_none"),
        width = "100%"
      ),
      htmltools::tags$p(class = "form-hint", i18n$tr("b_mrbayes_hint"))
    ),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] === 'RevBayes'", ns("analysis_type")),
      shiny::fileInput(
        inputId = ns("revbayes_files"),
        label = i18n$tr("b_revbayes_files"),
        accept = c(".nex", ".nexus", ".trees"),
        multiple = TRUE,
        buttonLabel = i18n$tr("browse"),
        placeholder = i18n$tr("upload_none"),
        width = "100%"
      ),
      htmltools::tags$p(class = "form-hint", i18n$tr("b_revbayes_hint"))
    ),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] === 'User'", ns("analysis_type")),
      shiny::fileInput(
        inputId = ns("user_tree"),
        label = i18n$tr("b_user_tree"),
        accept = c(".tre", ".nwk", ".newick", ".nexus", ".nex", ".txt"),
        buttonLabel = i18n$tr("browse"),
        placeholder = i18n$tr("upload_none"),
        width = "100%"
      ),
      shiny::fileInput(
        inputId = ns("user_nodeages"),
        label = i18n$tr("b_user_nodeages"),
        accept = c(".tsv", ".csv", ".txt"),
        buttonLabel = i18n$tr("browse"),
        placeholder = i18n$tr("upload_none"),
        width = "100%"
      ),
      htmltools::tags$p(class = "form-hint", i18n$tr("b_user_nodeages_hint"))
    ),
    shiny::actionButton(
      inputId = ns("parse_source"),
      label = i18n$tr("b_parse_source"),
      class = "btn-primary"
    ),
    shiny::uiOutput(ns("source_status"))
  )
}

parse_chain_file <- function(path) {
  chain <- tryCatch(
    data.table::fread(path, data.table = FALSE, check.names = FALSE),
    error = function(e) NULL
  )
  if (is.null(chain) || nrow(chain) == 0) stop(app_error("err_chain_no_tn"))
  limits <- check_posterior_limits(chain)
  if (!isTRUE(limits$ok)) {
    stop(do.call(app_error, c(list(limits$key), limits$args)))
  }
  tn <- chain_tn_columns(names(chain))
  if (!length(tn)) stop(app_error("err_chain_no_tn"))
  chain <- chain[, tn, drop = FALSE]
  if (!all(vapply(chain, is.numeric, logical(1)))) {
    stop(app_error("err_chain_no_tn"))
  }
  chain <- as.data.frame(chain)
  size <- check_object_size(chain)
  if (!isTRUE(size$ok)) {
    stop(do.call(app_error, c(list(size$key), size$args)))
  }
  chain
}

parse_tree_for_viz <- function(path) {
  parsed <- read_tree_file(path)
  phy <- parsed$phy
  limits <- check_tree_limits(phy)
  if (!isTRUE(limits$ok)) {
    stop(do.call(app_error, c(list(limits$key), limits$args)))
  }
  report <- validate_tree(phy)
  if (length(report$issues)) {
    issue <- report$issues[[1]]
    stop(do.call(app_error, c(list(issue$key), issue$args)))
  }
  if (!isTRUE(report$has_branch_lengths)) {
    stop(app_error("err_no_branch_lengths"))
  }
  list(phy = phy, report = report, multiple = parsed$multiple)
}

parse_figtree_source <- function(path) {
  obj <- tryCatch(
    MCMCtreeR::readMCMCtree(path, from.file = TRUE),
    error = function(e) NULL
  )
  if (is.null(obj) || !inherits(obj, "MCMCtreer")) {
    stop(app_error("err_parse_tree"))
  }
  phy <- obj$apePhy
  limits <- check_tree_limits(phy)
  if (!isTRUE(limits$ok)) {
    stop(do.call(app_error, c(list(limits$key), limits$args)))
  }
  report <- validate_tree(phy)
  if (!isTRUE(report$has_branch_lengths)) {
    stop(app_error("err_no_branch_lengths"))
  }
  list(object = obj, phy = phy, report = report)
}

parse_mrbayes_source <- function(staged, workspace) {
  names <- staged$name
  con <- require_literal_suffix(names, ".con.tre")
  if (length(con) != 1) stop(app_error("err_mrbayes_con"))
  runs <- names[grepl("\\.run[0-9]+\\.t$", tolower(names))]
  if (!length(runs)) stop(app_error("err_mrbayes_runs", ".run1.t"))
  run1 <- names[endsWith(tolower(names), ".run1.t")]
  if (!length(run1)) stop(app_error("err_mrbayes_runs", ".run1.t"))

  con_path <- file.path(workspace, con)
  tree <- tryCatch(ape::read.nexus(con_path), error = function(e) NULL)
  if (is.null(tree)) stop(app_error("err_parse_tree"))
  if (inherits(tree, "multiPhylo")) {
    if (!length(tree)) stop(app_error("err_parse_tree"))
    tree <- tree[[1]]
  }
  limits <- check_tree_limits(tree)
  if (!isTRUE(limits$ok)) {
    stop(do.call(app_error, c(list(limits$key), limits$args)))
  }
  list(
    directory.files = con_path,
    phy = tree,
    n_runs = length(runs),
    files = names
  )
}

parse_revbayes_source <- function(staged, workspace) {
  names <- staged$name
  nexus <- names[tolower(tools::file_ext(names)) %in% c("nex", "nexus")]
  if (length(nexus) != 1) stop(app_error("err_revbayes_nexus"))
  trees <- names[endsWith(tolower(names), ".trees")]
  if (!length(trees)) stop(app_error("err_revbayes_trees"))

  nexus_path <- file.path(workspace, nexus)
  tree <- tryCatch(ape::read.nexus(nexus_path), error = function(e) NULL)
  if (is.null(tree)) stop(app_error("err_parse_tree"))
  if (inherits(tree, "multiPhylo")) {
    if (!length(tree)) stop(app_error("err_parse_tree"))
    tree <- tree[[1]]
  }
  limits <- check_tree_limits(tree)
  if (!isTRUE(limits$ok)) {
    stop(do.call(app_error, c(list(limits$key), limits$args)))
  }
  list(
    directory.files = nexus_path,
    phy = tree,
    n_runs = length(trees),
    files = names
  )
}

b_clear_source <- function(b) {
  b$phy <- NULL
  b$chain <- NULL
  b$node_ages <- NULL
  b$directory.files <- NULL
  b$source_report <- NULL
  b$source_kind <- NULL
  b$data_ready <- FALSE
  b$plot_error <- NULL
  b
}

mod_b_data_source_server <- function(input, output, session, ns, state, set_b,
                                     i18n) {
  workspace <- session_workspace(session, "b")

  shiny::observeEvent(input$analysis_type, {
    value <- input$analysis_type
    if (is.null(value) || !value %in% viz_analysis_types()) return()
    b <- state$b
    if (identical(b$analysis_type, value)) return()
    b <- b_clear_source(b)
    b$analysis_type <- value
    b$source_mode <- if (identical(value, "MCMCtree")) "figtree" else NULL
    set_b(b)
  })

  shiny::observeEvent(input$source_mode, {
    value <- input$source_mode
    if (is.null(value) || !value %in% c("figtree", "posterior")) return()
    b <- state$b
    if (identical(b$source_mode, value)) return()
    b <- b_clear_source(b)
    b$source_mode <- value
    set_b(b)
  })

  shiny::observeEvent(input$parse_source, {
    if (!is_button_click(input$parse_source)) return()
    b <- state$b
    analysis <- input$analysis_type %||% "MCMCtree"
    source_mode <- input$source_mode %||% "figtree"

    outcome <- tryCatch({
      if (identical(analysis, "MCMCtree") && identical(source_mode, "figtree")) {
        file <- input$figtree_file
        if (is.null(file) || nrow(file) == 0) stop(app_error("err_file_empty"))
        check <- check_upload_files(file)
        if (!isTRUE(check$ok)) {
          stop(do.call(app_error, c(list(check$key), check$args)))
        }
        staged <- stage_uploaded_files(file, workspace, allowed = c(".tre", ".txt"))
        parsed <- parse_figtree_source(staged$path[1])
        list(kind = "figtree", parsed = parsed, n_rows = NA_integer_, n_runs = NA_integer_)
      } else if (identical(analysis, "MCMCtree")) {
        tree_file <- input$b_tree_file
        chain_file <- input$b_chain_file
        if (is.null(tree_file) || nrow(tree_file) == 0) stop(app_error("err_file_empty"))
        if (is.null(chain_file) || nrow(chain_file) == 0) stop(app_error("err_chain_missing"))
        check <- check_upload_files(rbind(tree_file, chain_file))
        if (!isTRUE(check$ok)) {
          stop(do.call(app_error, c(list(check$key), check$args)))
        }
        staged_tree <- stage_uploaded_files(
          tree_file, workspace,
          allowed = c(".tre", ".nwk", ".newick", ".nexus", ".nex", ".txt")
        )
        staged_chain <- stage_uploaded_files(
          chain_file, workspace, allowed = c(".tsv", ".txt", ".csv")
        )
        tree_parsed <- parse_tree_for_viz(staged_tree$path[1])
        chain <- parse_chain_file(staged_chain$path[1])
        list(
          kind = "posterior", phy = tree_parsed$phy, chain = chain,
          report = tree_parsed$report, n_rows = nrow(chain), n_runs = NA_integer_
        )
      } else if (identical(analysis, "MrBayes")) {
        files <- input$mrbayes_files
        if (is.null(files) || nrow(files) == 0) stop(app_error("err_file_empty"))
        check <- check_upload_files(files)
        if (!isTRUE(check$ok)) {
          stop(do.call(app_error, c(list(check$key), check$args)))
        }
        staged <- stage_uploaded_files(
          files, workspace,
          allowed = c(".con.tre", ".run1.t", ".run2.t", ".run3.t", ".run4.t")
        )
        parsed <- parse_mrbayes_source(staged, workspace)
        list(
          kind = "mrbayes", parsed = parsed,
          n_rows = NA_integer_, n_runs = parsed$n_runs
        )
      } else if (identical(analysis, "RevBayes")) {
        files <- input$revbayes_files
        if (is.null(files) || nrow(files) == 0) stop(app_error("err_file_empty"))
        check <- check_upload_files(files)
        if (!isTRUE(check$ok)) {
          stop(do.call(app_error, c(list(check$key), check$args)))
        }
        staged <- stage_uploaded_files(
          files, workspace, allowed = c(".nex", ".nexus", ".trees")
        )
        parsed <- parse_revbayes_source(staged, workspace)
        list(
          kind = "revbayes", parsed = parsed,
          n_rows = NA_integer_, n_runs = parsed$n_runs
        )
      } else {
        tree_file <- input$user_tree
        ages_file <- input$user_nodeages
        if (is.null(tree_file) || nrow(tree_file) == 0) stop(app_error("err_file_empty"))
        if (is.null(ages_file) || nrow(ages_file) == 0) stop(app_error("err_nodeages_format"))
        check <- check_upload_files(rbind(tree_file, ages_file))
        if (!isTRUE(check$ok)) {
          stop(do.call(app_error, c(list(check$key), check$args)))
        }
        staged_tree <- stage_uploaded_files(
          tree_file, workspace,
          allowed = c(".tre", ".nwk", ".newick", ".nexus", ".nex", ".txt")
        )
        staged_ages <- stage_uploaded_files(
          ages_file, workspace, allowed = c(".tsv", ".csv", ".txt")
        )
        tree_parsed <- parse_tree_for_viz(staged_tree$path[1])
        ages <- parse_node_ages_table(staged_ages$path[1], tree_parsed$phy)
        list(
          kind = "user", phy = tree_parsed$phy, node_ages = ages$node_ages,
          report = tree_parsed$report, n_rows = NA_integer_,
          n_nodes = ages$n_nodes, n_runs = NA_integer_
        )
      }
    }, error = function(e) e)

    if (inherits(outcome, "error")) {
      fmt <- format_error(outcome, i18n, fallback = "err_parse_tree")
      b <- b_clear_source(b)
      b$analysis_type <- analysis
      b$source_report <- list(ok = FALSE, error = fmt)
      set_b(b)
      user_notification(error_text(fmt), type = "error", duration = 9)
      return()
    }

    b <- b_clear_source(b)
    b$analysis_type <- analysis
    b$source_mode <- if (identical(analysis, "MCMCtree")) source_mode else NULL
    b$workspace <- workspace
    b$source_kind <- outcome$kind
    b$source_key <- (b$source_key %||% 0L) + 1L
    b$loaded_at <- as.character(Sys.time())

    report <- list(
      ok = TRUE,
      kind = outcome$kind,
      n_rows = outcome$n_rows,
      n_nodes = outcome$n_nodes %||% NA_integer_,
      n_runs = outcome$n_runs
    )

    if (identical(outcome$kind, "figtree")) {
      b$phy <- outcome$parsed$object
      report$n_tip <- outcome$parsed$report$n_tip
      report$n_node <- outcome$parsed$report$n_node
      b$params$build_tree <- FALSE
    } else if (identical(outcome$kind, "posterior")) {
      b$phy <- outcome$phy
      b$chain <- outcome$chain
      report$n_tip <- outcome$report$n_tip
      report$n_node <- outcome$report$n_node
      build_value <- input$build_tree %||% TRUE
      b$params$build_tree <- isTRUE(build_value)
    } else if (identical(outcome$kind, "mrbayes")) {
      b$directory.files <- outcome$parsed$directory.files
      b$phy <- NULL
      report$n_tip <- ape::Ntip(outcome$parsed$phy)
      report$n_node <- ape::Nnode(outcome$parsed$phy)
      b$params$n_runs <- as.integer(outcome$n_runs)
      report$files <- outcome$parsed$files
    } else if (identical(outcome$kind, "revbayes")) {
      b$directory.files <- outcome$parsed$directory.files
      b$phy <- NULL
      report$n_tip <- ape::Ntip(outcome$parsed$phy)
      report$n_node <- ape::Nnode(outcome$parsed$phy)
      b$params$n_runs <- as.integer(outcome$n_runs)
      report$files <- outcome$parsed$files
    } else {
      b$phy <- outcome$phy
      b$node_ages <- outcome$node_ages
      report$n_tip <- outcome$report$n_tip
      report$n_node <- outcome$report$n_node
      b$params$build_tree <- FALSE
    }

    b$source_report <- report
    b$data_ready <- TRUE
    b$plot_error <- NULL
    if (!is.na(report$n_rows) && report$n_rows > LIMITS$manual_redraw_rows) {
      b$auto_redraw <- FALSE
    }
    set_b(b)
    shiny::updateCheckboxInput(session, "build_tree", value = isTRUE(b$params$build_tree))
    shiny::updateNumericInput(session, "n_runs", value = b$params$n_runs)
    shiny::updateCheckboxInput(session, "auto_redraw", value = isTRUE(b$auto_redraw))

    user_notification(i18n$tr("msg_source_ready"), type = "message")
    if (!is.na(report$n_rows) && report$n_rows > LIMITS$manual_redraw_rows) {
      user_notification(i18n$tr("warn_plot_slow"), type = "warning", duration = 8)
    }
    gc()
  })

  output$source_status <- shiny::renderUI({
    report <- state$b$source_report
    if (is.null(report)) {
      return(htmltools::tags$p(class = "form-hint", i18n$tr("b_source_not_ready")))
    }
    if (!isTRUE(report$ok)) {
      fmt <- report$error %||% list(text = i18n$tr("err_parse_tree"), detail = NULL)
      return(htmltools::tags$div(
        class = "alert alert-danger app-alert", role = "alert",
        htmltools::tags$strong(i18n$tr("b_source_status")),
        htmltools::tags$p(error_text(fmt)),
        if (!is.null(fmt$detail)) htmltools::tags$pre(class = "code-block", fmt$detail)
      ))
    }

    kind_label <- switch(
      report$kind,
      figtree = i18n$tr("b_source_figtree"),
      posterior = i18n$tr("b_source_posterior"),
      mrbayes = i18n$tr("b_analysis_mrbayes"),
      revbayes = i18n$tr("b_analysis_revbayes"),
      user = i18n$tr("b_analysis_user"),
      report$kind
    )

    items <- list(
      htmltools::tags$li(i18n$tr("b_source_summary", report$n_tip, report$n_node))
    )
    if (!is.null(report$n_rows) && !is.na(report$n_rows)) {
      items <- c(items, list(htmltools::tags$li(i18n$tr("b_source_rows", report$n_rows))))
    }
    if (!is.null(report$n_nodes) && !is.na(report$n_nodes)) {
      items <- c(items, list(htmltools::tags$li(i18n$tr("b_source_nodes", report$n_nodes))))
    }
    if (!is.null(report$n_runs) && !is.na(report$n_runs)) {
      items <- c(items, list(htmltools::tags$li(i18n$tr("b_source_runs", report$n_runs))))
    }

    htmltools::tags$div(
      class = "alert alert-success app-alert", role = "status",
      htmltools::tags$strong(i18n$tr("msg_source_ready")),
      htmltools::tags$p(kind_label),
      htmltools::tags$ul(items)
    )
  })
}
