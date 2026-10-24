# Deployment script for Posit Connect Cloud.
#
# Usage:
#   CONNECT_CLOUD_APP=mcmctreer-gui-staging Rscript dev/deploy.R
#   CONNECT_CLOUD_APP=mcmctreer-gui Rscript dev/deploy.R
#
# Credentials must already exist under ~/.rsconnect/connect.posit.cloud
# (rsconnect::connectCloudUser() or connectCloudClientCredentials()).

app_name <- Sys.getenv("CONNECT_CLOUD_APP", "mcmctreer-gui-staging")
account <- Sys.getenv("CONNECT_CLOUD_ACCOUNT", "zengzichao")
server <- "connect.posit.cloud"
manifest_path <- "manifest.json"

# 1) The Connect Cloud account must be registered.
accounts <- rsconnect::accounts()
if (!any(accounts$name == account & accounts$server == server)) {
  stop(
    "Connect Cloud account not registered. Run rsconnect::connectCloudUser() ",
    "or rsconnect::connectCloudClientCredentials() first."
  )
}

# 2) Deploy from a clean working tree when this is a Git checkout.
if (dir.exists(".git")) {
  status <- system2("git", c("status", "--porcelain"), stdout = TRUE, stderr = TRUE)
  if (length(status) > 0) {
    stop("Working tree is not clean; commit or stash first.")
  }
}

# 3) Tests must pass.
pkgload::load_all(export_all = TRUE, helpers = FALSE, attach_testthat = FALSE)
testthat::test_local(stop_on_failure = TRUE)

# 4) The lock file must be in sync when an renv project is active.
if (file.exists("renv.lock") && dir.exists("renv")) {
  if (!requireNamespace("renv", quietly = TRUE)) {
    stop("renv.lock exists but renv is not installed.")
  }
  status <- renv::status()
  if (!isTRUE(status$synchronized)) {
    stop("renv.lock is out of sync; run renv::snapshot().")
  }
}

# 5) The checked-in manifest is authoritative. Regenerating it from a partial
# local library would silently drop the GitHub-pinned MCMCtreeR package.
if (!file.exists(manifest_path)) {
  stop("manifest.json is missing; run rsconnect::writeManifest() first.")
}
manifest <- jsonlite::read_json(manifest_path, simplifyVector = FALSE)
app_files <- names(manifest$files)
required <- c("app.R", "DESCRIPTION", "NAMESPACE")
missing <- setdiff(required, app_files)
if (length(missing)) {
  stop("Manifest is missing required files: ", paste(missing, collapse = ", "))
}
if (!any(startsWith(app_files, "R/"))) stop("Manifest contains no R/ files.")
if (!any(startsWith(app_files, "inst/"))) stop("Manifest contains no inst/ files.")
absent <- app_files[!file.exists(app_files)]
if (length(absent)) {
  stop("Files listed in the manifest are missing: ", paste(absent, collapse = ", "))
}

bundle_mb <- sum(file.info(app_files)$size, na.rm = TRUE) / 1024^2
if (bundle_mb > 30) {
  warning(sprintf("Bundle is %.1f MB; the target is under 30 MB.", bundle_mb))
}

# 6) The upstream package must remain pinned to the tested commit.
upstream <- manifest$packages$MCMCtreeR
expected_sha <- "2330e7a9916c3929513ee217d3854be993965f6b"
if (is.null(upstream) || !identical(upstream$RemoteSha, expected_sha)) {
  stop("manifest.json does not pin MCMCtreeR to ", expected_sha, ".")
}

# 7) Deploy.
rsconnect::deployApp(
  appDir = ".",
  manifestPath = manifest_path,
  appName = app_name,
  appTitle = sprintf(
    "MCMCtreeR Bench %s",
    read.dcf("DESCRIPTION", fields = "Version")[1, 1]
  ),
  account = account,
  server = server,
  appVisibility = "public",
  launch.browser = FALSE,
  forceUpdate = TRUE
)
