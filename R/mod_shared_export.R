# Shared export-control helpers (no module namespace of their own).

export_controls_ui <- function(ns, i18n, values, prefix = "export") {
  values <- modifyList(
    list(width = 9, height = 7, dpi = 200, format = "pdf", plot_theme = "print"),
    values %||% list()
  )
  htmltools::tagList(
    htmltools::tags$div(
      class = "export-grid",
      shiny::selectInput(
        inputId = ns(paste0(prefix, "_format")),
        label = i18n$tr("lbl_format"),
        choices = stats::setNames(
          c("pdf", "png", "svg"),
          c(i18n$tr("fmt_pdf"), i18n$tr("fmt_png"), i18n$tr("fmt_svg"))
        ),
        selected = values$format,
        width = "100%"
      ),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] !== 'pdf'", ns(paste0(prefix, "_format"))),
        shiny::selectInput(
          inputId = ns(paste0(prefix, "_plot_theme")),
          label = i18n$tr("theme_export_label"),
          choices = stats::setNames(
            c("match", "print"),
            c(i18n$tr("theme_plot_match"), i18n$tr("theme_plot_print"))
          ),
          selected = values$plot_theme,
          width = "100%"
        )
      ),
      shiny::numericInput(
        inputId = ns(paste0(prefix, "_width")),
        label = i18n$tr("lbl_width"),
        value = values$width,
        min = 2, max = 16, step = 0.5, width = "100%"
      ),
      shiny::numericInput(
        inputId = ns(paste0(prefix, "_height")),
        label = i18n$tr("lbl_height"),
        value = values$height,
        min = 2, max = 12, step = 0.5, width = "100%"
      ),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] === 'png'", ns(paste0(prefix, "_format"))),
        shiny::numericInput(
          inputId = ns(paste0(prefix, "_dpi")),
          label = i18n$tr("lbl_dpi"),
          value = values$dpi,
          min = 72, max = 200, step = 10, width = "100%"
        )
      )
    ),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] === 'pdf'", ns(paste0(prefix, "_format"))),
      htmltools::tags$p(class = "form-hint", i18n$tr("pdf_print_note"))
    ),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] !== 'pdf'", ns(paste0(prefix, "_format"))),
      htmltools::tags$p(class = "form-hint", i18n$tr("export_colour_note"))
    ),
    htmltools::tags$p(class = "form-hint", i18n$tr("ascii_name_hint"))
  )
}

export_values <- function(input, prefix = "export",
                          fallback = list(
                            width = 9, height = 7, dpi = 200,
                            format = "pdf", plot_theme = "print"
                          )) {
  result <- fallback
  width <- input[[paste0(prefix, "_width")]]
  height <- input[[paste0(prefix, "_height")]]
  dpi <- input[[paste0(prefix, "_dpi")]]
  format <- input[[paste0(prefix, "_format")]]
  plot_theme <- input[[paste0(prefix, "_plot_theme")]]
  if (!is.null(width) && is.finite(width)) result$width <- as.numeric(width)
  if (!is.null(height) && is.finite(height)) result$height <- as.numeric(height)
  if (!is.null(dpi) && is.finite(dpi)) result$dpi <- as.numeric(dpi)
  if (!is.null(format) && format %in% c("pdf", "png", "svg")) result$format <- format
  if (!is.null(plot_theme) && plot_theme %in% c("match", "print")) {
    result$plot_theme <- plot_theme
  }
  result
}
