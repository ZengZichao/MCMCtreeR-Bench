# Module B panel: geological time scale (the largest parameter group).

b_timescale_panel_ui <- function(ns, i18n, b) {
  params <- modifyList(viz_defaults(), b$params %||% list())
  htmltools::tagList(
    shiny::checkboxInput(
      inputId = ns("add_time_scale"),
      label = i18n$tr("b_add_time_scale"),
      value = isTRUE(params$add_time_scale)
    ),
    shiny::conditionalPanel(
      condition = sprintf("input['%s'] === true", ns("add_time_scale")),
      shiny::checkboxInput(
        inputId = ns("add_abs_time"),
        label = i18n$tr("b_add_abs_time"),
        value = isTRUE(params$add_abs_time)
      ),
      shiny::selectInput(
        inputId = ns("scale_res"),
        label = i18n$tr("b_scale_res"),
        choices = stats::setNames(
          c("Eon", "Period", "Epoch", "Age"),
          c(
            i18n$tr("b_scale_eon"), i18n$tr("b_scale_period"),
            i18n$tr("b_scale_epoch"), i18n$tr("b_scale_age")
          )
        ),
        selected = params$scale_res,
        multiple = TRUE,
        selectize = FALSE,
        size = 4,
        width = "100%"
      ),
      shiny::checkboxInput(
        inputId = ns("label_timescale_names"),
        label = i18n$tr("b_label_timescale_names"),
        value = isTRUE(params$label_timescale_names)
      ),
      shiny::checkboxInput(
        inputId = ns("grey_bars"),
        label = i18n$tr("b_grey_bars"),
        value = isTRUE(params$grey_bars)
      ),
      shiny::numericInput(
        inputId = ns("relative_height"),
        label = i18n$tr("b_relative_height"),
        value = params$relative_height,
        min = 0, max = 1, step = 0.01, width = "100%"
      ),
      shiny::numericInput(
        inputId = ns("cex_age"),
        label = i18n$tr("b_cex_age"),
        value = params$cex_age,
        min = 0, max = 5, step = 0.1, width = "100%"
      ),
      shiny::numericInput(
        inputId = ns("cex_labels"),
        label = i18n$tr("b_cex_labels"),
        value = params$cex_labels,
        min = 0, max = 5, step = 0.1, width = "100%"
      ),
      shiny::numericInput(
        inputId = ns("cex_names"),
        label = i18n$tr("b_cex_names"),
        value = params$cex_names,
        min = 0, max = 5, step = 0.1, width = "100%"
      ),
      shiny::checkboxInput(
        inputId = ns("pos_age_auto"),
        label = i18n$tr("b_pos_age_auto"),
        value = isTRUE(params$pos_age_auto)
      ),
      shiny::conditionalPanel(
        condition = sprintf("input['%s'] === false", ns("pos_age_auto")),
        shiny::numericInput(
          inputId = ns("pos_age"),
          label = i18n$tr("b_pos_age"),
          value = {
            pos <- params[["pos_age", exact = TRUE]]
            if (is.null(pos) || !is.finite(pos)) "" else pos
          },
          step = 1, width = "100%"
        )
      ),
      shiny::textInput(
        inputId = ns("abs_age_mgp"),
        label = i18n$tr("b_abs_age_mgp"),
        value = params$abs_age_mgp_raw,
        placeholder = "3, 0.35, 0",
        width = "100%"
      ),
      shiny::numericInput(
        inputId = ns("abs_age_lwd"),
        label = i18n$tr("b_abs_age_lwd"),
        value = params$abs_age_lwd,
        min = 0, max = 20, step = 0.1, width = "100%"
      ),
      shiny::numericInput(
        inputId = ns("abs_age_lwd_ticks"),
        label = i18n$tr("b_abs_age_lwd_ticks"),
        value = params$abs_age_lwd_ticks,
        min = 0, max = 20, step = 0.1, width = "100%"
      ),
      shiny::numericInput(
        inputId = ns("tck_abs_age"),
        label = i18n$tr("b_tck_abs_age"),
        value = params$tck_abs_age,
        min = -1, max = 1, step = 0.01, width = "100%"
      ),
      shiny::numericInput(
        inputId = ns("abs_age_line"),
        label = i18n$tr("b_abs_age_line"),
        value = params$abs_age_line,
        min = -10, max = 10, step = 0.1, width = "100%"
      )
    )
  )
}
