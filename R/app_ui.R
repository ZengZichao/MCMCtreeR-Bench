# Top-level UI shell. No i18n$tr() calls here: language is session state and
# the translatable parts are rendered by app_server via uiOutput().

app_ui <- function(request) {
  page <- bslib::page_navbar(
    title = htmltools::tagList(
      htmltools::tags$span(class = "app-brand", "MCMCtreeR Bench"),
      htmltools::tags$small(class = "app-version", paste0("v", app_version()))
    ),
    theme = app_theme(),
    fillable = FALSE,
    bslib::nav_panel(
      title = shiny::uiOutput("nav_a_title", inline = TRUE),
      value = "a",
      mod_a_ui("a")
    ),
    bslib::nav_panel(
      title = shiny::uiOutput("nav_b_title", inline = TRUE),
      value = "b",
      mod_b_ui("b")
    ),
    bslib::nav_spacer(),
    bslib::nav_item(mod_i18n_ui("i18n")),
    bslib::nav_item(mod_theme_ui("theme")),
    footer = shiny::uiOutput("app_footer")
  )

  htmltools::tagList(
    htmltools::tags$head(
      htmltools::tags$link(rel = "icon", href = "data:,")
    ),
    golem_add_external_resources(),
    page
  )
}

# Shared footer content. Kept in app_server because it depends on the current
# session language.
footer_ui <- function(i18n) {
  htmltools::tags$footer(
    class = "app-footer",
    htmltools::tags$div(
      class = "footer-line",
      htmltools::tags$span(i18n$tr("footer_version", app_version())),
      htmltools::tags$span(class = "footer-sep", "|"),
      htmltools::tags$span(i18n$tr("footer_author")),
      htmltools::tags$span(class = "footer-sep", "|"),
      htmltools::tags$a(
        href = orcid_url(), target = "_blank", rel = "noopener noreferrer",
        i18n$tr("footer_orcid"), class = "footer-link"
      )
    ),
    htmltools::tags$div(
      class = "footer-line",
      htmltools::tags$a(
        href = "#", class = "footer-link",
        onclick = "Shiny.setInputValue('footer_privacy', Math.random(), {priority: 'event'}); return false;",
        i18n$tr("footer_privacy")
      ),
      htmltools::tags$span(class = "footer-sep", "|"),
      htmltools::tags$a(
        href = "#", class = "footer-link",
        onclick = "Shiny.setInputValue('footer_local', Math.random(), {priority: 'event'}); return false;",
        i18n$tr("footer_local")
      ),
      htmltools::tags$span(class = "footer-sep", "|"),
      htmltools::tags$a(
        href = "#", class = "footer-link",
        onclick = "Shiny.setInputValue('footer_cite', Math.random(), {priority: 'event'}); return false;",
        i18n$tr("footer_cite")
      ),
      htmltools::tags$span(class = "footer-sep", "|"),
      htmltools::tags$a(
        href = "#", class = "footer-link",
        onclick = "Shiny.setInputValue('footer_about', Math.random(), {priority: 'event'}); return false;",
        i18n$tr("footer_about")
      ),
      htmltools::tags$span(class = "footer-sep", "|"),
      htmltools::tags$a(
        href = GUI_META$repo, target = "_blank", rel = "noopener noreferrer",
        i18n$tr("footer_source"), class = "footer-link"
      ),
      htmltools::tags$span(class = "footer-sep", "|"),
      htmltools::tags$span(i18n$tr("footer_license"))
    ),
    htmltools::tags$div(
      class = "footer-line footer-muted",
      i18n$tr("footer_upstream")
    )
  )
}
