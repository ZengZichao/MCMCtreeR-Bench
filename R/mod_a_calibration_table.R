# Step 3: calibration table with distribution type and age bounds.

calib_hidden_label <- function(text) {
  htmltools::tags$span(class = "visually-hidden", text)
}

calib_disabled_wrap <- function(disabled, input) {
  htmltools::tags$div(
    class = if (isTRUE(disabled)) "calib-field is-disabled" else "calib-field",
    inert = if (isTRUE(disabled)) "" else NULL,
    input
  )
}

step3_ui <- function(ns, i18n, a) {
  if (!length(a$calibrated)) {
    return(htmltools::tagList(
      htmltools::tags$div(
        class = "step-block",
        htmltools::tags$h4(i18n$tr("step3_title")),
        htmltools::tags$p(class = "step-hint", i18n$tr("step3_hint")),
        htmltools::tags$div(class = "alert alert-info app-alert", i18n$tr("a_need_nodes"))
      )
    ))
  }

  rows <- lapply(a$calibrated, function(one) {
    node <- as.integer(one$node)
    spec <- METHOD_SPECS[[one$method]] %||% METHOD_SPECS$cauchy
    min_disabled <- !isTRUE(spec$min)
    max_disabled <- !isTRUE(spec$max)

    htmltools::tags$div(
      class = "calib-row",
      htmltools::tags$div(
        class = "calib-cell calib-node",
        htmltools::tags$strong(paste0("N", node)),
        htmltools::tags$small(
          class = "calib-tip-count",
          i18n$tr("selected_tips_count", length(one$tips))
        )
      ),
      htmltools::tags$div(
        class = "calib-cell",
        shiny::selectInput(
          inputId = ns(paste0("method_", node)),
          label = calib_hidden_label(i18n$tr("calib_col_method")),
          choices = calibration_method_labels(),
          selected = one$method,
          width = "100%",
          selectize = FALSE
        )
      ),
      htmltools::tags$div(
        class = "calib-cell",
        calib_disabled_wrap(
          min_disabled,
          shiny::numericInput(
            inputId = ns(paste0("min_", node)),
            label = calib_hidden_label(i18n$tr("calib_col_min")),
            value = if (missing_num(one$minAge)) "" else as.numeric(one$minAge),
            min = 0,
            step = 0.1,
            width = "100%"
          )
        )
      ),
      htmltools::tags$div(
        class = "calib-cell",
        calib_disabled_wrap(
          max_disabled,
          shiny::numericInput(
            inputId = ns(paste0("max_", node)),
            label = calib_hidden_label(i18n$tr("calib_col_max")),
            value = if (missing_num(one$maxAge)) "" else as.numeric(one$maxAge),
            min = 0,
            step = 0.1,
            width = "100%"
          )
        )
      ),
      htmltools::tags$div(
        class = "calib-cell calib-status",
        shiny::uiOutput(ns(paste0("calib_status_", node)))
      )
    )
  })

  htmltools::tagList(
    htmltools::tags$div(
      class = "step-block",
      htmltools::tags$h4(i18n$tr("step3_title")),
      htmltools::tags$p(class = "step-hint", i18n$tr("step3_hint")),
      shiny::uiOutput(ns("calib_summary")),
      htmltools::tags$div(
        class = "calib-table",
        htmltools::tags$div(
          class = "calib-header",
          htmltools::tags$div(class = "calib-cell", i18n$tr("calib_col_node")),
          htmltools::tags$div(class = "calib-cell", i18n$tr("calib_col_method")),
          htmltools::tags$div(class = "calib-cell", i18n$tr("calib_col_min")),
          htmltools::tags$div(class = "calib-cell", i18n$tr("calib_col_max")),
          htmltools::tags$div(class = "calib-cell", i18n$tr("calib_col_status"))
        ),
        rows
      ),
      htmltools::tags$p(class = "form-hint", i18n$tr("step3_age_hint"))
    )
  )
}

coerce_age_input <- function(value) {
  if (is.null(value)) return(NULL)
  value <- suppressWarnings(as.numeric(value))
  if (!length(value)) return(NA_real_)
  if (!is.finite(value)) NA_real_ else as.numeric(value)
}

