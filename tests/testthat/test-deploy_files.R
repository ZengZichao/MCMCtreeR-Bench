test_that("production entry point sets the required options", {
  root <- testthat::test_path("..", "..")
  app <- file.path(root, "app.R")
  skip_if_not(file.exists(app), "app.R is only present in the source tree")
  text <- paste(readLines(app, warn = FALSE), collapse = "\n")
  expect_true(grepl("pkgload::load_all", text, fixed = TRUE))
  expect_true(grepl("library(MCMCtreeR)", text, fixed = TRUE))
  expect_true(grepl("golem.app.prod", text, fixed = TRUE))
  expect_true(grepl("shiny.maxRequestSize", text, fixed = TRUE))
  expect_true(grepl("shiny.sanitize.errors", text, fixed = TRUE))
  expect_true(grepl("mcmctreer::run_app()", text, fixed = TRUE))
})

test_that("DESCRIPTION pins the upstream commit and declares pkgload", {
  root <- testthat::test_path("..", "..")
  desc_path <- system.file("DESCRIPTION", package = "mcmctreer")
  if (!nzchar(desc_path)) desc_path <- file.path(root, "DESCRIPTION")
  skip_if_not(file.exists(desc_path), "DESCRIPTION is not available")
  desc <- read.dcf(desc_path)
  expect_identical(unname(desc[1, "Version"]), "0.1.0")
  expect_true(grepl("pkgload", desc[1, "Imports"], fixed = TRUE))
  expect_true(grepl(UPSTREAM$commit, desc[1, "Remotes"], fixed = TRUE))
  expect_true(grepl("GPL", desc[1, "License"], fixed = TRUE))
})

test_that("deployment targets Posit Connect Cloud with the checked-in manifest", {
  root <- testthat::test_path("..", "..")
  script <- file.path(root, "dev", "deploy.R")
  skip_if_not(file.exists(script), "deploy script is only present in the source tree")
  text <- paste(readLines(script, warn = FALSE), collapse = "\n")
  expect_true(grepl("connect.posit.cloud", text, fixed = TRUE))
  expect_true(grepl("manifestPath", text, fixed = TRUE))
  expect_true(grepl("appVisibility", text, fixed = TRUE))
  expect_false(grepl("SHINYAPPS", text, fixed = TRUE))
})

test_that(".rscignore excludes repository-only files and keeps app files", {
  root <- testthat::test_path("..", "..")
  path <- file.path(root, ".rscignore")
  skip_if_not(file.exists(path), "source tree only")
  lines <- trimws(readLines(path, warn = FALSE))
  for (entry in c("dev", "tests", "man", "docs", "mkdocs.yml", ".github", ".Rprofile", "renv")) {
    expect_true(entry %in% lines, info = entry)
  }
  for (entry in c("app.R", "DESCRIPTION", "NAMESPACE", "R", "inst", "renv.lock", "manifest.json")) {
    expect_false(entry %in% lines, info = entry)
  }
})

test_that("deployment file list contains the runtime files", {
  root <- testthat::test_path("..", "..")
  skip_if_not(file.exists(file.path(root, "app.R")), "source tree only")
  skip_if_not_installed("rsconnect")
  files <- tryCatch(
    rsconnect::listDeploymentFiles(root),
    error = function(e) NULL
  )
  skip_if(is.null(files), "rsconnect could not compute the deployment list here")
  expect_true("app.R" %in% files)
  expect_true("DESCRIPTION" %in% files)
  expect_true("NAMESPACE" %in% files)
  expect_true(any(startsWith(files, "R/")))
  expect_true(any(startsWith(files, "inst/")))
  expect_false(any(startsWith(files, "docs/")))
  expect_false(any(startsWith(files, "tests/")))
  expect_false(any(startsWith(files, "dev/")))
})

test_that("CITATION files are consistent with DESCRIPTION", {
  root <- testthat::test_path("..", "..")
  cff_path <- file.path(root, "CITATION.cff")
  skip_if_not(file.exists(cff_path), "CITATION.cff is not shipped in this build")
  expect_true(file.exists(file.path(root, "inst", "CITATION")))
  cff <- paste(readLines(cff_path, warn = FALSE), collapse = "\n")
  expect_true(grepl("version: \"0.1.0\"", cff, fixed = TRUE))
  expect_true(grepl("0000-0001-6553-970X", cff, fixed = TRUE))
  expect_true(grepl(UPSTREAM$doi, cff, fixed = TRUE))
})

test_that("renv lock and manifest pin the upstream commit", {
  root <- testthat::test_path("..", "..")
  lock_path <- file.path(root, "renv.lock")
  manifest_path <- file.path(root, "manifest.json")
  skip_if_not(file.exists(lock_path), "renv.lock is not shipped in this build")
  skip_if_not_installed("jsonlite")

  lock <- jsonlite::fromJSON(lock_path, simplifyVector = FALSE)
  pkg <- lock$Packages$MCMCtreeR
  expect_identical(pkg$Source, "GitHub")
  expect_identical(pkg$RemoteType, "github")
  expect_identical(pkg$RemoteSha, UPSTREAM$commit)
  expect_true(all(c("ragg", "svglite") %in% names(lock$Packages)))

  if (file.exists(manifest_path)) {
    manifest <- jsonlite::fromJSON(manifest_path, simplifyVector = FALSE)
    expect_true(all(c("ragg", "svglite") %in% names(manifest$packages)))
    descs <- vapply(
      manifest$packages,
      function(p) paste(p$description, collapse = "\n"),
      character(1)
    )
    idx <- which(vapply(descs, function(d) grepl("^MCMCtreeR", d), logical(1)))
    expect_length(idx, 1)
    expect_identical(manifest$packages[[idx]]$Source, "github")
    expect_identical(manifest$packages[[idx]]$RemoteSha, UPSTREAM$commit)
  }
})
