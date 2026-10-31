# Top-level UI shell. Language is session state; app_ui() itself contains no
# i18n$tr() calls and receives translated copy through app_server outputs.

app_mark_svg <- function() {
  paste0(
    '<svg class="app-mark" viewBox="0 0 24 24" width="22" height="22" ',
    'fill="none" stroke="currentColor" stroke-width="1.6" ',
    'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" ',
    'focusable="false">',
    '<path d="M12 21.5V16"/>',
    '<path d="M12 16 6.5 11.5V6.5"/>',
    '<path d="M12 16 17.5 11.5V6.5"/>',
    '<circle cx="12" cy="16" r="1.5" fill="currentColor" stroke="none"/>',
    '<circle cx="6.5" cy="5" r="1.8" fill="currentColor" stroke="none"/>',
    '<circle cx="17.5" cy="5" r="1.8" fill="currentColor" stroke="none"/>',
    "</svg>"
  )
}

hero_content <- function(eyebrow, title, lead, chips = character()) {
  htmltools::tagList(
    htmltools::tags$p(
      class = "hero-eyebrow",
      htmltools::tags$span(class = "hero-dot", `aria-hidden` = "true"),
      eyebrow
    ),
    htmltools::tags$h1(class = "hero-title", title),
    htmltools::tags$p(class = "hero-lead", lead),
    if (length(chips)) {
      htmltools::tags$div(
        class = "hero-meta",
        lapply(chips, function(chip) {
          htmltools::tags$span(class = "hero-chip", chip)
        })
      )
    }
  )
}

app_ui <- function(request) {
  page <- bslib::page_navbar(
    title = htmltools::tagList(
      htmltools::tags$span(
        class = "app-brand-lockup",
        htmltools::HTML(app_mark_svg()),
        htmltools::tags$span(class = "app-brand", "MCMCtreeR Bench")
      ),
      htmltools::tags$small(class = "app-version", paste0("v", app_version()))
    ),
    theme = app_theme(),
    fillable = FALSE,
    window_title = "MCMCtreeR Bench | Priors and time trees",
    navbar_options = bslib::navbar_options(
      bg = "#000000",
      theme = "dark",
      underline = FALSE
    ),
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
    bslib::nav_panel(
      title = shiny::uiOutput("nav_about_title", inline = TRUE),
      value = "about",
      shiny::uiOutput("about_page")
    ),
    bslib::nav_spacer(),
    bslib::nav_item(
      htmltools::tags$div(
        class = "nav-controls",
        mod_i18n_ui("i18n"),
        shiny::uiOutput("nav_theme")
      )
    )
  )

  htmltools::tagList(
    htmltools::tags$head(
      htmltools::tags$meta(
        name = "description",
        content = "Prepare MCMCtree time priors and visualise time-calibrated phylogenies."
      ),
      htmltools::tags$link(
        rel = "icon",
        type = "image/svg+xml",
        href = paste0(
          "data:image/svg+xml,",
          "%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E",
          "%3Crect width='24' height='24' rx='5' fill='%230066cc'/%3E",
          "%3Cpath d='M12 19v-4M12 15 7 11V7M12 15l5-4V7' stroke='white' stroke-width='1.8' stroke-linecap='round'/%3E",
          "%3Ccircle cx='7' cy='6' r='1.7' fill='white'/%3E",
          "%3Ccircle cx='17' cy='6' r='1.7' fill='white'/%3E",
          "%3Ccircle cx='12' cy='15' r='1.5' fill='white'/%3E",
          "%3C/svg%3E"
        )
      )
    ),
    golem_add_external_resources(),
    page
  )
}

