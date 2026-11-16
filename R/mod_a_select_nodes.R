# Step 2: select calibration nodes by clicking the tree or using the list.

step2_ui <- function(ns, i18n, a) {
  if (is.null(a$phy)) {
    return(htmltools::tagList(
      htmltools::tags$div(
        class = "step-block",
        htmltools::tags$div(class = "alert alert-info app-alert", i18n$tr("a_need_tree"))
      )
    ))
  }

  choices <- calibration_node_choices(a$phy)

  htmltools::tagList(
    htmltools::tags$div(
      class = "step-block",
      htmltools::tags$div(
        class = "node-picker",
        shiny::selectInput(
          inputId = ns("manual_node"),
          label = i18n$tr("manual_node_label"),
          choices = choices,
          selected = NULL,
          width = "100%",
          selectize = FALSE
        ),
        shiny::actionButton(
          inputId = ns("add_node"),
          label = i18n$tr("btn_add_node"),
          class = "btn-outline-secondary"
        )
      ),
      # The preview already accepts a click on any internal node; without this
      # line the crosshair was the only clue.
      htmltools::tags$p(class = "form-hint", i18n$tr("step2_click_hint")),
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
  if (!length(node)) {
    user_notification(i18n$tr("err_no_node_selected"), type = "warning")
    return(invisible(FALSE))
  }
  if (is.na(node[1])) {
    user_notification(i18n$tr("err_invalid_node", node[1]), type = "error")
    return(invisible(FALSE))
  }
  node <- node[1]
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
  if (!length(node) || is.na(node[1])) {
    user_notification(i18n$tr("err_no_node_selected"), type = "warning")
    return(invisible(FALSE))
  }
  node <- node[1]
  if (!node %in% as.integer(a$selected)) {
    user_notification(i18n$tr("err_no_node_selected"), type = "warning")
    return(invisible(FALSE))
  }
  a$calibrated <- remove_calibration(a$calibrated, node)
  a$selected <- setdiff(as.integer(a$selected), node)
  a$results <- NULL
  a$results_input <- NULL
  set_a(a)
  bump()
  user_notification(i18n$tr("msg_node_removed", node), type = "message")
  invisible(TRUE)
}

a_select_nodes_server <- function(input, output, session, ns, state, set_a,
                                 bump, i18n) {
  shiny::observeEvent(input$add_node, {
    if (!is_button_click(input$add_node)) return()
    a_add_node(state, set_a, bump, i18n, input$manual_node)
  })

  # One remove control inside each row: the delete decision lives where the
  # node is listed, instead of a second dropdown that re-asks what to delete.
  created <- shiny::reactiveVal(character())
  shiny::observe({
    calibrated <- state$a$calibrated
    ids <- vapply(
      calibrated,
      function(one) paste0("remove_node_", as.integer(one$node)),
      character(1)
    )
    pending <- setdiff(ids, created())
    for (id in pending) {
      local({
        id_local <- id
        node_local <- as.integer(sub("remove_node_", "", id_local))
        shiny::observeEvent(input[[id_local]], {
          if (!is_button_click(input[[id_local]])) return()
          a_remove_node(state, set_a, bump, i18n, node_local)
        })
      })
    }
    if (length(pending)) created(c(created(), pending))
  })

  output$node_tips <- shiny::renderUI({
    i18n$lang()
    calibrated <- state$a$calibrated
    htmltools::tags$div(
      class = "node-tip-list",
      htmltools::tags$h3(i18n$tr("selected_nodes_title")),
      if (!length(calibrated)) {
        htmltools::tags$p(class = "form-hint", i18n$tr("selected_nodes_none"))
      } else {
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
            htmltools::tags$div(
              class = "node-tip-head",
              htmltools::tags$strong(i18n$tr("selected_node_row", one$node)),
              htmltools::tags$span(
                class = "node-tip-count",
                i18n$tr("selected_tips_count", length(tips))
              )
            ),
            htmltools::tags$p(class = "node-tip-text", text),
            shiny::actionButton(
              inputId = ns(paste0("remove_node_", as.integer(one$node))),
              label = i18n$tr("remove"),
              class = "btn-outline-secondary btn-sm node-remove"
            )
          )
        })
      }
    )
  })
}