mod_a_calibration_table_server <- function(input, output, session, ns, state,
                                           set_a, bump, i18n) {
  shiny::observeEvent(
    {
      calibrated <- state$a$calibrated
      lapply(calibrated, function(one) {
        list(
          method = input[[paste0("method_", one$node)]],
          min = input[[paste0("min_", one$node)]],
          max = input[[paste0("max_", one$node)]]
        )
      })
    },
    {
      calibrated <- state$a$calibrated
      if (!length(calibrated)) return()
      changed <- FALSE
      method_changed <- FALSE
      new_cal <- calibrated

      for (i in seq_along(calibrated)) {
        node <- as.integer(calibrated[[i]]$node)
        method_in <- input[[paste0("method_", node)]]
        min_in <- input[[paste0("min_", node)]]
        max_in <- input[[paste0("max_", node)]]
        if (is.null(method_in) && is.null(min_in) && is.null(max_in)) next
        if (!is.null(method_in) && method_in %in% names(METHOD_SPECS) &&
            !identical(method_in, new_cal[[i]]$method)) {
          new_cal <- update_calibration(new_cal, node, method = method_in)
          changed <- TRUE
          method_changed <- TRUE
        }

        spec <- METHOD_SPECS[[new_cal[[i]]$method]]
        if (is.null(spec)) next

        if (isTRUE(spec$min)) {
          value <- coerce_age_input(min_in)
          if (!is.null(value) &&
              !identical(as.numeric(new_cal[[i]]$minAge), as.numeric(value))) {
            new_cal[[i]]$minAge <- value
            changed <- TRUE
          }
        } else if (!missing_num(new_cal[[i]]$minAge)) {
          new_cal[[i]]$minAge <- NA_real_
          changed <- TRUE
        }

        if (isTRUE(spec$max)) {
          value <- coerce_age_input(max_in)
          if (!is.null(value) &&
              !identical(as.numeric(new_cal[[i]]$maxAge), as.numeric(value))) {
            new_cal[[i]]$maxAge <- value
            changed <- TRUE
          }
        } else if (!missing_num(new_cal[[i]]$maxAge)) {
          new_cal[[i]]$maxAge <- NA_real_
          changed <- TRUE
        }
      }

      if (changed) {
        a <- state$a
        a$calibrated <- new_cal
        set_a(a)
        if (method_changed) bump()
      }
    },
    ignoreNULL = FALSE
  )

  shiny::observe({
    calibrated <- state$a$calibrated
    for (one in calibrated) {
      local({
        node <- as.integer(one$node)
        output[[paste0("calib_status_", node)]] <- shiny::renderUI({
          current <- state$a$calibrated
          idx <- which(vapply(current, function(x) identical(as.integer(x$node), node), logical(1)))
          if (!length(idx)) return(NULL)
          issues <- calibration_issues(list(current[[idx]]), include_adv = FALSE)
          if (!length(issues)) {
            return(htmltools::tags$span(class = "status-ok", i18n$tr("valid")))
          }
          htmltools::tags$span(
            class = "status-bad",
            issue_text(issues[[1]], i18n)
          )
        })
      })
    }
  })

  output$calib_summary <- shiny::renderUI({
    calibrated <- state$a$calibrated
    if (!length(calibrated)) return(NULL)
    issues <- calibration_issues(calibrated, include_adv = FALSE)
    if (!length(issues)) {
      return(htmltools::tags$div(
        class = "alert alert-success app-alert", role = "status",
        i18n$tr("calib_complete")
      ))
    }
    shown <- utils::head(issues, 5)
    htmltools::tags$div(
      class = "alert alert-warning app-alert", role = "alert",
      htmltools::tags$ul(
        lapply(shown, function(issue) htmltools::tags$li(issue_text(issue, i18n)))
      ),
      if (length(issues) > length(shown)) {
        htmltools::tags$p(class = "form-hint", paste0("+", length(issues) - length(shown)))
      }
    )
  })
}
