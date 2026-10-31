# Top-level server: state, session-scoped preferences, modules, footer, modals.

app_server <- function(input, output, session) {
  options(shiny.maxRequestSize = LIMITS$max_upload_bytes)

  state <- shiny::reactiveValues(
    a = list(
      phy = NULL,
      phy_source = NULL,
      phy_report = NULL,
      calibrated = list(),
      selected = integer(),
      results = NULL,
      results_input = NULL,
      results_error = NULL,
      step = 1L,
      load_mode = "file",
      tree_paste_text = "",
      view = list(show_node_ids = TRUE, show_tip_labels = TRUE),
      export = list(
        width = 8, height = 6, dpi = 200, format = "pdf",
        plot_theme = "print"
      )
    ),
    b = list(
      analysis_type = "MCMCtree",
      source_kind = NULL,
      phy = NULL,
      chain = NULL,
      node_ages = NULL,
      directory.files = NULL,
      workspace = NULL,
      source_report = NULL,
      data_ready = FALSE,
      params = viz_defaults(),
      export = list(
        width = 9, height = 7, dpi = 200, format = "pdf",
        plot_theme = "print"
      ),
      auto_redraw = TRUE,
      plot_error = NULL,
      source_key = 0L,
      loaded_at = NULL
    )
  )

  set_a <- function(value) state$a <- value
  set_b <- function(value) state$b <- value

  query <- tryCatch(
    shiny::parseQueryString(session$clientData$url_search),
    error = function(e) list()
  )
  query_lang <- query$lang
  if (!is.null(query_lang) && !query_lang %in% c("zh", "en")) query_lang <- NULL

  ui_prefs <- list(
    i18n = mod_i18n_server(
      "i18n",
      default = query_lang %||% "en",
      lock_default = !is.null(query_lang)
    ),
    theme = mod_theme_server("theme")
  )

  mod_a_server("a", state = state, set_a = set_a, ui_prefs = ui_prefs)
  mod_b_server("b", state = state, set_b = set_b, ui_prefs = ui_prefs)

  last_dirty <- NULL
  shiny::observe({
    dirty <- has_unsaved_state(state$a, state$b)
    if (!identical(dirty, last_dirty)) {
      last_dirty <<- dirty
      session$sendCustomMessage("mcmctreer_dirty", dirty)
    }
  })

  output$nav_a_title <- shiny::renderUI(ui_prefs$i18n$tr("nav_a"))
  output$nav_b_title <- shiny::renderUI(ui_prefs$i18n$tr("nav_b"))
  output$nav_about_title <- shiny::renderUI(ui_prefs$i18n$tr("nav_about"))
  output$nav_theme <- shiny::renderUI({
    ui_prefs$i18n$lang()
    mod_theme_ui(
      "theme",
      i18n = ui_prefs$i18n,
      plot_theme = shiny::isolate(ui_prefs$theme$plot_theme()),
      mode = shiny::isolate(ui_prefs$theme$mode())
    )
  })
  output$about_page <- shiny::renderUI(about_page_ui(ui_prefs$i18n))

  show_privacy <- function() {
    if (!is.null(shiny::getDefaultReactiveDomain())) {
      shiny::showModal(privacy_modal(ui_prefs$i18n))
    }
  }

  shiny::observeEvent(input$privacy_seen, {
    if (!is.null(input$privacy_seen) && !isTRUE(input$privacy_seen)) show_privacy()
  })

  shiny::observeEvent(input$privacy_ack, {
    if (!is_button_click(input$privacy_ack)) return()
    shiny::removeModal()
    session$sendCustomMessage("mcmctreer_privacy_seen", TRUE)
  })

  shiny::observeEvent(input$footer_privacy, {
    if (is_button_click(input$footer_privacy)) show_privacy()
  })
  shiny::observeEvent(input$footer_cite, {
    if (!is_button_click(input$footer_cite)) return()
    shiny::showModal(cite_modal(ui_prefs$i18n))
  })
  shiny::observeEvent(input$footer_local, {
    if (!is_button_click(input$footer_local)) return()
    shiny::showModal(local_run_modal(ui_prefs$i18n))
  })

  session$onSessionEnded(function() {
    clean_session_workspace(session)
  })

  invisible(list(state = state, ui_prefs = ui_prefs))
}

privacy_modal <- function(i18n) {
  shiny::modalDialog(
    title = i18n$tr("privacy_title"),
    htmltools::tags$p(i18n$tr("privacy_body")),
    htmltools::tags$p(
      class = "modal-muted",
      htmltools::tags$a(
        href = GUI_META$repo, target = "_blank", rel = "noopener noreferrer",
        "README / GitHub"
      )
    ),
    footer = shiny::actionButton(
      "privacy_ack", i18n$tr("privacy_ack"), class = "btn-primary"
    ),
    easyClose = FALSE,
    size = "m"
  )
}

cite_modal <- function(i18n) {
  shiny::modalDialog(
    title = i18n$tr("cite_title"),
    htmltools::tags$p(i18n$tr("cite_hint")),
    htmltools::tags$h6(i18n$tr("cite_gui")),
    htmltools::tags$pre(class = "code-block", gui_citation_text()),
    htmltools::tags$h6(i18n$tr("cite_upstream")),
    htmltools::tags$pre(class = "code-block", upstream_citation_text()),
    footer = shiny::modalButton(i18n$tr("close")),
    easyClose = TRUE,
    size = "m"
  )
}

local_run_modal <- function(i18n) {
  shiny::modalDialog(
    title = i18n$tr("local_title"),
    htmltools::tags$p(i18n$tr("local_body")),
    htmltools::tags$pre(class = "code-block", GUI_META$local_command),
    footer = shiny::modalButton(i18n$tr("close")),
    easyClose = TRUE,
    size = "m"
  )
}
