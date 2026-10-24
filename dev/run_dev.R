# Development launcher.
#
# Usage:
#   Rscript dev/run_dev.R

pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
options(shiny.maxRequestSize = 50 * 1024^2)
options("golem.app.prod" = FALSE)
mcmctreer::run_app()
