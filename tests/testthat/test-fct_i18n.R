test_that("dictionaries have identical key sets and placeholders", {
  expect_length(check_translations(), 0)
  expect_identical(translation_keys("en"), translation_keys("zh"))
})

test_that("tr falls back to English and marks missing keys", {
  expect_identical(tr("en", "app_title"), "MCMCtreeR Bench")
  expect_identical(tr("zh", "app_title"), "MCMCtreeR Bench")
  expect_identical(tr("en", "does_not_exist"), "\u27e8does_not_exist\u27e9")
  expect_identical(tr("fr", "app_title"), "MCMCtreeR Bench")
  expect_identical(tr("en", "msg_node_added", 8), "Node 8 added to the calibration table.")
  expect_identical(tr("zh", "msg_node_added", 8), "节点 8 已加入标定表。")
})

test_that("language codes are normalised", {
  expect_identical(normalize_lang("zh-CN"), "zh")
  expect_identical(normalize_lang("zh-TW"), "zh")
  expect_identical(normalize_lang("en-GB"), "en")
  expect_identical(normalize_lang("fr"), "en")
  expect_identical(normalize_lang(NULL), "en")
})

test_that("every literal UI key exists in both dictionaries", {
  r_dir <- testthat::test_path("..", "..", "R")
  skip_if_not(dir.exists(r_dir), "source R directory is not available")
  files <- list.files(r_dir, pattern = "\\.R$", full.names = TRUE)
  text <- paste(unlist(lapply(files, readLines, warn = FALSE)), collapse = "\n")
  matches <- gregexpr('(?:i18n\\$)?tr\\("([A-Za-z0-9_]+)"', text, perl = TRUE)
  keys <- unique(gsub('.*tr\\("([A-Za-z0-9_]+)".*', "\\1", regmatches(text, matches)[[1]]))
  keys <- setdiff(keys[nzchar(keys)], c("en", "zh"))
  expect_gt(length(keys), 30)
  expect_setequal(setdiff(keys, translation_keys("en")), character())
})

test_that("distribution and advanced-parameter keys are present", {
  keys <- translation_keys("en")
  for (method in calibration_methods()) {
    expect_true(paste0("method_", method, "_desc") %in% keys)
  }
  for (method in calibration_methods()) {
    for (param in names(METHOD_SPECS[[method]]$params)) {
      expect_true(paste0("adv_param_", param) %in% keys)
      expect_true(paste0("adv_desc_", param) %in% keys)
    }
  }
})

test_that("language state is session-scoped", {
  testServer(mod_i18n_server, {
    expect_identical(lang(), "en")
    session$setInputs(browser_lang = "zh-CN")
    session$flushReact()
    expect_identical(lang(), "zh")
    session$setInputs(lang = "en")
    session$flushReact()
    expect_identical(lang(), "en")
  })

  # A second session must start in English even though the first one used zh.
  testServer(mod_i18n_server, {
    expect_identical(lang(), "en")
  })
})

test_that("saved language wins over browser language", {
  testServer(mod_i18n_server, {
    session$setInputs(lang_saved = "zh")
    session$flushReact()
    expect_identical(lang(), "zh")
    session$setInputs(browser_lang = "en-US")
    session$flushReact()
    expect_identical(lang(), "zh")
  })
})
