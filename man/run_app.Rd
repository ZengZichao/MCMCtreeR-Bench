\name{run_app}
\alias{run_app}
\title{Launch MCMCtreeR Bench}
\description{
Starts the bilingual Shiny application for preparing MCMCtree time priors and
visualising time-calibrated phylogenies.
}
\usage{
run_app(onStart = NULL, options = list(), enableBookmarking = "disable",
        uiPattern = "/", ...)
}
\arguments{
  \item{onStart}{Optional function passed to \code{shiny::shinyApp()}.}
  \item{options}{Named list of Shiny application options.}
  \item{enableBookmarking}{Bookmarking mode passed to \code{shiny::shinyApp()}.}
  \item{uiPattern}{UI pattern passed to \code{shiny::shinyApp()}.}
  \item{...}{Additional golem options.}
}
\value{
An object returned by \code{shiny::shinyApp()}, or the value returned by
\code{shiny::runApp()} when the application is launched.
}
\details{
The application requires the \pkg{MCMCtreeR} package. See the README for the
pinned upstream installation command.
}
\examples{
\dontrun{
mcmctreer::run_app()
}
}
