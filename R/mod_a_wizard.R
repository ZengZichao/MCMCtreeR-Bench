# Module A assembly: step navigator, persistent tree preview and step content.

mod_a_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    htmltools::tags$div(
      class = "module-a",
      bslib::layout_columns(
        col_widths = c(2, 6, 4),
        htmltools::tags$div(
          class = "step-nav",
          htmltools::tags$h5(shiny::uiOutput(ns("step_nav_title"), inline = TRUE)),
          shiny::uiOutput(ns("step_nav"))
        ),
        htmltools::tags$div(
          class = "step-main",
          shiny::uiOutput(ns("step_content")),
          shiny::uiOutput(ns("step_footer"))
        ),
        htmltools::tags$div(
          class = "a-preview",
          htmltools::tags$h5(shiny::uiOutput(ns("preview_title"), inline = TRUE)),
          shiny::uiOutput(ns("preview_controls")),
          shiny::plotOutput(
            outputId = ns("tree_plot"),
            click = ns("tree_plot_click"),
            height = "440px"
          )
        )
      )
    )
  )
}

step_titles <- function() {
  c(
    "step1_title", "step2_title", "step3_title",
    "step4_title", "step5_title", "step6_title"
  )
}

step_lock_hint <- function(step, a, stale) {
  switch(
    as.character(step),
    "2" = "a_need_tree",
    "3" = "a_need_nodes",
    "4" = "a_need_ages",
    "5" = "a_need_adv",
    "6" = if (!is.null(a$results) && isTRUE(stale)) "err_stale" else "a_need_results",
    NULL
  )
}

