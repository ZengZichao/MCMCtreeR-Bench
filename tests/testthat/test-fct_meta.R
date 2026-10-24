test_that("version and author metadata come from DESCRIPTION", {
  expect_identical(app_version(), "0.1.0")
  expect_identical(app_author_name(), "Zichao Zeng")
  expect_identical(app_email(), "zengzichao@sjtu.edu.cn")
  expect_identical(app_orcid(), "0000-0001-6553-970X")
  expect_identical(orcid_url(), "https://orcid.org/0000-0001-6553-970X")

  desc_version <- description_value("Version")
  expect_identical(app_version(), unname(desc_version))
})

test_that("citation text contains the GUI and upstream references", {
  gui <- gui_citation_text()
  expect_true(grepl("MCMCtreeR Bench", gui, fixed = TRUE))
  expect_true(grepl("0.1.0", gui, fixed = TRUE))
  expect_true(grepl("Zeng", gui, fixed = TRUE))

  upstream <- upstream_citation_text()
  expect_true(grepl("Puttick", upstream, fixed = TRUE))
  expect_true(grepl(UPSTREAM$doi, upstream, fixed = TRUE))
  expect_true(grepl("Bioinformatics", upstream, fixed = TRUE))
})

test_that("upstream commit and repository are pinned", {
  expect_identical(
    UPSTREAM$repo,
    "https://github.com/PuttickMacroevolution/MCMCtreeR"
  )
  expect_identical(
    UPSTREAM$commit,
    "2330e7a9916c3929513ee217d3854be993965f6b"
  )
  expect_true(grepl(UPSTREAM$commit, upstream_repo_text(), fixed = TRUE))
})

test_that("the local run command uses the pinned commit", {
  expect_true(grepl(UPSTREAM$commit, GUI_META$local_command, fixed = TRUE))
  expect_false(grepl("install.packages", GUI_META$local_command, fixed = TRUE))
})

test_that("production flag follows the golem option", {
  old <- getOption("golem.app.prod")
  on.exit(options(golem.app.prod = old), add = TRUE)
  options(golem.app.prod = TRUE)
  expect_true(app_prod())
  options(golem.app.prod = FALSE)
  expect_false(app_prod())
})
