# Step 2: select calibration nodes by clicking the tree or using the list.

step2_ui <- function(ns, i18n, a) {
  if (is.null(a$phy)) {
    return(htmltools::tagList(
      htmltools::tags$div(
        class = "step-block",
        htmltools::tags$h4(i18n$tr("step2_title")),
        htmltools::tags$p(class = "step-hint", i18n$tr("step2_hint")),
        htmltools::tags$div(class = "alert alert-info app-alert", i18n$tr("a_need_tree"))
      )
    ))
  }

  choices <- calibration_node_choices(a$phy)
  selected_choices <- if (length(a$selected)) {
    stats::setNames(as.character(a$selected), paste0("Node ", a$selected))
  } else {
    character()
  }

  htmltools::tagList(
    htmltools::tags$div(
      class = "step-block",
      htmltools::tags$h4(i18n$tr("step2_title")),
      htmltools::tags$p(class = "step-hint", i18n$tr("step2_hint")),
      bslib::layout_columns(
        col_widths = c(6, 6),
        htmltools::tags$div(
          shiny::selectInput(
            inputId = ns("manual_node"),
            label = i18n$tr("manual_node_label"),
            choices = choices,
            selected = NULL,
            width = "100%"
          ),
          shiny::actionButton(
            inputId = ns("add_node"),
            label = i18n$tr("btn_add_node"),
            class = "btn-outline-primary btn-sm"
          ),
          htmltools::tags$p(class = "form-hint", i18n$tr("manual_node_hint"))
        ),
        htmltools::tags$div(
          shiny::selectInput(
            inputId = ns("remove_node_sel"),
            label = i18n$tr("selected_nodes_title"),
            choices = selected_choices,
            selected = NULL,
            width = "100%"
          ),
          shiny::actionButton(
            inputId = ns("remove_node"),
            label = i18n$tr("btn_remove_node"),
            class = "btn-outline-danger btn-sm"
          )
        )
      ),
      shiny::uiOutput(ns("node_tips"))
    )
  )
}

a_add_node <- function(state, set_a, bump, i18n, node) {
  a <- state$a
  if (is.null(a$phy)) {
    user_notification(i18n$tr("err_no_tree"), type = "warning")
    return(invisible(FALSE))
  }
  node <- suppressWarnings(as.integer(node))
  if (!is.finite(node) || is.na(node)) {
    user_notification(i18n$tr("err_invalid_node", node), type = "error")
    return(invisible(FALSE))
  }
  if (node %in% as.integer(a$selected)) return(invisible(FALSE))
  if (!node_is_internal(a$phy, node)) {
    key <- if (node >= 1 && node <= ape::Ntip(a$phy)) "err_tip_node" else "err_invalid_node"
    user_notification(i18n$tr(key, node), type = "error")
    return(invisible(FALSE))
  }

  tips <- tryCatch(tip_des_safe(a$phy, node), error = function(e) {
    user_notification(error_text(format_error(e, i18n)), type = "error")
    NULL
  })
  if (is.null(tips)) return(invisible(FALSE))

  a$calibrated <- add_calibration(a$calibrated, node, tips)
  a$selected <- sort(unique(c(as.integer(a$selected), node)))
  set_a(a)
  bump()
  user_notification(i18n$tr("msg_node_added", node), type = "message")
  invisible(TRUE)
}

a_remove_node <- function(state, set_a, bump, i18n, node) {
  a <- state$a
  node <- suppressWarnings(as.integer(node))
  if (is.na(node)) return(invisible(FALSE))
  if (!node %in% as.integer(a$selected)) return(invisible(FALSE))
  a$calibrated <- remove_calibration(a$calibrated, node)
  a$selected <- setdiff(as.integer(a$selected), node)
  a$results <- NULL
  a$results_input <- NULL
  set_a(a)
  bump()
  user_notification(i18n$tr("msg_node_removed", node), type = "message")
  invisible(TRUE)
}

mod_a_select_nodes_server <- function(input, output, session, ns, state, set_a,
                                      bump, i18n) {
  shiny::observeEvent(input$add_node, {
    if (!is_button_click(input$add_node)) return()
    a_add_node(state, set_a, bump, i18n, input$manual_node)
  })

  shiny::observeEvent(input$remove_node, {
    if (!is_button_click(input$remove_node)) return()
    a_remove_node(state, set_a, bump, i18n, input$remove_node_sel)
  })

  output$node_tips <- shiny::renderUI({
    calibrated <- state$a$calibrated
    if (!length(calibrated)) {
      return(htmltools::tags$p(class = "form-hint", i18n$tr("selected_nodes_none")))
    }
    htmltools::tags$div(
      class = "node-tip-list",
      htmltools::tags$h5(i18n$tr("node_tips_title")),
      lapply(calibrated, function(one) {
        tips <- as.character(one$tips)
        shown <- tips
        extra <- 0L
        if (length(tips) > 40) {
          shown <- tips[1:40]
          extra <- length(tips) - 40L
        }
        text <- paste(shown, collapse = ", ")
        if (extra > 0) text <- paste0(text, " ... +", extra)
        htmltools::tags$div(
          class = "node-tip-card",
          htmltools::tags$strong(i18n$tr("selected_node_row", one$node)),
          htmltools::tags$span(
            class = "node-tip-count",
            paste0(" (", i18n$tr("selected_tips_count", length(tips)), ")")
          ),
          htmltools::tags$p(class = "node-tip-text", text)
        )
      })
    )
  })
}
