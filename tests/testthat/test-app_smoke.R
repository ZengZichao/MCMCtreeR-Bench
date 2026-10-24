test_that("module A completes the example workflow", {
  skip_if_not_installed("MCMCtreeR")
  testServer(app_server, {
    session$setInputs(`a-load_mode` = "example", `a-load_tree` = 1)
    session$flushReact()
    report <- paste(
      htmltools::renderTags(output[["a-tree_report"]])$html,
      collapse = ""
    )
    expect_true(grepl("7", report, fixed = TRUE))

    session$setInputs(`a-manual_node` = "8", `a-add_node` = 1)
    session$flushReact()
    session$setInputs(`a-method_8` = "cauchy", `a-min_8` = 1.5, `a-max_8` = 3)
    session$flushReact()

    session$setInputs(`a-go_step_3` = 1)
    session$flushReact()
    session$setInputs(`i18n-lang` = "zh")
    session$flushReact()
    step3 <- paste(
      htmltools::renderTags(output[["a-step_content"]])$html,
      collapse = ""
    )
    expect_true(grepl("value=\"1.5\"", step3, fixed = TRUE))
    expect_true(grepl("\u6807\u5b9a", step3))

    session$setInputs(`i18n-lang` = "en")
    session$flushReact()
    session$setInputs(`a-go_step_5` = 1)
    session$flushReact()
    session$setInputs(`a-run_estimation` = 1)
    session$flushReact()
    results <- paste(
      htmltools::renderTags(output[["a-estimate_results"]])$html,
      collapse = ""
    )
    expect_true(grepl("Node 8", results, fixed = TRUE))
    expect_true(grepl("cauchy", results, fixed = TRUE))

    session$setInputs(`a-go_step_6` = 1)
    session$flushReact()
    actions <- paste(
      htmltools::renderTags(output[["a-export_actions"]])$html,
      collapse = ""
    )
    expect_true(grepl("a-download_tre", actions, fixed = TRUE))
    tre <- paste(
      htmltools::renderTags(output[["a-tre_preview"]])$html,
      collapse = ""
    )
    expect_true(grepl("L", tre, fixed = TRUE))

    session$setInputs(`a-min_8` = 2)
    session$flushReact()
    stale <- paste(
      htmltools::renderTags(output[["a-export_stale"]])$html,
      collapse = ""
    )
    expect_true(nzchar(stale))
  })
})

test_that("module B loads a FigTree source", {
  skip_if_not_installed("MCMCtreeR")
  output <- load_mcmctree_output()
  path <- tempfile(fileext = ".tre")
  on.exit(unlink(path), add = TRUE)
  writeLines(paste(output$MCMCtree.phy, collapse = "\t"), path)
  files <- make_upload_df(path, "figtree.tre")

  testServer(app_server, {
    session$setInputs(
      `b-analysis_type` = "MCMCtree",
      `b-source_mode` = "figtree",
      `b-figtree_file` = files
    )
    session$flushReact()
    session$setInputs(`b-parse_source` = 1)
    session$flushReact()

    status <- paste(
      htmltools::renderTags(output[["b-plot_status"]])$html,
      collapse = ""
    )
    expect_false(grepl("alert-danger", status, fixed = TRUE))

    actions <- paste(
      htmltools::renderTags(output[["b-export_actions"]])$html,
      collapse = ""
    )
    expect_true(grepl("b-download_plot", actions, fixed = TRUE))
  })
})

test_that("language switches preserve module A calibration values", {
  testServer(app_server, {
    session$setInputs(`a-load_mode` = "example", `a-load_tree` = 1)
    session$flushReact()
    session$setInputs(`a-manual_node` = "8", `a-add_node` = 1)
    session$flushReact()
    session$setInputs(`a-method_8` = "skewT", `a-min_8` = 1.25, `a-max_8` = 2.75)
    session$flushReact()

    session$setInputs(`a-go_step_3` = 1)
    session$flushReact()
    en <- paste(htmltools::renderTags(output[["a-step_content"]])$html, collapse = "")
    expect_true(grepl("skewT", en, fixed = TRUE))
    expect_true(grepl("value=\"1.25\"", en, fixed = TRUE))

    session$setInputs(`i18n-lang` = "zh")
    session$flushReact()
    zh <- paste(htmltools::renderTags(output[["a-step_content"]])$html, collapse = "")
    expect_true(grepl("skewT", zh, fixed = TRUE))
    expect_true(grepl("value=\"1.25\"", zh, fixed = TRUE))
  })
})
