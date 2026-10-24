# Security Policy

## Supported versions

Version 0.1.0 receives security fixes. Older development snapshots are not
supported.

## Reporting a vulnerability

Email <zengzichao@sjtu.edu.cn> with:

- a short description of the issue;
- steps to reproduce;
- the affected version and deployment (local or Posit Connect Cloud);
- any suggested mitigation.

Do not open a public issue containing a working exploit, user data or
deployment credentials. You should receive an acknowledgement within a
reasonable academic-maintenance window. No bounty or SLA is offered.

## Scope

Relevant reports include path traversal, cross-session data leakage, unsafe
file handling, injection into rendered HTML, dependency-source tampering and
credential exposure. The application does not run MCMCtree/PAML and does not
accept authentication data.

## Deployment credentials

Connect Cloud credentials live under `~/.rsconnect/connect.posit.cloud/` for
interactive use. For CI, put `CONNECT_CLOUD_CLIENT_ID` and
`CONNECT_CLOUD_CLIENT_SECRET` in secret storage. If a secret is exposed, delete
the credential in the Posit account settings, create a new one, re-register it,
and redeploy staging.
