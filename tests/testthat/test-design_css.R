# Guards the presentation layer: the interface is an editorial workbench built
# on Radix UI Colors, hairline rules and a three-size type scale. These checks
# keep that system from drifting back to rounded cards, shadows and ad-hoc
# colours.

css_text <- function() {
  path <- ""
  root <- pkg_source_root()
  if (!is.na(root)) {
    path <- file.path(root, "inst", "app", "www", "custom.css")
  }
  if (!nzchar(path) || !file.exists(path)) {
    path <- system.file("app", "www", "custom.css", package = "mcmctreer")
  }
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
  # At 375px bslib 0.9 still emits the Bootstrap 3 navbar shell:
  # .navbar-header > .navbar-toggle + .navbar-toggle .icon-bar, with the menu
  # in .navbar-collapse.show. The Sass alias for .navbar-toggler does not
  # rewrite the layout selectors, so both families are real and both are styled.
  expect_true(grepl("\\.navbar-toggle\\b", css), info = "BS3 toggle is emitted")
  expect_true(grepl("\\.icon-bar\\b", css), info = "BS3 icon bars need theming")
  expect_true(grepl("\\.navbar-header\\b", css), info = "BS3 header needs layout")
  expect_false(grepl("\\.navbar-collapse\\.in", css), info = "the toggle adds .show, not .in")
  expect_false(grepl("\\.form-inline\\b", css), info = "BS3 .form-inline is dead")
  expect_true(grepl("\\.navbar-toggler\\b", css), info = "the BS5 toggler alias is also styled")
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

test_that("the Module B rail is a hairline column, not a card stack", {
  css <- css_text()
  src <- paste(readLines(source_file("R", "mod_b_viz.R"), warn = FALSE), collapse = "\n")
  sidebar <- regmatches(
    css,
    regexpr("\\.b-workbench \\.bslib-sidebar-layout > \\.b-sidebar\\s*\\{[^}]*\\}", css)
  )
  expect_true(nzchar(sidebar), info = "the rail rule must out-specify bslib")
  expect_match(sidebar, "position:\\s*sticky", info = "the settings rail scrolls independently")
  # The rail is sticky, so its own border only reaches its content. The divider
  # is painted on the layout instead and spans the full workbench height.
  expect_match(
    css,
    "\\.b-workbench \\.bslib-sidebar-layout::before\\s*\\{[^}]*width:\\s*0\\.5px[^}]*background:\\s*var\\(--rule\\)",
    info = "one hairline separates rail from stage"
  )
  expect_false(grepl("border-right:\\s*var\\(--line\\);", sidebar), info = "the rail does not draw its own clipped border")
  expect_match(sidebar, "background:\\s*transparent", info = "no sidebar fill")
  expect_false(grepl("b-sidebar-title", css), info = "the rail has no heading any more")
  expect_false(grepl("b-sidebar-title|sidebar_title", src), info = "and the UI emits none")
})

test_that("the Module B toolbar stays clear of the canvas", {
  css <- css_text()
  toolbar <- regmatches(css, regexpr("\\.b-toolbar-wrap\\s*\\{[^}]*\\}", css))
  expect_true(nzchar(toolbar))
  # .b-stage clips, so it is the toolbar's scroll container: a sticky `top`
  # pulled the bar down over the canvas even at scrollTop 0 and hid the top
  # edge of the figure.
  expect_false(grepl("position:\\s*sticky", toolbar), info = "sticky here overlaps the canvas")
  expect_match(toolbar, "flex:\\s*0 0 auto", info = "the bar is a plain row of the stage column")
})

test_that("the canvas is a sheet on rules and the empty state is a well", {
  css <- css_text()
  canvas <- regmatches(css, regexpr("\\.b-canvas\\s*\\{[^}]*\\}", css))
  expect_true(nzchar(canvas))
  # Auto margins absorb the free space when the figure is short and collapse to
  # zero when it is tall, so it still scrolls from its own top edge.
  expect_match(canvas, "margin-block:\\s*auto", info = "centre without clipping")
  expect_false(grepl("align-self:\\s*center", canvas), info = "align-self clips a too-tall figure")
  expect_match(canvas, "border:\\s*var\\(--line\\)", info = "the canvas edge is a hairline")
  expect_match(css, "\\.b-canvas\\.is-empty\\s*\\{[^}]*border:\\s*0\\.5px dashed",
    info = "an empty canvas is a well waiting for input")
  expect_match(css, "\\[data-bs-theme=\"dark\"\\] \\.b-canvas\\.is-empty",
    info = "the well needs a dark variant")})

test_that("the placeholder draws no text and brings no paper of its own", {
  theme <- readLines(source_file("R", "fct_plot_theme.R"), warn = FALSE)
  start <- grep("^plot_empty_state <- function", theme)
  expect_length(start, 1L)
  stop <- start + which(theme[start:length(theme)] == "}")[1] - 1L
  body <- paste(theme[start:stop], collapse = "\n")
  expect_false(grepl("graphics::text", body),
    info = "placeholder wording belongs in the DOM, where tr() can reach it")
  viz <- paste(readLines(source_file("R", "mod_b_viz.R"), warn = FALSE), collapse = "\n")
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
    "\\.shiny-input-container \\.input-group \\.btn-file \\{[^}]*background: var\\(--well\\)",
    info = "the visible browse button must use the well token"
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
  expect_match(block, "color: var\\(--ink-2\\)")
  expect_match(block, "background:\\s*transparent")
})

test_that("muted copy clears WCAG AA on the surfaces it sits on", {
  css <- css_text()
  light <- regmatches(css, regexpr(":root \\{[^}]*\\}", css))[[1]]
  dark <- regmatches(css, regexpr("\\[data-bs-theme=\"dark\"\\] \\{[^}]*\\}", css))[[1]]
  grab <- function(block, token) {
    hit <- regmatches(block, regexpr(paste0(token, ": *#[0-9a-fA-F]{6}"), block))
    sub(".*: *#", "#", hit)
  }
  for (block in list(light, dark)) {
    muted <- grab(block, "--gray-11")
    for (token in c("--gray-1", "--gray-2", "--gray-3")) {
      surface <- grab(block, token)
      ratio <- css_contrast(muted, surface)
      expect_true(
        ratio >= 4.5,
        info = paste("muted", muted, "on", token, surface, "=", round(ratio, 2))
      )
    }
  }
})

test_that("every colour comes from a Radix palette token", {
  css <- css_text()
  light <- regmatches(css, regexpr(":root \\{[^}]*\\}", css))[[1]]
  dark <- regmatches(css, regexpr("\\[data-bs-theme=\"dark\"\\] \\{[^}]*\\}", css))[[1]]
  palette <- unique(c(
    regmatches(light, gregexpr("#[0-9a-fA-F]{6}", light))[[1]],
    regmatches(dark, gregexpr("#[0-9a-fA-F]{6}", dark))[[1]]
  ))
  used <- unique(regmatches(css, gregexpr("#[0-9a-fA-F]{6}", css))[[1]])
  expect_setequal(setdiff(used, palette), character())
  # The three families the interface relies on must all be defined.
  for (family in c("gray", "blue", "red", "green", "amber")) {
    expect_match(light, paste0("--", family, "-1: #"))
    expect_match(light, paste0("--", family, "-11: #"))
  }
})

test_that("borders are hairlines and corners are square", {
  css <- css_text()
  border_decls <- regmatches(css, gregexpr("border(?:-[a-z]+)?:\\s*[^;]+;", css))[[1]]
  widths <- unlist(regmatches(border_decls, gregexpr("[0-9.]+px", border_decls)))
  expect_setequal(setdiff(unique(widths), "0.5px"), character())

  radius_decls <- regmatches(css, gregexpr("border-radius:\\s*[^;]+;", css))[[1]]
  radius_vals <- trimws(sub("border-radius:\\s*", "", sub(";", "", radius_decls)))
  expect_setequal(setdiff(unique(radius_vals), c("0", "var(--radius)")), character())
  expect_match(css, "--radius: 0px")

  shadows <- regmatches(css, gregexpr("box-shadow:\\s*[^;]+;", css))[[1]]
  shadow_vals <- trimws(sub("box-shadow:\\s*", "", sub(";", "", shadows)))
  expect_setequal(setdiff(unique(shadow_vals), "none"), character())
})

test_that("type stays on a three-size scale and never drops below 12px", {
  css <- css_text()
  sizes <- unique(trimws(sub(";", "", regmatches(
    css, gregexpr("font-size:\\s*[^;]+;", css)
  )[[1]])))
  sizes <- sub("font-size:\\s*", "", sizes)
  expect_setequal(
    setdiff(sizes, c("var(--fs-micro)", "var(--fs-base)", "var(--fs-display)")),
    character()
  )
  expect_match(css, "--fs-micro: 12px")
  expect_match(css, "--fs-base: 15px")
})

test_that("motion is one 250ms ease-out transition and nothing else", {
  css <- css_text()
  expect_match(css, "--motion: 250ms ease-out")
  expect_false(grepl("@keyframes", css), info = "no decorative keyframe animation")
  expect_false(grepl("animation:", css), info = "no decorative animation")
  durations <- unlist(regmatches(css, gregexpr("\\b[0-9]+(?:\\.[0-9]+)?(?:ms|s)\\b", css)))
  expect_setequal(setdiff(unique(durations), c("250ms", "0.01ms")), character())
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

test_that("the desktop settings rail scrolls on its own", {
  css <- css_text()
  sidebar <- regmatches(
    css,
    regexpr("\\.b-workbench \\.bslib-sidebar-layout > \\.b-sidebar\\s*\\{[^}]*\\}", css)
  )
  expect_match(sidebar, "max-height: calc\\(100vh - 72px\\)")
  expect_match(sidebar, "overflow-y: auto")
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
  files <- source_r_files()
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

test_that("copy uses no middle-dot separators", {
  files <- source_r_files()
  hits <- vapply(files, function(f) {
    any(grepl("\u00b7", readLines(f, warn = FALSE), fixed = TRUE))
  }, logical(1))
  expect_true(!any(hits), info = paste(basename(files[hits]), collapse = "\n"))
})

test_that("the calibration table exposes table semantics", {
  src <- paste(readLines(source_file("R", "mod_a_calibration_table.R"), warn = FALSE), collapse = "\n")
  expect_match(src, "class = \"calib-table\",\\s*role = \"table\"")
  expect_match(src, "role = \"columnheader\"")
  expect_match(src, "role = \"rowheader\"")
})
