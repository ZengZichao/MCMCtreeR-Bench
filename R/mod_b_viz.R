# Module B assembly: settings sidebar, live plot and export.

mod_b_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    htmltools::tags$section(
      class = "hero hero--compact",
      htmltools::tags$div(class = "hero-inner", shiny::uiOutput(ns("hero")))
    ),
    htmltools::tags$section(
      class = "workbench",
      id = "b-workbench",
      htmltools::tags$div(
        class = "workbench-inner",
        htmltools::tags$div(
          class = "b-workbench",
          bslib::layout_sidebar(
            sidebar = bslib::sidebar(
              width = 380,
              padding = 0,
              gap = 0,
              class = "b-sidebar",
              htmltools::tags$div(
                class = "b-sidebar-inner",
                shiny::uiOutput(ns("sidebar"))
              )
            ),
            htmltools::tags$div(
              class = "b-stage",
              htmltools::tags$div(
                class = "b-toolbar-wrap",
                shiny::uiOutput(ns("plot_toolbar"))
              ),
              # The status strip sits between the controls and the canvas: it is
              # where a failed load or the empty-state instruction has to land so
              # it is visible without scrolling past a full-height figure.
              htmltools::tags$div(
                class = "b-status-wrap",
                shiny::uiOutput(ns("plot_status"))
              ),
              htmltools::tags$div(
                class = "b-plot-wrap",
                shiny::uiOutput(ns("plot_canvas"))
              )
            ),
            fillable = FALSE,
            border = FALSE,
            padding = 0,
            gap = "20px"
          )
        )
      )
    )
  )
}

b_export_panel_ui <- function(ns, i18n, b) {
  htmltools::tagList(
    export_controls_ui(ns, i18n, b$export, prefix = "export"),
    shiny::uiOutput(ns("export_actions"))
  )
}

