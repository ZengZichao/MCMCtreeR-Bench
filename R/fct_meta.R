# Single sources for version, author, licensing and citation metadata.
#
# The package version is read from DESCRIPTION (or packageVersion when the
# package is installed). Other metadata is read from Authors@R when possible
# and falls back to the constants below. Tests assert consistency with
# DESCRIPTION, CITATION.cff and inst/CITATION.

UPSTREAM <- list(
  package = "MCMCtreeR",
  author = "Mark N. Puttick",
  contributor = "Pascal Title",
  repo = "https://github.com/PuttickMacroevolution/MCMCtreeR",
  commit = "2330e7a9916c3929513ee217d3854be993965f6b",
  cran_archive = "https://cran.r-project.org/src/contrib/Archive/MCMCtreeR/",
  paper = "MCMCtreeR: functions to prepare MCMCtree analyses and visualize posterior ages on trees",
  journal = "Bioinformatics",
  year = 2019,
  volume = 35,
  issue = 24,
  pages = "5321--5322",
  doi = "10.1093/bioinformatics/btz554"
)

GUI_META <- list(
  name = "MCMCtreeR Bench",
  author = "Zichao Zeng",
  author_cn = "\u66fe\u5b50\u8d85",
  email = "zengzichao@sjtu.edu.cn",
  orcid = "0000-0001-6553-970X",
  orcid_url = "https://orcid.org/0000-0001-6553-970X",
  license = "GPL-2.0-or-later",
  repo = "https://github.com/ZengZichao/MCMCtreeR-Bench",
  app_url = "https://zengzichao-mcmctreer-bench.share.connect.posit.cloud/",
  local_command = paste(
    "remotes::install_github(\"PuttickMacroevolution/MCMCtreeR@2330e7a9916c3929513ee217d3854be993965f6b\", build_vignettes = FALSE)",
    "remotes::install_github(\"ZengZichao/MCMCtreeR-Bench\")",
    "mcmctreer::run_app()",
    sep = "\n"
  )
)

description_path <- function() {
  candidates <- c(
    tryCatch(system.file("DESCRIPTION", package = "mcmctreer"), error = function(e) ""),
    file.path(getwd(), "DESCRIPTION"),
    file.path(getwd(), "..", "DESCRIPTION")
  )
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (!length(candidates)) return(NULL)
  normalizePath(candidates[1], mustWork = FALSE)
}

description_value <- function(field) {
  path <- description_path()
  if (is.null(path)) return(NA_character_)
  value <- tryCatch(read.dcf(path, fields = field)[1, 1], error = function(e) NA_character_)
  if (is.na(value)) NA_character_ else value
}

app_version <- function() {
  version <- tryCatch(
    as.character(utils::packageVersion("mcmctreer")),
    error = function(e) NA_character_
  )
  if (is.na(version) || !nzchar(version)) {
    version <- description_value("Version")
  }
  if (is.na(version) || !nzchar(version)) "unknown" else version
}

app_authors <- function() {
  raw <- description_value("Authors@R")
  if (is.na(raw) || !nzchar(raw)) return(NULL)
  parsed <- tryCatch(
    eval(parse(text = raw)[[1]], envir = list(person = utils::person)),
    error = function(e) NULL
  )
  if (is.null(parsed)) return(NULL)
  if (inherits(parsed, "person")) return(parsed)
  if (is.list(parsed) && length(parsed) && inherits(parsed[[1]], "person")) {
    do.call(c, parsed)
  } else {
    NULL
  }
}

app_author_name <- function(fallback = GUI_META$author) {
  authors <- app_authors()
  if (is.null(authors) || !length(authors)) return(fallback)
  paste(authors[[1]]$given, authors[[1]]$family)
}

app_email <- function(fallback = GUI_META$email) {
  authors <- app_authors()
  if (is.null(authors) || !length(authors)) return(fallback)
  authors[[1]]$email %||% fallback
}

app_orcid <- function(fallback = GUI_META$orcid) {
  authors <- app_authors()
  if (is.null(authors) || !length(authors)) return(fallback)
  orcid <- authors[[1]]$comment[["ORCID"]] %||% fallback
  as.character(orcid)
}

orcid_url <- function() {
  paste0("https://orcid.org/", app_orcid())
}

app_prod <- function() {
  isTRUE(getOption("golem.app.prod", FALSE))
}

gui_citation_text <- function() {
  paste0(
    "Zeng, Z. (2026). MCMCtreeR Bench (version ", app_version(), "). ",
    "R package. ", GUI_META$repo
  )
}

upstream_citation_text <- function() {
  paste0(
    "Puttick, M. N. (2019). MCMCtreeR: functions to prepare MCMCtree analyses ",
    "and visualize posterior ages on trees. Bioinformatics, 35(24), ",
    "5321-5322. https://doi.org/", UPSTREAM$doi
  )
}

upstream_repo_text <- function() {
  paste0(UPSTREAM$repo, " @ ", UPSTREAM$commit)
}