mod_a_server <- function(id, state, set_a, ui_prefs) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    i18n <- ui_prefs$i18n
    workspace <- session_workspace(session, "a")
    plot_coords <- shiny::reactiveVal(NULL)
    a_revision <- shiny::reactiveVal(0L)
    bump <- function() a_revision(shiny::isolate(a_revision()) + 1L)

    current_hash <- shiny::reactive({
      a <- state$a
      if (is.null(a$phy)) return(NULL)
      hash_business_inputs(a$phy, a$calibrated, dir = workspace)
    })

    stale <- shiny::reactive({
      a <- state$a
      if (is.null(a$results)) return(TRUE)
      is_stale(a$results_input, current_hash())
    })

    step_enabled <- shiny::reactive({
      a <- state$a
      n <- length(a$calibrated)
      ages_ok <- n > 0 && calibration_valid(a$calibrated, include_adv = FALSE)
      all_ok <- n > 0 && calibration_valid(a$calibrated)
      c(
        "1" = TRUE,
        "2" = !is.null(a$phy),
        "3" = n > 0,
        "4" = ages_ok,
        "5" = all_ok,
        "6" = !is.null(a$results) && !isTRUE(stale())
      )
    })

    go_step <- function(step) {
      enabled <- step_enabled()
      step <- as.integer(step)
      if (!isTRUE(enabled[as.character(step)])) {
        hint_key <- step_lock_hint(step, state$a, stale())
        if (!is.null(hint_key)) {
          user_notification(i18n$tr(hint_key), type = "warning")
        }
        return(invisible(FALSE))
      }
      a <- state$a
      if (!identical(as.integer(a$step), step)) {
        a$step <- step
        set_a(a)
        bump()
      }
      invisible(TRUE)
    }

    for (step in seq_len(6)) {
      local({
        step_local <- step
        shiny::observeEvent(
          input[[paste0("go_step_", step_local)]],
          {
            if (!is_button_click(input[[paste0("go_step_", step_local)]])) return()
            go_step(step_local)
          }
        )
      })
    }
    shiny::observeEvent(input$step_prev, {
      if (!is_button_click(input$step_prev)) return()
      go_step(max(1L, as.integer(state$a$step) - 1L))
    })
    shiny::observeEvent(input$step_next, {
      if (!is_button_click(input$step_next)) return()
      go_step(min(6L, as.integer(state$a$step) + 1L))
    })

    mod_a_load_tree_server(input, output, session, ns, state, set_a, bump, i18n, workspace)
    mod_a_select_nodes_server(input, output, session, ns, state, set_a, bump, i18n)
    mod_a_calibration_table_server(input, output, session, ns, state, set_a, bump, i18n)
    mod_a_advanced_params_server(input, output, session, ns, state, set_a, i18n)
    mod_a_estimate_server(input, output, session, ns, state, set_a, bump, i18n, ui_prefs, stale, workspace)
    mod_a_export_server(input, output, session, ns, state, set_a, bump, i18n, ui_prefs, stale, workspace)

    output$step_nav_title <- shiny::renderUI(i18n$tr("step_nav_title"))
    output$preview_title <- shiny::renderUI(i18n$tr("tree_plot_title"))

    output$preview_controls <- shiny::renderUI({
      i18n$lang()
      a <- shiny::isolate(state$a)
      view <- a$view %||% list(show_node_ids = TRUE, show_tip_labels = TRUE)
      disabled <- is.null(a$phy)
      htmltools::tags$div(
        inert = if (disabled) "" else NULL,
        shiny::checkboxInput(
          inputId = ns("show_node_ids"),
          label = i18n$tr("show_node_ids"),
          value = isTRUE(view$show_node_ids)
        ),
        shiny::checkboxInput(
          inputId = ns("show_tip_labels"),
          label = i18n$tr("show_tip_labels"),
          value = isTRUE(view$show_tip_labels)
        )
      )
    })

    shiny::observeEvent(
      list(input$show_node_ids, input$show_tip_labels),
      {
        if (is.null(input$show_node_ids) && is.null(input$show_tip_labels)) return()
        a <- state$a
        view <- a$view %||% list(show_node_ids = TRUE, show_tip_labels = TRUE)
        view$show_node_ids <- isTRUE(input$show_node_ids %||% view$show_node_ids)
        view$show_tip_labels <- isTRUE(input$show_tip_labels %||% view$show_tip_labels)
        if (!identical(view, a$view)) {
          a$view <- view
          set_a(a)
        }
      },
      ignoreNULL = FALSE
    )

    output$step_nav <- shiny::renderUI({
      enabled <- step_enabled()
      a <- state$a
      titles <- step_titles()
      current <- as.integer(a$step)
      htmltools::tags$div(
        class = "step-list",
        role = "navigation",
        `aria-label` = i18n$tr("aria_step_nav"),
        lapply(seq_len(6), function(step) {
          is_active <- identical(step, current)
          is_enabled <- isTRUE(enabled[as.character(step)])
          hint_key <- if (is_enabled) NULL else step_lock_hint(step, a, stale())
          htmltools::tags$button(
            id = ns(paste0("go_step_", step)),
            type = "button",
            class = paste(
              "btn step-btn action-button",
              if (is_active) "active" else "",
              if (is_enabled) "" else "locked",
              if (step < current && is_enabled) "done" else ""
            ),
            disabled = if (is_enabled) NULL else "disabled",
            `aria-current` = if (is_active) "step" else NULL,
            `aria-disabled` = if (is_enabled) "false" else "true",
            title = if (!is.null(hint_key)) i18n$tr(hint_key) else NULL,
            htmltools::tags$span(class = "step-index", step),
            htmltools::tags$span(class = "step-label", i18n$tr(titles[step]))
          )
        })
      )
    })

    output$step_content <- shiny::renderUI({
      i18n$lang()
      a_revision()
      a <- shiny::isolate(state$a)
      switch(
        as.character(a$step),
        "1" = step1_ui(ns, i18n, a),
        "2" = step2_ui(ns, i18n, a),
        "3" = step3_ui(ns, i18n, a),
        "4" = step4_ui(ns, i18n, a),
        "5" = step5_ui(ns, i18n, a),
        "6" = step6_ui(ns, i18n, a),
        step1_ui(ns, i18n, a)
      )
    })

    output$step_footer <- shiny::renderUI({
      enabled <- step_enabled()
      a <- state$a
      step <- as.integer(a$step)
      prev_enabled <- step > 1
      next_enabled <- step < 6 && isTRUE(enabled[as.character(step + 1)])
      next_hint <- if (step < 6 && !next_enabled) {
        step_lock_hint(step + 1, a, stale())
      } else {
        NULL
      }
      htmltools::tags$div(
        class = "step-footer",
        htmltools::tags$button(
          id = ns("step_prev"),
          type = "button",
          class = "btn btn-outline-secondary action-button",
          disabled = if (prev_enabled) NULL else "disabled",
          i18n$tr("step_prev")
        ),
        htmltools::tags$button(
          id = ns("step_next"),
          type = "button",
          class = "btn btn-primary action-button",
          disabled = if (next_enabled) NULL else "disabled",
          title = if (!is.null(next_hint)) i18n$tr(next_hint) else NULL,
          i18n$tr("step_next")
        )
      )
    })

    output$tree_plot <- shiny::renderPlot({
      phy <- state$a$phy
      selected <- state$a$selected
      view <- state$a$view %||% list(show_node_ids = TRUE, show_tip_labels = TRUE)
      cols <- plot_colors_for(ui_prefs)

      if (is.null(phy)) {
        with_plot_theme(cols, {
          graphics::plot.new()
          graphics::text(
            0.5, 0.5, "Load a tree to begin",
            col = cols$muted, cex = 1.1
          )
        })
        plot_coords(NULL)
        return(invisible(NULL))
      }

      show_ids <- isTRUE(input$show_node_ids %||% view$show_node_ids)
      show_tips <- isTRUE(input$show_tip_labels %||% view$show_tip_labels)
      selected_list <- lapply(as.integer(selected), function(node) list(node = node))
      pp <- with_plot_theme(cols, plot_calibrated_tree(
        phy, selected_list, cols = cols,
        show_tip_label = show_tips,
        show_node_ids = show_ids
      ))
      plot_coords(pp)
      invisible(NULL)
    }, bg = "transparent")

    shiny::observeEvent(input$tree_plot_click, {
      phy <- state$a$phy
      if (is.null(phy)) return()
      pp <- plot_coords()
      if (is.null(pp)) return()
      click <- input$tree_plot_click
      hit <- nearest_phylo_node(pp, click$x, click$y, ape::Ntip(phy), tol = 0.15)
      if (is.null(hit$node)) return()
      if (isTRUE(hit$is_tip)) {
        user_notification(i18n$tr("err_tip_node", hit$node), type = "warning")
        return()
      }
      if (hit$node %in% as.integer(state$a$selected)) {
        a_remove_node(state, set_a, bump, i18n, hit$node)
      } else {
        a_add_node(state, set_a, bump, i18n, hit$node)
      }
    })

    invisible(list(stale = stale, step_enabled = step_enabled))
  })
}
