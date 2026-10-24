# On-disk limits tuned for a hosted Connect Cloud instance.

LIMITS <- list(
  max_upload_bytes = 50 * 1024^2,
  max_single_file_bytes = 50 * 1024^2,
  max_tree_tips = 3000L,
  max_tree_nodes = 6000L,
  max_posterior_rows = 200000L,
  max_object_mb = 500,
  max_pdf_width = 16,
  max_pdf_height = 12,
  max_png_width = 12,
  max_png_height = 9,
  max_png_dpi = 200,
  max_upload_mb = 50,
  manual_redraw_rows = 100000L,
  debounce_ms = 350
)

allowed_upload_extensions <- function() {
  c(
    ".tre", ".nwk", ".newick", ".nexus", ".nex", ".txt",
    ".tsv", ".csv", ".con.tre", ".run1.t", ".run2.t",
    ".run3.t", ".run4.t", ".trees"
  )
}

format_mb <- function(bytes) {
  round(as.numeric(bytes) / 1024^2, 2)
}

check_upload_files <- function(files) {
  if (is.null(files) || nrow(files) == 0) {
    return(list(ok = FALSE, key = "err_file_empty", args = list()))
  }
  sizes <- as.numeric(files$size %||% rep(0, nrow(files)))
  total <- sum(sizes, na.rm = TRUE)
  if (total > LIMITS$max_upload_bytes) {
    return(list(
      ok = FALSE, key = "err_upload_too_big",
      args = list(format_mb(total), LIMITS$max_upload_mb)
    ))
  }
  too_big <- which(sizes > LIMITS$max_single_file_bytes)
  if (length(too_big)) {
    i <- too_big[1]
    return(list(
      ok = FALSE, key = "err_file_too_big",
      args = list(files$name[i], format_mb(sizes[i]), LIMITS$max_upload_mb)
    ))
  }
  empty <- which(sizes <= 0)
  if (length(empty)) {
    return(list(ok = FALSE, key = "err_file_empty", args = list()))
  }
  list(ok = TRUE, key = NULL, args = list(), total = total)
}

check_tree_limits <- function(phy) {
  n_tip <- tryCatch(ape::Ntip(phy), error = function(e) NA_integer_)
  n_node <- tryCatch(ape::Nnode(phy), error = function(e) NA_integer_)
  if (is.na(n_tip) || is.na(n_node)) {
    return(list(ok = FALSE, key = "err_parse_tree", args = list()))
  }
  if (n_tip > LIMITS$max_tree_tips) {
    return(list(
      ok = FALSE, key = "err_tree_tips",
      args = list(n_tip, LIMITS$max_tree_tips)
    ))
  }
  if (n_node > LIMITS$max_tree_nodes) {
    return(list(
      ok = FALSE, key = "err_tree_nodes",
      args = list(n_node, LIMITS$max_tree_nodes)
    ))
  }
  list(ok = TRUE, key = NULL, args = list(), n_tip = n_tip, n_node = n_node)
}

check_posterior_limits <- function(chain) {
  n <- tryCatch(nrow(chain), error = function(e) 0L)
  if (n > LIMITS$max_posterior_rows) {
    return(list(
      ok = FALSE, key = "err_posterior_rows",
      args = list(n, LIMITS$max_posterior_rows)
    ))
  }
  list(ok = TRUE, key = NULL, args = list(), n_rows = n)
}

check_object_size <- function(object) {
  mb <- as.numeric(utils::object.size(object)) / 1024^2
  if (isTRUE(mb > LIMITS$max_object_mb)) {
    return(list(ok = FALSE, key = "err_object_size", args = list(), mb = mb))
  }
  list(ok = TRUE, key = NULL, args = list(), mb = mb)
}

check_pdf_size <- function(width, height) {
  if (!is.finite(width) || !is.finite(height) ||
      width <= 0 || height <= 0 ||
      width > LIMITS$max_pdf_width || height > LIMITS$max_pdf_height) {
    return(list(
      ok = FALSE, key = "err_image_size",
      args = list(
        LIMITS$max_pdf_width, LIMITS$max_pdf_height,
        LIMITS$max_png_width, LIMITS$max_png_height, LIMITS$max_png_dpi
      )
    ))
  }
  list(ok = TRUE, key = NULL, args = list())
}

check_png_size <- function(width, height, dpi) {
  if (!is.finite(width) || !is.finite(height) || !is.finite(dpi) ||
      width <= 0 || height <= 0 || dpi <= 0 ||
      width > LIMITS$max_png_width || height > LIMITS$max_png_height ||
      dpi > LIMITS$max_png_dpi) {
    return(list(
      ok = FALSE, key = "err_image_size",
      args = list(
        LIMITS$max_pdf_width, LIMITS$max_pdf_height,
        LIMITS$max_png_width, LIMITS$max_png_height, LIMITS$max_png_dpi
      )
    ))
  }
  list(ok = TRUE, key = NULL, args = list())
}
