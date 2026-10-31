# Step 1: load a tree from a file, a Newick string, or the bundled example.

step1_ui <- function(ns, i18n, a) {
  load_mode <- a$load_mode %||% "file"
  htmltools::tagList(
    htmltools::tags$div(
      class = "step-block",
      htmltools::tags$h2(class = "step-title", i18n$tr("step1_title")),
      htmltools::tags$p(class = "step-hint", i18n$tr("step1_hint")),
      shiny::radioButtons(
        inputId = ns("load_mode"),
        label = i18n$tr("load_mode_label"),
        choiceNames = list(
          i18n$tr("load_mode_file"),
          i18n$tr("load_mode_paste"),
          i18n$tr("load_mode_example")
        ),
        choiceValues = list("file", "paste", "example"),
        selected = load_mode,
        inline = TRUE
      ),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] === 'file'", ns("load_mode")),
        shiny::fileInput(
          inputId = ns("tree_file"),
          label = i18n$tr("tree_file_label"),
          accept = c(".tre", ".nwk", ".newick", ".nexus", ".nex", ".txt"),
          buttonLabel = i18n$tr("browse"),
          placeholder = i18n$tr("upload_none"),
          width = "100%"
        )
      ),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] === 'paste'", ns("load_mode")),
        shiny::textAreaInput(
          inputId = ns("tree_paste"),
          label = i18n$tr("tree_paste_label"),
          value = a$tree_paste_text %||% "",
          rows = 6,
          placeholder = i18n$tr("tree_paste_placeholder"),
          width = "100%"
        )
      ),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] === 'example'", ns("load_mode")),
        htmltools::tags$p(class = "form-hint", i18n$tr("tree_example_hint"))
      ),
      # The action sits directly under its input; the reference hints used to
      # push it two paragraphs away from the field it acts on.
      htmltools::tags$div(
        class = "step-action",
        shiny::actionButton(
          inputId = ns("load_tree"),
          label = i18n$tr("btn_load_tree"),
          class = "btn-primary"
        )
      ),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] === 'file'", ns("load_mode")),
        htmltools::tags$p(
          class = "form-hint",
          i18n$tr("file_upload_hint", ".tre, .nwk, .newick, .nexus, .nex, .txt")
        ),
        htmltools::tags$p(
          class = "form-hint",
          i18n$tr("max_upload_hint", format_mb(LIMITS$max_upload_bytes))
        )
      ),
      shiny::uiOutput(ns("tree_report"))
    )
  )
}

