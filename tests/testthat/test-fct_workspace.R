test_that("session workspaces are isolated", {
  root <- tempfile("wsroot-")
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE, force = TRUE), add = TRUE)

  ws1 <- session_workspace(NULL, "a", root = root, token = "tok1")
  ws2 <- session_workspace(NULL, "a", root = root, token = "tok2")
  expect_false(identical(ws1, ws2))
  expect_true(dir.exists(ws1))
  expect_true(dir.exists(ws2))

  expect_identical(basename(dirname(ws1)), "tok1")
  expect_identical(basename(ws1), "a")
})

test_that("upload names are sanitised and extensions checked", {
  expect_identical(safe_upload_name("a/b.txt"), "b.txt")
  expect_identical(safe_upload_name("tree.nwk"), "tree.nwk")
  expect_app_error(safe_upload_name(".."), "err_bad_filename")
  expect_app_error(safe_upload_name("bad\u0001name"), "err_bad_filename")

  expect_true(has_allowed_extension("sample.con.tre"))
  expect_true(has_allowed_extension("sample.run1.t"))
  expect_true(has_allowed_extension("tree.NWK"))
  expect_false(has_allowed_extension("archive.zip"))

  names <- c("a.con.tre", "b.conXtre", "run1.t")
  expect_identical(require_literal_suffix(names, ".con.tre"), "a.con.tre")
})

test_that("staging preserves original names and file contents", {
  root <- tempfile("wsroot-")
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE, force = TRUE), add = TRUE)
  ws <- session_workspace(NULL, "uploads", root = root, token = "tok")

  p1 <- tempfile(fileext = ".con.tre")
  p2 <- tempfile(fileext = ".run1.t")
  writeLines("tree-one", p1)
  writeLines("run-one", p2)
  files <- make_upload_df(c(p1, p2), c("sample.con.tre", "sample.run1.t"))

  staged <- stage_uploaded_files(files, ws)
  expect_identical(staged$name, c("sample.con.tre", "sample.run1.t"))
  expect_true(all(file.exists(staged$path)))
  expect_identical(readLines(staged$path[1]), "tree-one")
  expect_identical(readLines(staged$path[2]), "run-one")

  bad <- make_upload_df(p1, "archive.zip")
  expect_app_error(stage_uploaded_files(bad, ws), "err_bad_extension")
})

test_that("workspace path assertions reject escapes", {
  root <- tempfile("wsroot-")
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE, force = TRUE), add = TRUE)
  ws <- session_workspace(NULL, "uploads", root = root, token = "tok")

  inside <- file.path(ws, "inside.txt")
  writeLines("ok", inside)
  outside <- file.path(root, "outside.txt")
  writeLines("no", outside)

  expect_identical(assert_in_workspace(inside, ws), normalizePath(inside))
  expect_app_error(assert_in_workspace(outside, ws), "err_path_outside")
})

test_that("session cleanup removes the token directory", {
  root <- tempfile("wsroot-")
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE, force = TRUE), add = TRUE)
  ws <- session_workspace(NULL, "uploads", root = root, token = "tok")
  writeLines("x", file.path(ws, "x.txt"))
  expect_true(clean_session_workspace(NULL, root = root, token = "tok"))
  expect_false(dir.exists(file.path(root, "tok")))
})

test_that("text files are written as UTF-8", {
  path <- tempfile(fileext = ".tre")
  write_text_file(path, "hello \u4e16\u754c")
  expect_identical(readLines(path, encoding = "UTF-8"), "hello \u4e16\u754c")
})