mod_b_server <- function(id, state, set_b, ui_prefs) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    i18n <- ui_prefs$i18n
    plot_error <- shiny::reactiveVal(NULL)
    plot_trigger <- shiny::reactiveVal(0L)

    contrib_debounced <- shiny::debounce(
      shiny::reactive(state$b$params),
      millis = LIMITS$debounce_ms
    )

    plot_params <- shiny::reactive({
      auto <- isTRUE(state$b$auto_redraw)
      state$b$data_ready
      state$b$source_key
      if (auto) {
        contrib_debounced()
      } else {
        plot_trigger()
        shiny::isolate(state$b$params)
      }
    })

    shiny::observe({
      b <- state$b
      params <- collect_viz_params(input, b$params)
      if (!identical(params, b$params)) {
        b$params <- params
        set_b(b)
      }
    })

    shiny::observeEvent(input$auto_redraw, {
      if (is.null(input$auto_redraw)) return()
      b <- state$b
      value <- isTRUE(input$auto_redraw)
      if (!identical(b$auto_redraw, value)) {
        b$auto_redraw <- value
        set_b(b)
      }
    })

    shiny::observeEvent(input$redraw, {
      if (!is_button_click(input$redraw)) return()
      plot_trigger(shiny::isolate(plot_trigger()) + 1L)
    })

    shiny::observeEvent(
      list(
        input$export_width, input$export_height,
        input$export_dpi, input$export_format,
        input$export_plot_theme
      ),
      {
        values <- export_values(input, fallback = state$b$export)
        if (!identical(values, state$b$export)) {
          b <- state$b
          b$export <- values
          set_b(b)
        }
      },
      ignoreNULL = FALSE
    )

    mod_b_data_source_server(input, output, session, ns, state, set_b, i18n)

    output$hero <- shiny::renderUI({
      hero_content(
        eyebrow = i18n$tr("app_title"),
        title = i18n$tr("b_hero_title"),
        lead = i18n$tr("b_hero_lead"),
        chips = c("MCMCtree", "MrBayes", "RevBayes", "User")
      )
    })

    output$sidebar <- shiny::renderUI({
      i18n$lang()
      b <- shiny::isolate(state$b)
      panels <- list(
        bslib::accordion_panel(
          i18n$tr("b_data_source_title"),
          b_data_source_panel_ui(ns, i18n, b)
        ),
        bslib::accordion_panel(
          i18n$tr("b_plot_type_title"),
          b_plot_type_panel_ui(ns, i18n, b)
        ),
        bslib::accordion_panel(
          i18n$tr("b_timescale_title"),
          b_timescale_panel_ui(ns, i18n, b)
        ),
        bslib::accordion_panel(
          i18n$tr("b_node_uncert_title"),
          b_node_uncert_panel_ui(ns, i18n, b)
        ),
        bslib::accordion_panel(
          i18n$tr("b_appearance_title"),
          b_appearance_panel_ui(ns, i18n, b)
        )
      )
      # The burn-in / run-count inputs only exist for MrBayes and RevBayes, so
      # offering an "分析设置" panel that expands to nothing is a dead end.
      analysis <- shiny::isolate(input$analysis_type) %||% b$analysis_type
      if (identical(analysis, "MrBayes") || identical(analysis, "RevBayes")) {
        panels <- c(panels, list(bslib::accordion_panel(
          i18n$tr("b_analysis_title"),
          b_analysis_panel_ui(ns, i18n, b)
        )))
      }
      panels <- c(panels, list(bslib::accordion_panel(
        i18n$tr("b_export_title"),
        b_export_panel_ui(ns, i18n, b)
      )))
      do.call(bslib::accordion, c(
        list(class = "b-accordion", open = i18n$tr("b_data_source_title"),
             multiple = TRUE),
        panels
      ))
    })

    output$plot_toolbar <- shiny::renderUI({
      i18n$lang()
      b <- shiny::isolate(state$b)
      htmltools::tags$div(
        class = "b-toolbar",
        shiny::checkboxInput(
          inputId = ns("auto_redraw"),
          label = i18n$tr("b_auto_redraw"),
          value = isTRUE(b$auto_redraw)
        ),
        shiny::conditionalPanel(
          condition = sprintf("input['%s'] === false", ns("auto_redraw")),
          shiny::actionButton(
            inputId = ns("redraw"),
            label = i18n$tr("b_redraw"),
            class = "btn-outline-primary btn-sm"
          )
        ),
        shiny::conditionalPanel(
          condition = sprintf("input['%s'] === true", ns("auto_redraw")),
          htmltools::tags$p(class = "form-hint", i18n$tr("b_redraw_hint"))
        ),
        shiny::conditionalPanel(
          condition = sprintf("input['%s'] === false", ns("auto_redraw")),
          htmltools::tags$p(class = "form-hint", i18n$tr("b_manual_redraw_hint"))
        )
      )
    })

    output$time_tree <- shiny::renderPlot({
      params <- plot_params()
      b <- shiny::isolate(state$b)
      b$params <- params
      cols <- plot_colors_for(ui_prefs)

      if (!isTRUE(b$data_ready)) {
        # A placeholder is drawn over the interface's own surface, so it must
        # not bring a sheet of paper with it: an opaque background here would
        # cut a white band across the waiting well.
        cols$bg <- NA
        with_plot_theme(cols, {
          plot_empty_state(cols)
        })
        plot_error(NULL)
        return(invisible(NULL))
      }

      args <- tryCatch(build_viz_call(b, cols = cols), error = function(e) e)
      if (inherits(args, "error")) {
        plot_error(format_error(args, i18n, fallback = "err_plot_failed"))
        with_plot_theme(cols, {
          graphics::plot.new()
          graphics::text(0.5, 0.5, i18n$tr("b_plot_needs_attention"),
                         col = cols$accent, cex = 1.05)
        })
        return(invisible(NULL))
      }

      outcome <- tryCatch(
        run_with_warnings(with_plot_theme(
          cols,
          with_mcmctree_timescale(cols, do.call(MCMCtreeR::MCMC.tree.plot, args))
        )),
        error = function(e) e
      )
      if (inherits(outcome, "error")) {
        plot_error(format_error(outcome, i18n, fallback = "err_plot_failed"))
        with_plot_theme(cols, {
          graphics::plot.new()
          graphics::text(0.5, 0.5, i18n$tr("b_plot_failed"),
                         col = cols$accent, cex = 1.05)
        })
        return(invisible(NULL))
      }

      plot_error(NULL)
      if (length(outcome$warnings)) {
        message("[module B] ", paste(unique(outcome$warnings), collapse = " | "))
      }
      invisible(NULL)
    }, bg = "transparent", height = function() {
      # The placeholder well is sized by its own raster: the ghost tree is drawn
      # in normalised coordinates, so a taller well scales the watermark with it
      # instead of leaving it stranded in the middle.
      if (!isTRUE(state$b$data_ready)) return(440)
      inches <- plot_params()$plot_height_in %||% 7
      max(330, min(1200, inches * 96))
    })

    # A rendered figure and a placeholder should not wear the same frame: the
    # canvas is a sheet of paper once there is something on it, and a well
    # waiting for input before that. bslib 0.12 exports no class-toggling
    # helper, so the frame is chosen where the canvas is emitted.
    output$plot_canvas <- shiny::renderUI({
      ready <- isTRUE(state$b$data_ready)
      htmltools::tags$div(
        class = paste0("b-canvas", if (!ready) " is-empty"),
        shiny::plotOutput(outputId = ns("time_tree"), width = "100%")
      )
    })

    output$plot_status <- shiny::renderUI({
      b <- state$b
      if (!isTRUE(b$data_ready)) {
        # A failed load must show up where the work is, not only in the 380px
        # settings rail that may well be scrolled out of view.
        report <- b$source_report
        if (!is.null(report) && !isTRUE(report$ok)) {
          fmt <- report$error %||% list(text = i18n$tr("b_plot_failed"), detail = NULL)
          return(htmltools::tags$div(
            class = "alert alert-danger app-alert", role = "alert",
            htmltools::tags$strong(i18n$tr("b_source_status")),
            htmltools::tags$p(error_text(fmt)),
            if (!is.null(fmt$detail)) htmltools::tags$pre(class = "code-block", fmt$detail)
          ))
        }
        return(htmltools::tags$p(
          class = "plot-caption",
          i18n$tr("b_preview_empty")
        ))
      }
      fmt <- plot_error()
      if (!is.null(fmt)) {
        return(htmltools::tags$div(
          class = "alert alert-danger app-alert", role = "alert",
          htmltools::tags$strong(i18n$tr("b_plot_error")),
          htmltools::tags$p(error_text(fmt)),
          if (!is.null(fmt$detail)) htmltools::tags$pre(class = "code-block", fmt$detail)
        ))
      }
      extra <- NULL
      n_rows <- b$source_report$n_rows %||% NA_integer_
      if (!is.na(n_rows) && n_rows > LIMITS$manual_redraw_rows) {
        extra <- htmltools::tags$p(class = "form-hint", i18n$tr("b_large_chain_note"))
      }
      kind_label <- if (isTRUE(b$source_report$example)) {
        i18n$tr("b_source_example")
      } else {
        switch(
          b$source_kind %||% "",
          figtree = i18n$tr("b_source_figtree"),
          posterior = i18n$tr("b_source_posterior"),
          mrbayes = i18n$tr("b_analysis_mrbayes"),
          revbayes = i18n$tr("b_analysis_revbayes"),
          user = i18n$tr("b_analysis_user"),
          NULL
        )
      }
      report <- b$source_report
      summary <- if (!is.null(report$n_tip) && !is.null(report$n_node)) {
        i18n$tr("b_source_summary", report$n_tip, report$n_node)
      } else {
        NULL
      }
      meta <- paste(c(kind_label, summary), collapse = " \u00b7 ")
      htmltools::tags$div(
        class = "plot-status",
        htmltools::tags$p(i18n$tr("b_plot_ready")),
        if (nzchar(meta)) htmltools::tags$p(class = "form-hint", meta),
        if (isTRUE(b$params$add_time_scale)) {
          htmltools::tags$p(class = "form-hint", i18n$tr("b_plot_legend"))
        },
        if (!is.null(report$n_tip) && is.finite(report$n_tip) && report$n_tip > 80) {
          htmltools::tags$p(
            class = "form-hint",
            i18n$tr(if (isTRUE(b$params$show_tip_label)) {
              "b_large_tree_hint"
            } else {
              "b_tips_hidden_hint"
            })
          )
        },
        extra
      )
    })

    output$export_actions <- shiny::renderUI({
      b <- state$b
      if (!isTRUE(b$data_ready)) {
        return(htmltools::tags$div(
          class = "export-actions",
          htmltools::tags$button(
            class = "btn btn-secondary",
            disabled = "disabled",
            i18n$tr("download")
          ),
          htmltools::tags$p(class = "form-hint", i18n$tr("b_export_no_data"))
        ))
      }
      values <- export_values(input, fallback = b$export)
      label <- switch(
        values$format,
        pdf = i18n$tr("b_export_pdf"),
        png = i18n$tr("b_export_png"),
        svg = i18n$tr("b_export_svg"),
        i18n$tr("download")
      )
      htmltools::tags$div(
        class = "export-actions",
        `aria-label` = i18n$tr("aria_download"),
        shiny::downloadButton(
          outputId = ns("download_plot"),
          label = label,
          class = "btn-primary"
        ),
        htmltools::tags$p(class = "form-hint", i18n$tr("b_export_note"))
      )
    })

    output$download_plot <- shiny::downloadHandler(
      filename = function() {
        values <- export_values(input, fallback = state$b$export)
        ascii_filename(paste0("time_tree.", values$format))
      },
      content = function(file) {
        b <- state$b
        if (!isTRUE(b$data_ready)) return(invisible(NULL))
        values <- export_values(input, fallback = b$export)
        theme <- values$plot_theme
        mode <- ui_prefs$theme$mode()
        cols <- plot_colors(
          if (identical(values$format, "pdf")) "print" else effective_plot_theme(theme, mode)
        )

        outcome <- tryCatch({
          args <- build_viz_call(b, cols = cols)
          ws <- session_workspace(session, "output")
          path <- file.path(ws, paste0("time_tree.", values$format))
          export_time_tree(
            path, args,
            dev = values$format,
            width = values$width, height = values$height,
            res = values$dpi,
            plot_theme = theme, mode = mode
          )
          copy_download_file(path, file, ws)
          gc()
          TRUE
        }, error = function(e) e)

        if (inherits(outcome, "error")) {
          fmt <- format_error(outcome, i18n, fallback = "err_export_failed")
          user_notification(error_text(fmt), type = "error", duration = 10)
          stop(fmt$text)
        }
        invisible(NULL)
      },
      # Shiny requires a character contentType here; the file extension still
      # tells the browser how to open PDF, PNG or SVG.
      contentType = "application/octet-stream"
    )

    invisible(list(plot_error = plot_error, plot_params = plot_params))
  })
}
