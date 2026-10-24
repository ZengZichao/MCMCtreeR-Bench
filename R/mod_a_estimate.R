# Step 5: run the per-node estimation and show parameters plus prior curves.

parameter_table_html <- function(parameters, i18n) {
  if (is.null(parameters)) return(NULL)
  values <- as.numeric(parameters)
  labels <- colnames(parameters)
  if (is.null(labels) || length(labels) != length(values)) {
    labels <- names(parameters)
  }
  if (is.null(labels) || length(labels) != length(values)) {
    labels <- paste0("p", seq_along(values))
  }
  htmltools::tags$table(
    class = "table table-sm parameter-table",
    htmltools::tags$thead(
      htmltools::tags$tr(
        htmltools::tags$th(i18n$tr("lbl_parameters")),
        htmltools::tags$th("")
      )
    ),
    htmltools::tags$tbody(
      lapply(seq_along(values), function(i) {
        htmltools::tags$tr(
          htmltools::tags$td(labels[i]),
          htmltools::tags$td(format(values[i], trim = TRUE, digits = 8))
        )
      })
    )
  )
}

step5_ui <- function(ns, i18n, a) {
  if (is.null(a$phy)) {
    return(htmltools::tagList(
      htmltools::tags$div(
        class = "step-block",
        htmltools::tags$h4(i18n$tr("step5_title")),
        htmltools::tags$p(class = "step-hint", i18n$tr("step5_hint")),
        htmltools::tags$div(class = "alert alert-info app-alert", i18n$tr("a_need_tree"))
      )
    ))
  }

  htmltools::tagList(
    htmltools::tags$div(
      class = "step-block",
      htmltools::tags$h4(i18n$tr("step5_title")),
      htmltools::tags$p(class = "step-hint", i18n$tr("step5_hint")),
      shiny::uiOutput(ns("estimate_stale")),
      shiny::uiOutput(ns("estimate_error_alert")),
      bslib::input_task_button(
        id = ns("run_estimation"),
        label = i18n$tr("estimate_run"),
        type = "primary"
      ),
      htmltools::tags$p(class = "form-hint", i18n$tr("estimate_gamma_note")),
      shiny::uiOutput(ns("estimate_results"))
    )
  )
}

mod_a_estimate_server <- function(input, output, session, ns, state, set_a,
                                  bump, i18n, ui_prefs, stale, workspace) {
  shiny::observeEvent(input$run_estimation, {
    if (!is_button_click(input$run_estimation)) return()
    a <- state$a
    if (is.null(a$phy)) {
      user_notification(i18n$tr("err_no_tree"), type = "error")
      return()
    }
    issues <- calibration_issues(a$calibrated)
    if (length(issues)) {
      user_notification(issue_text(issues[[1]], i18n), type = "error", duration = 8)
      return()
    }

    outcome <- tryCatch({
      shiny::withProgress(
        message = i18n$tr("estimate_running"),
        value = 0,
        {
          run_estimation(
            a$phy, a$calibrated,
            progress = function(i, n, node) {
              shiny::incProgress(
                1 / max(n, 1),
                detail = i18n$tr("estimate_node", node)
              )
            }
          )
        }
      )
    }, error = function(e) e)

    if (inherits(outcome, "error")) {
      fmt <- format_error(outcome, i18n, fallback = "err_estimation_failed")
      a$results <- NULL
      a$results_input <- NULL
      a$results_error <- fmt
      set_a(a)
      bump()
      user_notification(error_text(fmt), type = "error", duration = 10)
      return()
    }

    a$results <- outcome
    a$results_input <- outcome$input_hash
    a$results_error <- NULL
    a$step <- 5L
    set_a(a)
    bump()
    user_notification(
      i18n$tr("msg_estimate_done", length(outcome$nodes)),
      type = "message"
    )
    gc()
  })

  shiny::observeEvent(state$a$results, {
    results <- state$a$results
    if (is.null(results) || !length(results$nodes)) return()
    for (one in results$nodes) {
      local({
        node <- as.integer(one$node)
        output[[paste0("dist_", node)]] <- shiny::renderPlot({
          current <- state$a$results
          if (is.null(current)) return(NULL)
          idx <- which(vapply(current$nodes, function(x) identical(as.integer(x$node), node), logical(1)))
          if (!length(idx)) return(NULL)
          cols <- plot_colors_for(ui_prefs)
          with_plot_theme(cols, plot_node_distribution(
            current$nodes[[idx]],
            cols = cols,
            cex = 0.9
          ))
        }, bg = "transparent", height = 230)
      })
    }
  }, ignoreNULL = TRUE)

  output$estimate_stale <- shiny::renderUI({
    if (is.null(state$a$results)) return(NULL)
    if (isTRUE(stale())) {
      return(htmltools::tags$div(
        class = "alert alert-warning app-alert", role = "alert",
        i18n$tr("err_stale")
      ))
    }
    NULL
  })

  output$estimate_error_alert <- shiny::renderUI({
    fmt <- state$a$results_error
    if (is.null(fmt)) return(NULL)
    htmltools::tags$div(
      class = "alert alert-danger app-alert", role = "alert",
      htmltools::tags$strong(i18n$tr("estimate_error")),
      htmltools::tags$p(error_text(fmt)),
      if (!is.null(fmt$detail)) htmltools::tags$pre(class = "code-block", fmt$detail)
    )
  })

  output$estimate_results <- shiny::renderUI({
    results <- state$a$results
    if (is.null(results)) {
      return(htmltools::tags$div(
        class = "empty-state",
        htmltools::tags$p(i18n$tr("estimate_no_results"))
      ))
    }

    warnings <- results$warning_class$known %||% character()
    cards <- lapply(results$nodes, function(one) {
      node <- as.integer(one$node)
      htmltools::tags$div(
        class = "result-card",
        htmltools::tags$div(
          class = "result-head",
          htmltools::tags$h5(paste0(
            i18n$tr("estimate_node", node), " \u00b7 ", one$method
          )),
          htmltools::tags$span(
            class = "result-tips",
            i18n$tr("selected_tips_count", length(one$tips))
          )
        ),
        parameter_table_html(one$parameters, i18n),
        shiny::plotOutput(ns(paste0("dist_", node)), height = "230px")
      )
    })

    htmltools::tagList(
      if (length(warnings)) htmltools::tags$div(
        class = "alert alert-info app-alert", role = "status",
        i18n$tr("estimate_known_warnings")
      ),
      htmltools::tags$h5(i18n$tr("estimate_results")),
      cards
    )
  })
}
