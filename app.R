# Production entry point generated in the style of a golem deployment file.
# Keep business logic out of this file: it only loads the package, sets the
# platform options that must exist before the app starts, and launches the app.

pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
library(MCMCtreeR)

options("golem.app.prod" = TRUE)
options(shiny.maxRequestSize = 50 * 1024^2)
options(shiny.sanitize.errors = TRUE)

mcmctreer::run_app()