# About is a full page, not a footer: project metadata, resources and citation.
about_page_ui <- function(i18n) {
  modal_link <- function(input_id, label) {
    # Opens a dialog rather than navigating, so it must not be announced as a
    # link; role="button" keeps the existing .about-link styling intact.
    htmltools::tags$a(
      href = "#",
      class = "about-link",
      role = "button",
      onclick = sprintf(
        paste0(
          "Shiny.setInputValue('%s', Math.random(), ",
          "{priority: 'event'}); return false;"
        ),
        input_id
      ),
      label
    )
  }
  external_link <- function(href, label) {
    htmltools::tags$a(
      href = href,
      target = "_blank",
      rel = "noopener noreferrer",
      class = "about-link",
      label
    )
  }
  detail_link <- function(href, label) {
    htmltools::tags$a(
      href = href,
      target = "_blank",
      rel = "noopener noreferrer",
      label
    )
  }

  htmltools::tagList(
    htmltools::tags$section(
      class = "hero hero--compact",
      htmltools::tags$div(
        class = "hero-inner",
        hero_content(
          eyebrow = i18n$tr("app_title"),
          title = i18n$tr("about_title"),
          lead = i18n$tr("about_lead"),
          chips = c(
            paste0("v", app_version()),
            paste(i18n$tr("lang_en"), "/", i18n$tr("lang_zh"))
          )
        )
      )
    ),
    htmltools::tags$section(
      class = "workbench about-workbench",
      htmltools::tags$div(
        class = "workbench-inner",
        htmltools::tags$div(
          class = "about-grid",
          htmltools::tags$article(
            class = "surface-card about-card about-card--main",
            htmltools::tags$h2(
              class = "about-card-title",
              i18n$tr("footer_project")
            ),
            htmltools::tags$p(class = "about-body", i18n$tr("about_body")),
            htmltools::tags$dl(
              class = "about-dl",
              htmltools::tags$dt(i18n$tr("author_label")),
              htmltools::tags$dd(paste0(
                app_author_name(), " (", GUI_META$author_cn, ")"
              )),
              htmltools::tags$dt(i18n$tr("contact_label")),
              htmltools::tags$dd(htmltools::tags$a(
                href = paste0("mailto:", app_email()), app_email()
              )),
              htmltools::tags$dt(i18n$tr("orcid_label")),
              htmltools::tags$dd(detail_link(orcid_url(), app_orcid())),
              htmltools::tags$dt(i18n$tr("license_label")),
              htmltools::tags$dd(GUI_META$license),
              htmltools::tags$dt(i18n$tr("upstream_label")),
              htmltools::tags$dd(detail_link(UPSTREAM$repo, paste0(
                UPSTREAM$package, " @ ", UPSTREAM$commit
              )))
            ),
            htmltools::tags$p(
              class = "about-note",
              i18n$tr("footer_upstream")
            )
          ),
          htmltools::tags$div(
            class = "about-side",
            htmltools::tags$section(
              class = "surface-card about-card",
              htmltools::tags$h2(
                class = "about-card-title",
                i18n$tr("footer_resources")
              ),
              htmltools::tags$nav(
                class = "about-links",
                `aria-label` = i18n$tr("footer_resources"),
                modal_link("footer_privacy", i18n$tr("footer_privacy")),
                modal_link("footer_local", i18n$tr("footer_local")),
                modal_link("footer_cite", i18n$tr("footer_cite")),
                external_link(GUI_META$repo, i18n$tr("footer_source")),
                external_link(orcid_url(), i18n$tr("footer_orcid"))
              ),
              htmltools::tags$p(
                class = "about-note",
                i18n$tr("privacy_short")
              )
            ),
            htmltools::tags$section(
              class = "surface-card about-card",
              htmltools::tags$h2(
                class = "about-card-title",
                i18n$tr("cite_title")
              ),
              htmltools::tags$p(class = "about-body", i18n$tr("cite_hint")),
              htmltools::tags$h3(
                class = "about-subtitle",
                i18n$tr("cite_gui")
              ),
              htmltools::tags$pre(
                class = "code-block",
                gui_citation_text()
              ),
              htmltools::tags$h3(
                class = "about-subtitle",
                i18n$tr("cite_upstream")
              ),
              htmltools::tags$pre(
                class = "code-block",
                upstream_citation_text()
              )
            )
          )
        )
      )
    )
  )
}
