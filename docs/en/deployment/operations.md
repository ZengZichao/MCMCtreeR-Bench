# Operations

## Monitoring

Every release, check the revision log and run the staging smoke test. Every week,
review usage credits, memory peaks and error logs on the content page. The Free
plan provides 4 GB memory, 1 CPU, 20 monthly usage credits and five applications;
public sharing does not consume seats.

## Rollback

Connect Cloud keeps every revision, so the previous bundle remains inspectable.
Roll back by checking out the previous commit and deploying again:

```bash
git log --oneline
git checkout <previous-commit>
CONNECT_CLOUD_APP=mcmctreer-gui Rscript dev/deploy.R
```

A rollback is only reproducible when `renv.lock` and `manifest.json` are pinned
to the same upstream commit.

## Quotas

The application is designed for academic demonstration use:

- 50 MB total upload limit;
- 3,000 tips and 6,000 nodes per tree;
- 200,000 posterior rows;
- PDF pages up to 16 x 12 inches;
- PNG up to 12 x 9 inches at 200 dpi.

Long tasks are triggered explicitly and large posteriors default to manual
redraw. Users who need repeated or large runs should install the application
locally.

## Token rotation

If a Connect Cloud client secret is exposed, delete the credential in the Posit
account settings, create a new one, re-register it with
`rsconnect::connectCloudClientCredentials()`, run a staging deployment and
confirm that the old credential no longer works. Deleting the local account with
`rsconnect::removeAccount()` is not enough; rotate the secret itself.

## Migration exit

Connect Cloud runs each application on a single instance with up to 32 GB memory
and 8 CPU on higher plans. If the application needs SSO, data-source
authentication, custom domains or an SLA, move to a paid Connect Cloud plan or a
managed Posit Connect installation. Keep the repository commit, `renv.lock`,
`manifest.json` and the pinned upstream commit when migrating.
