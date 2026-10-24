# Module B panel: node uncertainty colours and distribution styling.

b_node_uncert_panel_ui <- function(ns, i18n, b) {
  params <- modifyList(viz_defaults(), b$params %||% list())
  htmltools::tagList(
    shiny::selectInput(
      inputId = ns("node_method"),
      label = i18n$tr("b_node_method"),
      choices = stats::setNames(
        c("bar", "node.length", "full.length", "none"),
        c(
          i18n$tr("b_node_bar"), i18n$tr("b_node_length"),
          i18n$tr("b_node_full_length"), i18n$tr("b_node_none")
        )
      ),
      selected = params$node_method,
      width = "100%"
    ),
    htmltools::tags$p(class = "form-hint", i18n$tr("b_node_method_hint")),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] === 'phylogram'", ns("plot_type")),
      shiny::textInput(
        inputId = ns("col_age"),
        label = i18n$tr("b_col_age"),
        value = params$col_age,
        placeholder = i18n$tr("b_color_placeholder"),
        width = "100%"
      ),
      shiny::numericInput(
        inputId = ns("lwd_bar"),
        label = i18n$tr("b_lwd_bar"),
        value = params$lwd_bar,
        min = 0, max = 20, step = 0.1, width = "100%"
      ),
      shiny::checkboxInput(
        inputId = ns("tip_lengths"),
        label = i18n$tr("b_tip_lengths"),
        value = isTRUE(params$tip_lengths)
      ),
      shiny::textInput(
        inputId = ns("tip_bar_col"),
        label = i18n$tr("b_tip_bar_col"),
        value = params$tip_bar_col,
        placeholder = i18n$tr("b_color_placeholder"),
        width = "100%"
      )
    ),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] === 'distributions'", ns("plot_type")),
      shiny::numericInput(
        inputId = ns("distribution_height"),
        label = i18n$tr("b_distribution_height"),
        value = params$distribution_height,
        min = 0, max = 1, step = 0.05, width = "100%"
      ),
      shiny::textInput(
        inputId = ns("density_col"),
        label = i18n$tr("b_density_col"),
        value = params$density_col,
        placeholder = i18n$tr("b_color_placeholder"),
        width = "100%"
      ),
      shiny::textInput(
        inputId = ns("density_border_col"),
        label = i18n$tr("b_density_border_col"),
        value = params$density_border_col,
        placeholder = i18n$tr("b_color_placeholder"),
        width = "100%"
      )
    )
  )
}
