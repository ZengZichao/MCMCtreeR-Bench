# Wrapper around tipDes() that always returns a list of character vectors.
#
# Upstream tipDes(phy, one_node) returns a character vector, while
# tipDes(phy, several_nodes) returns a list. MCMCtreePhy and nodeToPhy
# require a list whose length matches the number of calibrated nodes.

build_mono_groups <- function(phy, nodes) {
  if (is.null(phy)) stop(app_error("err_no_tree"))
  nodes <- as.integer(nodes)
  if (!length(nodes)) stop(app_error("err_no_nodes"))
  n_tip <- ape::Ntip(phy)
  max_node <- n_tip + ape::Nnode(phy)
  bad <- nodes[nodes <= n_tip | nodes > max_node | is.na(nodes)]
  if (length(bad)) {
    stop(app_error("err_invalid_node", paste(bad, collapse = ", ")))
  }

  groups <- lapply(nodes, function(node) {
    tips <- MCMCtreeR::tipDes(phy, node)
    as.character(unlist(tips, use.names = FALSE))
  })
  names(groups) <- as.character(nodes)
  groups
}

tip_des_safe <- function(phy, node) {
  if (!node_is_internal(phy, node)) {
    stop(app_error("err_invalid_node", node))
  }
  as.character(unlist(MCMCtreeR::tipDes(phy, as.integer(node)), use.names = FALSE))
}
