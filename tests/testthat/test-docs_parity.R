test_that("bilingual documentation trees mirror each other", {
  root <- testthat::test_path("..", "..")
  skip_if_not(dir.exists(file.path(root, "docs")), "docs directory not available")
  en_dir <- file.path(root, "docs", "en")
  zh_dir <- file.path(root, "docs", "zh")
  expect_true(dir.exists(en_dir))
  expect_true(dir.exists(zh_dir))

  en <- sort(list.files(en_dir, recursive = TRUE, full.names = FALSE))
  zh <- sort(list.files(zh_dir, recursive = TRUE, full.names = FALSE))
  expect_identical(en, zh)

  for (relative in en) {
    en_lines <- readLines(file.path(en_dir, relative), warn = FALSE)
    zh_lines <- readLines(file.path(zh_dir, relative), warn = FALSE)

    en_heads <- grep("^#{1,2} ", en_lines, value = TRUE)
    zh_heads <- grep("^#{1,2} ", zh_lines, value = TRUE)
    expect_identical(length(en_heads), length(zh_heads), info = relative)

    en_fences <- grep("^```", en_lines, value = TRUE)
    zh_fences <- grep("^```", zh_lines, value = TRUE)
    expect_identical(en_fences, zh_fences, info = relative)

    expect_false(any(grepl("TODO|TBD|\u5f85\u8865|lorem ipsum", en_lines, ignore.case = TRUE)))
    expect_false(any(grepl("TODO|TBD|\u5f85\u8865|lorem ipsum", zh_lines, ignore.case = TRUE)))
  }
})

test_that("internal documentation links resolve", {
  root <- testthat::test_path("..", "..")
  skip_if_not(dir.exists(file.path(root, "docs")), "docs directory not available")
  for (lang in c("en", "zh")) {
    root_lang <- file.path(root, "docs", lang)
    files <- list.files(root_lang, recursive = TRUE, full.names = TRUE)
    for (file in files) {
      lines <- readLines(file, warn = FALSE)
      matches <- regmatches(lines, gregexpr("\\]\\(([^)#]+\\.md)\\)", lines))
      targets <- unlist(matches)
      targets <- gsub("^\\]\\(|\\)$", "", targets)
      for (target in targets) {
        if (grepl("^https?://", target) || grepl("^mailto:", target)) next
        expect_true(
          file.exists(file.path(dirname(file), target)),
          info = paste(file, "->", target)
        )
      }
    }
  }
})

test_that("README files carry the required sections", {
  root <- testthat::test_path("..", "..")
  skip_if_not(file.exists(file.path(root, "README.md")), "README not shipped in this build")
  for (file in file.path(root, c("README.md", "README.zh-CN.md"))) {
    expect_true(file.exists(file))
    text <- paste(readLines(file, warn = FALSE), collapse = "\n")
    expect_true(grepl(GUI_META$app_url, text, fixed = TRUE))
    expect_true(grepl("install_github", text, fixed = TRUE))
    expect_true(grepl("0.1.0", text, fixed = TRUE))
    expect_true(grepl("0000-0001-6553-970X", text, fixed = TRUE))
    expect_true(grepl("GPL", text, fixed = TRUE))
    expect_true(grepl("Privacy", text, ignore.case = TRUE))
    expect_true(grepl("Puttick", text, fixed = TRUE))
    expect_true(grepl("10.1093/bioinformatics/btz554", text, fixed = TRUE))
    expect_true(grepl("remotes::install_github", text, fixed = TRUE))
  }
})

test_that("mkdocs configuration is strict and bilingual", {
  root <- testthat::test_path("..", "..")
  config_path <- file.path(root, "mkdocs.yml")
  skip_if_not(file.exists(config_path), "mkdocs.yml is not shipped in this build")
  config <- paste(readLines(config_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("strict: true", config, fixed = TRUE))
  expect_true(grepl("i18n", config, fixed = TRUE))
  expect_true(dir.exists(file.path(root, "docs", "en")) &&
                dir.exists(file.path(root, "docs", "zh")))
})
