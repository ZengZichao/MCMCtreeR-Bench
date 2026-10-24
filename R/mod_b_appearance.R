# Module B panel: tree appearance.

b_appearance_panel_ui <- function(ns, i18n, b) {
  params <- modifyList(viz_defaults(), b$params %||% list())
  htmltools::tagList(
    shiny::numericInput(
      inputId = ns("cex_tips"),
      label = i18n$tr("b_cex_tips"),
      value = params$cex_tips,
      min = 0, max = 5, step = 0.1, width = "100%"
    ),
    shiny::checkboxInput(
      inputId = ns("show_tip_label"),
      label = i18n$tr("b_show_tip_label"),
      value = isTRUE(params$show_tip_label)
    ),
    shiny::textInput(
      inputId = ns("col_tree"),
      label = i18n$tr("b_col_tree"),
      value = params$col_tree,
      placeholder = i18n$tr("b_color_placeholder"),
      width = "100%"
    ),
    shiny::textInput(
      inputId = ns("tip_color"),
      label = i18n$tr("b_tip_color"),
      value = params$tip_color,
      placeholder = i18n$tr("b_color_placeholder"),
      width = "100%"
    ),
    shiny::checkboxInput(
      inputId = ns("ladderize_tree"),
      label = i18n$tr("b_ladderize"),
      value = isTRUE(params$ladderize_tree)
    ),
    shiny::numericInput(
      inputId = ns("time_correction"),
      label = i18n$tr("b_time_correction"),
      value = params$time_correction,
      min = 0, step = 0.1, width = "100%"
    ),
    shiny::numericInput(
      inputId = ns("plot_height_in"),
      label = i18n$tr("b_plot_height"),
      value = params$plot_height_in,
      min = 3, max = 12, step = 0.5, width = "100%"
    )
  )
}
