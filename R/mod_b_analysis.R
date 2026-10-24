# Module B panel: MrBayes / RevBayes analysis settings.

b_analysis_panel_ui <- function(ns, i18n, b) {
  params <- modifyList(viz_defaults(), b$params %||% list())
  htmltools::tagList(
    htmltools::tags$p(class = "form-hint", i18n$tr("b_analysis_hint")),
    shiny::conditionalPanel(
      condition = sprintf(
        "input['%s'] === 'MrBayes' || input['%s'] === 'RevBayes'",
        ns("analysis_type"), ns("analysis_type")
      ),
      shiny::numericInput(
        inputId = ns("burn_in"),
        label = i18n$tr("b_burn_in"),
        value = params$burn_in,
        min = 0, max = 1, step = 0.05, width = "100%"
      ),
      shiny::numericInput(
        inputId = ns("n_runs"),
        label = i18n$tr("b_n_runs"),
        value = params$n_runs,
        min = 1, max = 20, step = 1, width = "100%"
      )
    )
  )
}
