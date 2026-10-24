# Map a click in the plot area to the nearest ape node.
#
# ape::plot.phylo() returns xx/yy coordinates in the order tips (1..Ntip)
# followed by internal nodes (Ntip+1..Ntip+Nnode). The returned index is
# therefore the ape node number. A normalised distance threshold prevents
# clicks in empty space from selecting a far-away node.

phylo_plot_points <- function(pp, n_tip) {
  if (is.null(pp) || is.null(pp$xx) || is.null(pp$yy)) {
    stop(app_error("err_no_tree"))
  }
  n <- length(pp$xx)
  if (length(pp$yy) != n || n < n_tip) {
    stop(app_error("err_no_tree"))
  }
  data.frame(
    index = seq_len(n),
    node = seq_len(n),
    is_tip = seq_len(n) <= n_tip,
    x = as.numeric(pp$xx),
    y = as.numeric(pp$yy),
    stringsAsFactors = FALSE
  )
}

nearest_phylo_node <- function(pp, x, y, n_tip, tol = 0.15) {
  points <- phylo_plot_points(pp, n_tip)
  x_range <- diff(range(points$x, finite = TRUE))
  y_range <- diff(range(points$y, finite = TRUE))
  if (!is.finite(x_range) || x_range <= 0) x_range <- 1
  if (!is.finite(y_range) || y_range <= 0) y_range <- 1
  nx <- (points$x - x) / x_range
  ny <- (points$y - y) / y_range
  distance <- sqrt(nx^2 + ny^2)
  index <- which.min(distance)

  if (!length(index) || !is.finite(distance[index]) || distance[index] > tol) {
    return(list(node = NULL, index = NA_integer_, is_tip = NA, distance = NA_real_))
  }
  list(
    node = as.integer(points$node[index]),
    index = as.integer(index),
    is_tip = isTRUE(points$is_tip[index]),
    distance = as.numeric(distance[index])
  )
}

calibration_node_choices <- function(phy) {
  n_tip <- ape::Ntip(phy)
  nodes <- (n_tip + 1):(n_tip + ape::Nnode(phy))
  stats::setNames(as.character(nodes), paste0("Node ", nodes))
}

toggle_node_selection <- function(selected, node) {
  node <- as.integer(node)
  if (node %in% as.integer(selected)) {
    list(selected = setdiff(as.integer(selected), node), added = FALSE)
  } else {
    list(selected = sort(unique(c(as.integer(selected), node))), added = TRUE)
  }
}

node_is_internal <- function(phy, node) {
  node <- as.integer(node)
  length(node) == 1 && is.finite(node) &&
    node > ape::Ntip(phy) &&
    node <= ape::Ntip(phy) + ape::Nnode(phy)
}
