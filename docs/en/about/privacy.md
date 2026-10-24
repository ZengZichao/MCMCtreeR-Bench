# Privacy

## Data flow

Uploaded files travel from the browser to the Posit Connect Cloud instance. The
application copies them into `tempdir()/session$token/` and parses only that
session copy. No account, database or cross-session cache is used.

## Retention

The session directory is deleted in `onSessionEnded()`. Instance restarts and
redeployments also clear the local filesystem. The application does not provide
a way to recover a previous session's uploads or results. Download outputs
before closing the page.

## Logs

Server logs may record error stacks, file names and request metadata. The
application does not print file contents, full tip lists or user paths. Error
messages shown to users replace temporary paths with `<tmp>`. Do not put
sensitive information in file names or uploaded content.

## Local alternative

Install the package and run `mcmctreer::run_app()` on your own machine when data
must not leave your environment. The same code path is used locally and online;
only the hosting layer differs.

## Contact

Privacy questions: <zengzichao@sjtu.edu.cn>. Security reports should follow
`SECURITY.md` and should not be posted publicly.
