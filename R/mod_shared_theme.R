# Session-scoped light/dark and plot colour preferences.
#
# Both values live inside moduleServer(). They are presentation preferences:
# they are never written into state$a or state$b and never participate in the
# result staleness hash.

mod_theme_ui <- function(id, i18n = NULL, plot_theme = "match", mode = "light") {
  ns <- shiny::NS(id)
  if (!isTRUE(mode %in% c("light", "dark"))) mode <- "light"
  # The interface owns the light/dark switch. Plot colours are decided where
  # figures are exported, not in the global masthead.
  shiny::tags$div(
    class = "theme-switch",
    bslib::input_dark_mode(id = ns("theme_mode"), mode = mode)
  )
}

mod_theme_server <- function(id, default_mode = "light") {
  shiny::moduleServer(id, function(input, output, session) {
    if (!isTRUE(default_mode %in% c("light", "dark"))) default_mode <- "light"
    mode <- shiny::reactive({
      value <- input$theme_mode %||% default_mode
      if (value %in% c("light", "dark")) value else default_mode
    })

    plot_theme <- shiny::reactiveVal("match")

    shiny::observeEvent(input$plot_theme, {
      if (isTRUE(input$plot_theme %in% c("match", "print"))) {
        plot_theme(input$plot_theme)
      }
    })

    list(
      mode = mode,
      plot_theme = shiny::reactive(plot_theme()),
      set_plot_theme = function(value) {
        if (isTRUE(value %in% c("match", "print"))) plot_theme(value)
      }
    )
  })
}
