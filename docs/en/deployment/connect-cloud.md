# Deploy to Posit Connect Cloud

## Credentials

Authenticate once from an R session:

```r
rsconnect::connectCloudUser()
rsconnect::accounts()
```

For noninteractive environments, create a Connect Cloud credential and register
it without a browser flow. Keep the client secret outside the repository:

```r
rsconnect::connectCloudClientCredentials(
  clientId = Sys.getenv("CONNECT_CLOUD_CLIENT_ID"),
  clientSecret = Sys.getenv("CONNECT_CLOUD_CLIENT_SECRET"),
  accountName = Sys.getenv("CONNECT_CLOUD_ACCOUNT")
)
```

The account is stored under `~/.rsconnect/connect.posit.cloud/`, never in this
repository. The server name is `connect.posit.cloud`.

## Create the applications

The deployment script creates the content on first use and reuses it afterwards.
The Free plan allows five applications.

| Purpose | Public URL |
| --- | --- |
| staging | created by the same script under a separate content name |
| production | <https://zengzichao-mcmctreer-bench.share.connect.posit.cloud/> |

Both contents are public. Connect Cloud currently builds with R 4.6.1, which
matches `renv.lock`; confirm the runtime in the content settings after a platform
upgrade.

## Deploy

```bash
CONNECT_CLOUD_APP=mcmctreer-gui-staging Rscript dev/deploy.R
CONNECT_CLOUD_APP=mcmctreer-gui Rscript dev/deploy.R
```

`dev/deploy.R` checks the account, runs the test suite, verifies the bundle and
deployment records, then calls `rsconnect::deployApp()` with
`server = "connect.posit.cloud"`, `manifestPath = "manifest.json"` and
`appVisibility = "public"`. Passing the checked-in manifest is deliberate: it
keeps the GitHub-pinned `MCMCtreeR` commit and the `ragg`/`svglite` dependencies
in the bundle even when the local library is incomplete.

## Inspect logs

Deploy with `logLevel = "verbose"` to stream bundle, install and runtime logs.
Failures also appear in the revision history of the content page:

```r
rsconnect::deployApp(
  appDir = ".", manifestPath = "manifest.json",
  appName = "mcmctreer-gui", account = "zengzichao",
  server = "connect.posit.cloud", appVisibility = "public",
  launch.browser = FALSE, forceUpdate = TRUE, logLevel = "verbose"
)
```

Look for package installation failures, a missing `MCMCtreeR` commit, and Shiny
startup errors. Do not interrupt the first deployment while dependencies are
being installed.

## URLs

Connect Cloud serves each revision at
`https://[content-id].share.connect.posit.cloud` and exposes an administration
page at `https://connect.posit.cloud/[account]/content/[content-id]`. A custom
name can replace the content ID with `[account]-[name]`; the default URLs above
are the canonical addresses in this repository.

## Bundle rules

`.rscignore` is the authoritative bundle list. It excludes `dev/`, `tests/`,
`man/`, `docs/`, `mkdocs.yml`, `.github/`, `renv/`, `.Rprofile`, `rsconnect/`,
`README*`, `CONTRIBUTING*`, `CODE_OF_CONDUCT*`, `SECURITY*`,
`CITATION.cff` and `site/`. It must not exclude `app.R`,
`DESCRIPTION`, `NAMESPACE`, `R/`, `inst/`, `renv.lock` or `manifest.json`.

Use the following before every release and keep the bundle below 30 MB:

```r
files <- rsconnect::listDeploymentFiles(".")
length(files)
sum(file.info(files)$size) / 1024^2
```
