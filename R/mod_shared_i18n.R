# Session-scoped language module.
#
# The language value is created inside moduleServer() so that two browsers in
# the same R process never share a language.

mod_i18n_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tags$div(
    class = "lang-switch",
    shiny::selectInput(
      inputId = ns("lang"),
      label = htmltools::tags$span(
        class = "visually-hidden",
        "Language / \u8bed\u8a00"
      ),
      choices = c("English" = "en", "\u4e2d\u6587" = "zh"),
      selected = "en",
      width = "auto",
      selectize = FALSE
    )
  )
}

mod_i18n_server <- function(id, default = "en", lock_default = FALSE) {
  shiny::moduleServer(id, function(input, output, session) {
    lang <- shiny::reactiveVal(normalize_lang(default))
    user_chosen <- shiny::reactiveVal(isTRUE(lock_default))

    if (!identical(normalize_lang(default), "en")) {
      shiny::updateSelectInput(session, "lang", selected = normalize_lang(default))
    }

    # app.js sets this input from navigator.language on page load.
    shiny::observeEvent(input$browser_lang, {
      if (!is.null(input$browser_lang) && !isTRUE(user_chosen())) {
        value <- normalize_lang(input$browser_lang)
        lang(value)
        shiny::updateSelectInput(session, "lang", selected = value)
      }
    })

    # app.js restores the last manual choice from localStorage.
    shiny::observeEvent(input$lang_saved, {
      if (isTRUE(input$lang_saved %in% c("zh", "en"))) {
        user_chosen(TRUE)
        lang(input$lang_saved)
        shiny::updateSelectInput(session, "lang", selected = input$lang_saved)
      }
    })

    shiny::observeEvent(input$lang, {
      if (!input$lang %in% c("zh", "en")) return()
      if (identical(input$lang, lang())) return()
      user_chosen(TRUE)
      lang(input$lang)
      session$sendCustomMessage("mcmctreer_save_lang", input$lang)
    })

    list(
      lang = lang,
      tr = function(key, ...) tr(lang(), key, ...),
      set_lang = function(value) {
        value <- normalize_lang(value)
        user_chosen(TRUE)
        lang(value)
        shiny::updateSelectInput(session, "lang", selected = value)
        session$sendCustomMessage("mcmctreer_save_lang", value)
      }
    )
  })
}
