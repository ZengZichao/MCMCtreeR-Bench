# Step 4: optional advanced parameters, one card per calibrated node.
#
# Empty fields are omitted from the upstream call. This keeps GUI defaults and
# upstream defaults from drifting apart.

adv_input_id <- function(node, param) paste0("adv_", as.integer(node), "_", param)

step4_ui <- function(ns, i18n, a) {
  if (!length(a$calibrated)) {
    return(htmltools::tagList(
      htmltools::tags$div(
        class = "step-block",
        htmltools::tags$h4(i18n$tr("step4_title")),
        htmltools::tags$p(class = "step-hint", i18n$tr("step4_hint")),
        htmltools::tags$div(class = "alert alert-info app-alert", i18n$tr("a_need_nodes"))
      )
    ))
  }

  cards <- lapply(a$calibrated, function(one) {
    node <- as.integer(one$node)
    spec <- METHOD_SPECS[[one$method]]
    raw_values <- one$adv_raw %||% list()
    params <- if (is.null(spec)) list() else spec$params

    fields <- if (!length(params)) {
      htmltools::tags$p(class = "form-hint", i18n$tr("adv_none"))
    } else {
      lapply(names(params), function(param) {
        info <- params[[param]]
        raw <- as.character(raw_values[[param]] %||% "")[1]
        label <- i18n$tr(paste0("adv_param_", param))
        help <- i18n$tr(paste0("adv_desc_", param))
        default_text <- i18n$tr(
          "adv_default_placeholder",
          as.character(info$default)
        )
        input <- if (identical(info$type, "logical")) {
          shiny::selectInput(
            inputId = ns(adv_input_id(node, param)),
            label = label,
            choices = stats::setNames(
              c("", "TRUE", "FALSE"),
              c(i18n$tr("adv_use_default"), "TRUE", "FALSE")
            ),
            selected = if (raw %in% c("TRUE", "FALSE")) raw else "",
            width = "100%",
            selectize = FALSE
          )
        } else {
          shiny::textInput(
            inputId = ns(adv_input_id(node, param)),
            label = label,
            value = raw,
            placeholder = default_text,
            width = "100%"
          )
        }
        htmltools::tags$div(
          class = "adv-field",
          input,
          htmltools::tags$p(class = "form-hint", help),
          shiny::uiOutput(ns(paste0("adv_status_", node, "_", param)))
        )
      })
    }

    htmltools::tags$div(
      class = "adv-card",
      htmltools::tags$div(
        class = "adv-card-head",
        htmltools::tags$h5(i18n$tr("adv_for_node", node, one$method)),
        htmltools::tags$p(class = "form-hint", i18n$tr(paste0("method_", one$method, "_desc")))
      ),
      if (identical(one$method, "gamma")) {
        htmltools::tags$p(class = "form-hint", i18n$tr("estimate_gamma_note"))
      },
      htmltools::tags$div(class = "adv-grid", fields)
    )
  })

  htmltools::tagList(
    htmltools::tags$div(
      class = "step-block",
      htmltools::tags$h4(i18n$tr("step4_title")),
      htmltools::tags$p(class = "step-hint", i18n$tr("step4_hint")),
      cards
    )
  )
}

mod_a_advanced_params_server <- function(input, output, session, ns, state,
                                         set_a, i18n) {
  shiny::observeEvent(
    {
      calibrated <- state$a$calibrated
      lapply(calibrated, function(one) {
        spec <- METHOD_SPECS[[one$method]]
        params <- if (is.null(spec)) character() else names(spec$params)
        lapply(params, function(param) input[[adv_input_id(one$node, param)]])
      })
    },
    {
      calibrated <- state$a$calibrated
      if (!length(calibrated)) return()
      changed <- FALSE
      new_cal <- calibrated

      for (i in seq_along(calibrated)) {
        node <- as.integer(calibrated[[i]]$node)
        spec <- METHOD_SPECS[[new_cal[[i]]$method]]
        params <- if (is.null(spec)) character() else names(spec$params)
        values <- lapply(params, function(param) input[[adv_input_id(node, param)]])
        if (!length(values) || all(vapply(values, is.null, logical(1)))) next
        raw <- list()
        for (j in seq_along(params)) {
          value <- values[[j]]
          if (is.null(value)) next
          value <- as.character(value)[1]
          if (is.na(value) || !nzchar(value)) next
          raw[[params[j]]] <- value
        }
        old <- new_cal[[i]]$adv_raw %||% list()
        if (!identical(sort_named_list(old), sort_named_list(raw))) {
          new_cal[[i]]$adv_raw <- raw
          new_cal[[i]]$adv <- parse_adv_raw(new_cal[[i]]$method, raw)$values
          changed <- TRUE
        }
      }

      if (changed) {
        a <- state$a
        a$calibrated <- new_cal
        set_a(a)
      }
    },
    ignoreNULL = FALSE
  )

  shiny::observe({
    calibrated <- state$a$calibrated
    for (one in calibrated) {
      spec <- METHOD_SPECS[[one$method]]
      params <- if (is.null(spec)) character() else names(spec$params)
      for (param in params) {
        local({
          node <- as.integer(one$node)
          param_local <- param
          output[[paste0("adv_status_", node, "_", param_local)]] <- shiny::renderUI({
            current <- state$a$calibrated
            idx <- which(vapply(current, function(x) identical(as.integer(x$node), node), logical(1)))
            if (!length(idx)) return(NULL)
            errors <- adv_field_issues(current[[idx]])
            if (param_local %in% names(errors)) {
              return(htmltools::tags$span(
                class = "status-bad",
                i18n$tr(errors[[param_local]], node, param_local)
              ))
            }
            raw <- current[[idx]]$adv_raw[[param_local]] %||% ""
            if (nzchar(as.character(raw)[1])) {
              return(htmltools::tags$span(class = "status-ok", i18n$tr("valid")))
            }
            NULL
          })
        })
      }
    }
  })
}