mod_a_load_tree_server <- function(input, output, session, ns, state, set_a,
                                   bump, i18n, workspace) {
  shiny::observeEvent(input$load_mode, {
    if (is.null(input$load_mode)) return()
    a <- state$a
    if (!identical(a$load_mode, input$load_mode)) {
      a$load_mode <- input$load_mode
      set_a(a)
    }
  })

  shiny::observeEvent(input$tree_paste, {
    if (is.null(input$tree_paste)) return()
    a <- state$a
    value <- as.character(input$tree_paste %||% "")[1]
    if (!identical(a$tree_paste_text, value)) {
      a$tree_paste_text <- value
      set_a(a)
    }
  })

  shiny::observeEvent(input$load_tree, {
    if (!is_button_click(input$load_tree)) return()
    a <- state$a
    mode <- input$load_mode %||% "file"
    source_label <- ""
    multiple <- FALSE

    outcome <- tryCatch({
      if (identical(mode, "file")) {
        files <- input$tree_file
        if (is.null(files)) stop(app_error("err_no_file_selected"))
        if (nrow(files) == 0) stop(app_error("err_file_empty"))
        check <- check_upload_files(files)
        if (!isTRUE(check$ok)) {
          stop(do.call(app_error, c(list(check$key), check$args)))
        }
        staged <- stage_uploaded_files(
          files, workspace,
          allowed = c(".tre", ".nwk", ".newick", ".nexus", ".nex", ".txt")
        )
        parsed <- read_tree_file(staged$path[1])
        multiple <- parsed$multiple
        source_label <- paste0(i18n$tr("tree_source_file"), ": ", staged$name[1])
        parsed$phy
      } else if (identical(mode, "paste")) {
        text <- input$tree_paste %||% ""
        parsed <- parse_newick(text)
        multiple <- parsed$multiple
        source_label <- i18n$tr("tree_source_paste")
        parsed$phy
      } else {
        # MCMCtreeR::apeData ships a topology-only tree, which makes the example
        # report "no branch lengths" and its export unreadable by module B. The
        # bundled copy is that same tree with deterministic ultrametric lengths.
        phy <- read_tree_file(example_tree_file())$phy
        source_label <- i18n$tr("tree_source_example")
        phy
      }
    }, error = function(e) e)

    if (inherits(outcome, "error")) {
      fmt <- format_error(outcome, i18n, fallback = "err_parse_tree")
      a$phy_report <- list(ok = FALSE, error = fmt)
      set_a(a)
      bump()
      user_notification(error_text(fmt), type = "error", duration = 8)
      return()
    }

    phy <- outcome
    limits <- check_tree_limits(phy)
    if (!isTRUE(limits$ok)) {
      fmt <- format_error(
        do.call(app_error, c(list(limits$key), limits$args)),
        i18n
      )
      a$phy_report <- list(ok = FALSE, error = fmt)
      set_a(a)
      bump()
      user_notification(error_text(fmt), type = "error", duration = 8)
      return()
    }

    report <- validate_tree(phy)
    if (length(report$issues)) {
      issue <- report$issues[[1]]
      fmt <- format_error(
        do.call(app_error, c(list(issue$key), issue$args)),
        i18n
      )
      report$ok <- FALSE
      report$error <- fmt
      a$phy_report <- report
      set_a(a)
      bump()
      user_notification(error_text(fmt), type = "error", duration = 8)
      return()
    }

    report$ok <- TRUE
    report$source <- source_label
    report$multiple <- multiple
    report$loaded_at <- as.character(Sys.time())

    a$phy <- phy
    a$phy_source <- source_label
    a$phy_report <- report
    a$calibrated <- list()
    a$selected <- integer()
    a$results <- NULL
    a$results_input <- NULL
    a$results_error <- NULL
    a$step <- 1L
    set_a(a)
    bump()

    notify <- i18n$tr("msg_tree_loaded", report$n_tip, report$n_node)
    user_notification(notify, type = "message")
    gc()
  })

  output$tree_report <- shiny::renderUI({
    report <- state$a$phy_report
    if (is.null(report)) return(NULL)

    if (!isTRUE(report$ok)) {
      fmt <- report$error %||% list(text = i18n$tr("err_parse_tree"), detail = NULL)
      return(htmltools::tags$div(
        class = "alert alert-danger app-alert", role = "alert",
        htmltools::tags$strong(i18n$tr("tree_report_title")),
        htmltools::tags$p(error_text(fmt)),
        if (!is.null(fmt$detail)) htmltools::tags$pre(class = "code-block", fmt$detail)
      ))
    }

    warnings <- character()
    if (isTRUE(report$multiple)) warnings <- c(warnings, i18n$tr("err_multiple_trees_warn"))
    if (!isTRUE(report$has_branch_lengths)) warnings <- c(warnings, i18n$tr("err_no_branch_warn"))
    if (!isTRUE(report$is_binary)) warnings <- c(warnings, i18n$tr("err_not_binary_warn"))

    htmltools::tags$div(
      class = "alert alert-success app-alert", role = "status",
      htmltools::tags$strong(i18n$tr("tree_report_title")),
      htmltools::tags$dl(
        class = "tree-report",
        htmltools::tags$dt(i18n$tr("tree_source_label")),
        htmltools::tags$dd(report$source %||% ""),
        htmltools::tags$dt(i18n$tr("tree_tips")),
        htmltools::tags$dd(as.character(report$n_tip)),
        htmltools::tags$dt(i18n$tr("tree_nodes")),
        htmltools::tags$dd(as.character(report$n_node)),
        htmltools::tags$dt(i18n$tr("tree_branch_lengths")),
        htmltools::tags$dd(if (isTRUE(report$has_branch_lengths)) i18n$tr("yes") else i18n$tr("no")),
        htmltools::tags$dt(i18n$tr("tree_binary")),
        htmltools::tags$dd(if (isTRUE(report$is_binary)) i18n$tr("yes") else i18n$tr("no"))
      ),
      if (length(warnings)) htmltools::tags$ul(
        class = "tree-warnings",
        lapply(warnings, function(x) htmltools::tags$li(x))
      ) else htmltools::tags$p(class = "form-hint", i18n$tr("tree_valid"))
    )
  })
}
