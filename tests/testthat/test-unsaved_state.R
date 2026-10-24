test_that("an untouched session has no unsaved state", {
  expect_false(has_unsaved_state(list(), list()))
  expect_false(has_unsaved_state(NULL, NULL))
  expect_false(has_unsaved_state(list(tree_paste_text = ""), list(data_ready = FALSE)))
})

test_that("module A inputs mark the session as unsaved", {
  expect_true(has_unsaved_state(list(phy = structure(list(), class = "phylo")), list()))
  expect_true(has_unsaved_state(list(tree_paste_text = "((A,B),C);"), list()))
  expect_true(has_unsaved_state(
    list(calibrated = list(list(node = 4L, method = "cauchy"))),
    list()
  ))
})

test_that("module B inputs mark the session as unsaved", {
  expect_true(has_unsaved_state(list(), list(phy = structure(list(), class = "phylo"))))
  expect_true(has_unsaved_state(list(), list(chain = data.frame(x = 1))))
  expect_true(has_unsaved_state(list(), list(node_ages = data.frame(node = 4, age = 1))))
  expect_true(has_unsaved_state(list(), list(directory.files = c("tree.txt"))))
})
