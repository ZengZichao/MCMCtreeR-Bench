# Step 6: preview the calibrated tree and export .tre and distribution figures.

step6_ui <- function(ns, i18n, a) {
  if (is.null(a$results)) {
    return(htmltools::tagList(
      htmltools::tags$div(
        class = "step-block",
        htmltools::tags$h4(i18n$tr("step6_title")),
        htmltools::tags$p(class = "step-hint", i18n$tr("step6_hint")),
        htmltools::tags$div(class = "alert alert-info app-alert", i18n$tr("export_no_results"))
      )
    ))
  }

  htmltools::tagList(
    htmltools::tags$div(
      class = "step-block",
      htmltools::tags$h4(i18n$tr("step6_title")),
      htmltools::tags$p(class = "step-hint", i18n$tr("step6_hint")),
      shiny::uiOutput(ns("export_stale")),
      shiny::uiOutput(ns("export_actions")),
      htmltools::tags$h5(i18n$tr("export_tree_preview")),
      shiny::plotOutput(ns("result_tree"), height = "420px"),
      htmltools::tags$h5(i18n$tr("export_tre_preview")),
      htmltools::tags$p(class = "form-hint", i18n$tr("export_tre_hint")),
      shiny::uiOutput(ns("tre_preview")),
      htmltools::tags$h5(i18n$tr("export_summary")),
      shiny::uiOutput(ns("summary_table")),
      htmltools::tags$h5(i18n$tr("export_distributions")),
      htmltools::tags$p(class = "form-hint", i18n$tr("export_distributions_hint")),
      export_controls_ui(ns, i18n, a$export, prefix = "export")
    )
  )
}

mod_a_export_server <- function(input, output, session, ns, state, set_a,
                                bump, i18n, ui_prefs, stale, workspace) {
  shiny::observeEvent(
    list(
      input$export_width,
      input$export_height,
      input$export_dpi,
      input$export_format,
      input$export_plot_theme
    ),
    {
        values <- export_values(input, fallback = state$a$export)
        if (!identical(values, state$a$export)) {
          a <- state$a
          a$export <- values
          set_a(a)
        }
      },
      ignoreNULL = FALSE
    )

  output$export_stale <- shiny::renderUI({
    if (is.null(state$a$results)) return(NULL)
    if (isTRUE(stale())) {
      return(htmltools::tags$div(
        class = "alert alert-warning app-alert", role = "alert",
        i18n$tr("export_disabled_stale")
      ))
    }
    NULL
  })

  output$export_actions <- shiny::renderUI({
    if (is.null(state$a$results)) return(NULL)
    if (isTRUE(stale())) {
      return(htmltools::tags$div(
        class = "export-actions",
        htmltools::tags$button(
          class = "btn btn-secondary", disabled = "disabled",
          i18n$tr("btn_download_tre")
        ),
        htmltools::tags$button(
          class = "btn btn-secondary", disabled = "disabled",
          i18n$tr("export_distributions")
        )
      ))
    }
    format <- export_values(input, fallback = state$a$export)$format
    label <- switch(
      format,
      pdf = i18n$tr("btn_download_pdf"),
      png = i18n$tr("btn_download_png"),
      svg = i18n$tr("btn_download_svg"),
      i18n$tr("download")
    )
    htmltools::tags$div(
      class = "export-actions",
      shiny::downloadButton(
        outputId = ns("download_tre"),
        label = i18n$tr("export_download_tre"),
        class = "btn-primary"
      ),
      shiny::downloadButton(
        outputId = ns("download_distributions"),
        label = label,
        class = "btn-outline-primary"
      )
    )
  })

  output$tre_preview <- shiny::renderUI({
    results <- state$a$results
    if (is.null(results)) return(NULL)
    text_id <- ns("tre_text")
    copy_js <- sprintf(
      "navigator.clipboard.writeText(document.getElementById('%s').innerText); return false;",
      text_id
    )
    htmltools::tags$div(
      htmltools::tags$pre(
        id = text_id,
        class = "code-block tre-preview",
        tre_text(results$final_tre)
      ),
      htmltools::tags$div(
        class = "copy-row",
        htmltools::tags$button(
          type = "button",
          class = "btn btn-outline-secondary btn-sm",
          onclick = copy_js,
          i18n$tr("btn_copy_tre")
        ),
        htmltools::tags$p(class = "form-hint", i18n$tr("copy_help"))
      )
    )
  })

  output$result_tree <- shiny::renderPlot({
    results <- state$a$results
    if (is.null(results)) {
      graphics::plot.new()
      graphics::text(0.5, 0.5, i18n$tr("estimate_no_results"), col = "#6C757D")
      return(invisible(NULL))
    }
    cols <- plot_colors_for(ui_prefs)
    view <- state$a$view %||% list(show_node_ids = TRUE, show_tip_labels = TRUE)
    with_plot_theme(cols, plot_calibrated_tree(
      results$final_phy,
      state$a$calibrated,
      cols = cols,
      show_tip_label = isTRUE(view$show_tip_labels),
      show_node_ids = isTRUE(view$show_node_ids)
    ))
  }, bg = "transparent")

  output$summary_table <- shiny::renderUI({
    results <- state$a$results
    if (is.null(results)) return(NULL)
    summary <- parameter_summary(results)
    if (!nrow(summary)) return(NULL)
    htmltools::tags$table(
      class = "table table-sm summary-table",
      htmltools::tags$thead(htmltools::tags$tr(
        htmltools::tags$th(i18n$tr("estimate_summary_col_node")),
        htmltools::tags$th(i18n$tr("estimate_summary_col_method")),
        htmltools::tags$th(i18n$tr("estimate_summary_col_params"))
      )),
      htmltools::tags$tbody(
        lapply(seq_len(nrow(summary)), function(i) {
          htmltools::tags$tr(
            htmltools::tags$td(summary$node[i]),
            htmltools::tags$td(summary$method[i]),
            htmltools::tags$td(summary$parameters[i])
          )
        })
      )
    )
  })

  output$download_tre <- shiny::downloadHandler(
    filename = function() "mcmctree_priors.tre",
    content = function(file) {
      results <- state$a$results
      if (is.null(results) || isTRUE(stale())) {
        return(invisible(NULL))
      }
      ws <- session_workspace(session, "output")
      path <- file.path(ws, "mcmctree_priors.tre")
      write_text_file(path, tre_text(results$final_tre))
      copy_download_file(path, file, ws)
    },
    contentType = content_type_for("mcmctree_priors.tre")
  )

  output$download_distributions <- shiny::downloadHandler(
    filename = function() {
      format <- export_values(input, fallback = state$a$export)$format
      ascii_filename(paste0("node_distributions.", format))
    },
    content = function(file) {
      results <- state$a$results
      if (is.null(results) || isTRUE(stale())) {
        return(invisible(NULL))
      }
      values <- export_values(input, fallback = state$a$export)
      ws <- session_workspace(session, "output")
      path <- file.path(ws, paste0("node_distributions.", values$format))
      theme <- values$plot_theme
      mode <- ui_prefs$theme$mode()

      if (identical(values$format, "pdf")) {
        export_distributions_pdf(
          path, results,
          width = values$width, height = values$height,
          plot_theme = theme, mode = mode
        )
      } else {
        export_distributions_image(
          path, results,
          dev = values$format,
          width = values$width, height = values$height,
          res = values$dpi,
          plot_theme = theme, mode = mode
        )
      }
      copy_download_file(path, file, ws)
      gc()
    },
    # Shiny requires a character contentType here; the file extension still
    # tells the browser how to open PDF, PNG or SVG.
    contentType = "application/octet-stream"
  )
}
