# golem-style launcher.

run_app <- function(onStart = NULL, options = list(),
                    enableBookmarking = "disable", uiPattern = "/", ...) {
  options(shiny.maxRequestSize = LIMITS$max_upload_bytes)
  golem::with_golem_options(
    app = shiny::shinyApp(
      ui = app_ui,
      server = app_server,
      onStart = onStart,
      options = options,
      enableBookmarking = enableBookmarking,
      uiPattern = uiPattern
    ),
    golem_opts = list(...)
  )
}
