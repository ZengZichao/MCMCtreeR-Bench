# Guards the presentation layer, which previously had no automated coverage at
# all: every rule below failed at some point and shipped because nothing in the
# suite executed CSS or looked at colour values.

css_text <- function() {
  path <- file.path("..", "..", "inst", "app", "www", "custom.css")
  if (!file.exists(path)) path <- system.file("app", "www", "custom.css", package = "mcmctreer")
  expect_true(file.exists(path), info = "custom.css must exist")
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

css_relative_luminance <- function(hex) {
  hex <- sub("^#", "", hex)
  ch <- as.integer(strtoi(substring(hex, c(1, 3, 5), c(2, 4, 6)), 16L)) / 255
  lin <- ifelse(ch <= 0.03928, ch / 12.92, ((ch + 0.055) / 1.055)^2.4)
  sum(c(0.2126, 0.7152, 0.0722) * lin)
}

css_contrast <- function(fg, bg) {
  l1 <- css_relative_luminance(fg)
  l2 <- css_relative_luminance(bg)
  (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
}

test_that("custom.css keeps the selectors the app actually emits", {
  css <- css_text()
  # Shiny still renders the Bootstrap 3 names (.navbar-toggle, .icon-bar), but
  # the Sass build rewrites every ".navbar-toggler" rule into
  # ".navbar-toggler, .navbar-toggle", so styling the modern name covers both and
  # the legacy selectors must not be hand-written a second time.
  expect_false(grepl("[^r]\\.navbar-toggle[ ,{:.]", css), info = "the build aliases .navbar-toggle for us")
  expect_false(grepl("\\.icon-bar", css), info = "bslib hides .icon-bar and paints the bars with ::before")
  expect_false(grepl("\\.navbar-collapse\\.in", css), info = "BS3 .navbar-collapse.in is dead")
  expect_false(grepl("\\.navbar-header\\b", css), info = "BS3 .navbar-header is dead")
  expect_false(grepl("\\.form-inline\\b", css), info = "BS3 .form-inline is dead")
  expect_true(grepl("\\.navbar-toggler\\b", css), info = "the real toggler must be styled")
})

test_that("notification rules out-specify bslib's doubled selectors", {
  css <- css_text()
  # bslib ships ".shiny-notification.shiny-notification" (specificity 0,2,0) and
  # ".shiny-notification.shiny-notification .shiny-notification-close" (0,3,0).
  # A single-class rule loses to those regardless of cascade order, which let
  # bslib's 2rem padding + 1.5rem margin widen each toast past the 340px panel
  # and grow a horizontal scrollbar underneath the message.
  expect_true(grepl("\\.shiny-notification\\.shiny-notification\\s*\\{", css),
    info = "the toast box rule must match bslib's doubled selector")
  expect_true(grepl("\\.shiny-notification\\.shiny-notification-error", css),
    info = "raising the base rule would otherwise swallow the error variant")
  expect_true(grepl("\\.shiny-notification\\.shiny-notification-warning", css),
    info = "raising the base rule would otherwise swallow the warning variant")
  expect_true(grepl("\\.shiny-notification\\.shiny-notification \\.shiny-notification-close", css),
    info = "the close button needs bslib's three-part selector")
  expect_match(css, "#shiny-notification-panel\\s*\\{[^}]*overflow-x:\\s*hidden",
    info = "overflow-y alone would compute overflow-x to auto")
})

test_that("the Module B rail is a bare card stack with no bslib chrome", {
  css <- css_text()
  src <- paste(readLines("../../R/mod_b_viz.R", warn = FALSE), collapse = "\n")
  # bslib gives its sidebar a chrome of its own through
  # `.bslib-sidebar-layout > .sidebar` (0,2,0): translucent fill, right-hand
  # hairline, square right corners. That is what made the rail a square box.
  sidebar <- regmatches(
    css,
    regexpr("\\.b-workbench \\.bslib-sidebar-layout > \\.b-sidebar\\s*\\{[^}]*\\}", css)
  )
  expect_true(nzchar(sidebar), info = "the rail reset must out-specify bslib")
  expect_match(sidebar, "border:\\s*0", info = "no hairline frame around the rail")
  expect_match(sidebar, "background:\\s*transparent", info = "no translucent sidebar fill")
  expect_false(grepl("b-sidebar-title", css), info = "the rail has no heading any more")
  expect_false(grepl("b-sidebar-title|sidebar_title", src), info = "and the UI emits none")
})

test_that("the Module B toolbar stays clear of the canvas", {
  css <- css_text()
  toolbar <- regmatches(css, regexpr("\\.b-toolbar-wrap\\s*\\{[^}]*\\}", css))
  expect_true(nzchar(toolbar))
  # .b-stage clips, so it is the toolbar's scroll container: a sticky `top`
  # pulled the bar down over the canvas even at scrollTop 0 and hid the top
  # edge and upper corners of the figure card.
  expect_false(grepl("position:\\s*sticky", toolbar), info = "sticky here overlaps the canvas")
  expect_match(toolbar, "flex:\\s*0 0 auto", info = "the bar is a plain row of the stage column")
})

test_that("the canvas centres overflow-safely and the placeholder is a well", {
  css <- css_text()
  canvas <- regmatches(css, regexpr("\\.b-canvas\\s*\\{[^}]*\\}", css))
  expect_true(nzchar(canvas))
  # Auto margins absorb the free space when the figure is short and collapse to
  # zero when it is tall, so it still scrolls from its own top edge.
  expect_match(canvas, "margin-block:\\s*auto", info = "centre without clipping")
  expect_false(grepl("align-self:\\s*center", canvas), info = "align-self clips a too-tall figure")
  expect_match(css, "\\.b-canvas\\.is-empty\\s*\\{[^}]*border:\\s*1px dashed",
    info = "an empty canvas is a well waiting for input, not a sheet of paper")
  expect_match(css, "\\[data-bs-theme=\"dark\"\\] \\.b-canvas\\.is-empty",
    info = "the well needs a dark variant")
})

test_that("the placeholder draws no text and brings no paper of its own", {
  theme <- readLines("../../R/fct_plot_theme.R", warn = FALSE)
  start <- grep("^plot_empty_state <- function", theme)
  expect_length(start, 1L)
  stop <- start + which(theme[start:length(theme)] == "}")[1] - 1L
  body <- paste(theme[start:stop], collapse = "\n")
  expect_false(grepl("graphics::text", body),
    info = "placeholder wording belongs in the DOM, where tr() can reach it")
  viz <- paste(readLines("../../R/mod_b_viz.R", warn = FALSE), collapse = "\n")
  expect_match(viz, "cols\\$bg\\s*<-\\s*NA",
    info = "an opaque raster background cuts a white band across the well")
})

test_that("dead hero variant is gone and no rule references an unused modifier", {
  css <- css_text()
  expect_false(grepl("hero--dark", css), info = ".hero--dark is never emitted")
})

test_that("the Shiny file button is pulled into the design system", {
  css <- css_text()
  # Shiny's fileInput renders a .btn-file span, not ::file-selector-button, and
  # Shiny's own sheet styles it at (0,3,0) so a bare .btn rule cannot win.
  expect_match(
    css,
    "\\.shiny-input-container \\.input-group \\.btn-file \\{[^}]*background: var\\(--app-",
    info = "the visible browse button must use app tokens"
  )
})

test_that("select carets have a dark-mode variant", {
  css <- css_text()
  expect_match(
    css,
    "\\[data-bs-theme=\"dark\"\\] select\\.form-control",
    info = "the caret is a data URI and cannot inherit a token"
  )
})

test_that("locked wizard steps stay readable instead of fading to half opacity", {
  css <- css_text()
  block <- regmatches(css, regexpr("\\.btn\\.step-btn\\.locked \\{[^}]*\\}", css))
  expect_gt(nchar(block), 0)
  expect_false(grepl("opacity: *0?\\.?[0-6]", block), info = "opacity on the whole button fails contrast")
  expect_match(block, "color: var\\(--app-muted\\)")
  expect_match(block, "background: var\\(--app-parchment\\)")
})

test_that("muted copy clears WCAG AA on the surfaces it sits on", {
  css <- css_text()
  light <- regmatches(css, regexpr(":root \\{[^}]*\\}", css))
  dark <- regmatches(css, regexpr("\\[data-bs-theme=\"dark\"\\] \\{[^}]*\\}", css))
  grab <- function(block, token) {
    hit <- regmatches(block, regexpr(paste0(token, ": *#[0-9a-fA-F]{3,6}"), block))
    sub(".*: *#", "#", hit)
  }
  for (block in list(light, dark)) {
    muted <- grab(block, "--app-muted")
    for (token in c("--app-card", "--app-parchment", "--app-field")) {
      surface <- grab(block, token)
      ratio <- css_contrast(muted, surface)
      expect_true(
        ratio >= 4.5,
        info = paste("muted", muted, "on", token, surface, "=", round(ratio, 2))
      )
    }
  }
})

test_that("motion and contrast preferences are both honoured", {
  css <- css_text()
  expect_match(css, "@media \\(prefers-reduced-motion: reduce\\)")
  expect_match(css, "@media \\(prefers-contrast: more\\)")
})

# Returns the concatenated text of every @media block matching a query, since
# the same breakpoint can appear in several places in the sheet.
css_media_blocks <- function(css, query) {
  m <- gregexpr(paste0("@media \\(", query, "\\) \\{[\\s\\S]*?\\n\\}"), css, perl = TRUE)[[1]]
  if (length(m) == 1 && m[1] == -1L) return("")
  starts <- as.integer(m)
  lens <- attr(m, "match.length")
  paste(substring(css, starts, starts + lens - 1L), collapse = "\n")
}

test_that("module B stacks its plot above its controls on small screens", {
  css <- css_text()
  block <- css_media_blocks(css, "max-width: 991\\.98px")
  expect_match(block, "\\.b-workbench \\.bslib-sidebar-layout > \\.main")
  expect_match(block, "grid-row: 1")
})

test_that("module B bounds its desktop layout so the settings rail scrolls alone", {
  css <- css_text()
  block <- css_media_blocks(css, "min-width: 992px")
  expect_true(nzchar(block), info = "the 992px module B block must exist")
  expect_match(block, "height: calc\\(100vh")
  expect_match(block, "overflow-y: auto")
})

test_that("!important stays within budget and no rule block is duplicated", {
  css <- css_text()
  # Shiny's stylesheet loads after the bslib theme, so a handful of overrides
  # genuinely need !important; the rest should be specificity. Cap the total so
  # it cannot creep back up.
  expect_lte(lengths(regmatches(css, gregexpr("!important", css))), 72)

  # Only top-level rules count as duplicates: the same declaration repeated
  # inside two different @media blocks is deliberate responsive design.
  chars <- strsplit(css, "")[[1]]
  depth <- 0L
  top <- character()
  buf <- ""
  i <- 1L
  n <- length(chars)
  while (i <= n) {
    ch <- chars[i]
    if (ch == "{") {
      depth <- depth + 1L
      if (depth == 1L && !grepl("@", buf)) {
        start <- i + 1L
        inner <- 1L
        j <- start
        while (j <= n && inner > 0) {
          if (chars[j] == "{") inner <- inner + 1L
          if (chars[j] == "}") inner <- inner - 1L
          j <- j + 1L
        }
        body <- paste(chars[start:(j - 2)], collapse = "")
        top <- c(top, paste0(trimws(buf), "{", body, "}"))
        buf <- ""
        i <- j
        depth <- depth - 1L
        next
      }
      buf <- paste0(buf, ch)
    } else if (ch == "}") {
      depth <- depth - 1L
      buf <- ""
    } else if (depth == 0L) {
      buf <- paste0(buf, ch)
    }
    i <- i + 1L
  }
  norm <- tolower(gsub("[[:space:]]+", " ", trimws(top)))
  norm <- norm[nzchar(norm)]
  dupes <- unique(norm[duplicated(norm)])
  expect_true(!length(dupes), info = paste(dupes, collapse = "\n"))
})

test_that("no UI string is drawn into a plot without going through tr()", {
  files <- list.files("../../R", pattern = "\\.R$", full.names = TRUE)
  offenders <- character()
  for (f in files) {
    lines <- readLines(f, warn = FALSE)
    hits <- grep("graphics::text\\(", lines, value = TRUE)
    literal <- hits[grepl("\"[^\"]+\"", hits)]
    bad <- literal[!grepl("tr\\(", literal)]
    if (length(bad)) {
      offenders <- c(offenders, paste(basename(f), trimws(bad), sep = ": "))
    }
  }
  expect_true(!length(offenders), info = paste(offenders, collapse = "\n"))
})

test_that("the calibration table exposes table semantics", {
  src <- paste(readLines("../../R/mod_a_calibration_table.R", warn = FALSE), collapse = "\n")
  expect_match(src, "class = \"calib-table\",\\s*role = \"table\"")
  expect_match(src, "role = \"columnheader\"")
  expect_match(src, "role = \"rowheader\"")
})
