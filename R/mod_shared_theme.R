# Session-scoped light/dark and plot colour preferences.
#
# Both values live inside moduleServer(). They are presentation preferences:
# they are never written into state$a or state$b and never participate in the
# result staleness hash.

mod_theme_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tags$div(
    class = "theme-switch",
    bslib::input_dark_mode(id = ns("theme_mode"), mode = NULL),
    shiny::selectInput(
      inputId = ns("plot_theme"),
      label = NULL,
      choices = c("match" = "match", "print" = "print"),
      selected = "match",
      width = "auto",
      selectize = FALSE
    )
  )
}

mod_theme_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    mode <- shiny::reactive({
      value <- input$theme_mode %||% "light"
      if (value %in% c("light", "dark")) value else "light"
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
