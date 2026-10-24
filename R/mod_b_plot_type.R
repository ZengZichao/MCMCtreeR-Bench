# Module B panel: plot type and node filter.

b_plot_type_panel_ui <- function(ns, i18n, b) {
  params <- modifyList(viz_defaults(), b$params %||% list())
  htmltools::tagList(
    shiny::selectInput(
      inputId = ns("plot_type"),
      label = i18n$tr("b_plot_type"),
      choices = stats::setNames(
        c("phylogram", "cladogram", "distributions"),
        c(
          i18n$tr("b_plot_phylogram"),
          i18n$tr("b_plot_cladogram"),
          i18n$tr("b_plot_distributions")
        )
      ),
      selected = params$plot_type,
      width = "100%"
    ),
    htmltools::tags$p(class = "form-hint", i18n$tr("b_plot_type_hint")),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] === 'MCMCtree'", ns("analysis_type")),
      shiny::checkboxInput(
        inputId = ns("build_tree"),
        label = i18n$tr("b_build_tree"),
        value = isTRUE(params$build_tree)
      ),
      htmltools::tags$p(class = "form-hint", i18n$tr("b_build_tree_hint"))
    ),
    shiny::textInput(
      inputId = ns("all_nodes_raw"),
      label = i18n$tr("b_all_nodes"),
      value = params$all_nodes_raw,
      placeholder = i18n$tr("b_all_nodes_hint"),
      width = "100%"
    ),
    htmltools::tags$p(class = "form-hint", i18n$tr("b_all_nodes_hint"))
  )
}
