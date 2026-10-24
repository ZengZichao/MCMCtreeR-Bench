# FAQ

## Is my data uploaded?

Yes, when you use the online application. Files are sent to the Posit
Connect Cloud server and stored in a session-specific temporary directory. They
are deleted when the session ends or the instance restarts. For sensitive data,
install and run the application locally.

## Why is export disabled?

The inputs changed after the last estimation run, or no estimation has run yet.
The application hashes the tree, nodes, ages, distributions and advanced
parameters. Rerun the estimation to refresh the results. Switching language or
theme does not disable export.

## Why are plot labels in English?

Plot text uses English so that figures remain readable on Linux servers without
guaranteed CJK fonts, and so that exported figures match common journal style.
The interface itself is fully bilingual.

## Why can gamma alpha not be fixed through MCMCtreePhy?

The upstream `MCMCtreePhy()` wrapper passes the numeric `alpha` value to the
logical `estimateAlpha` argument, which forces alpha estimation. The GUI calls
`estimateGamma()` directly, where `estimateAlpha = FALSE` works as documented.

## Can I use BEAST2 data?

Not in version 0.1.0. The GUI exposes MCMCtree, MrBayes, RevBayes and User
modes. The pinned upstream `MCMC.tree.plot()` contains a BEAST2 branch, but it
has not been validated for this release.

## How should I cite the tool?

Cite the GUI software and the original MCMCtreeR paper. Both BibTeX entries are
in the README and in the Citation page. The upstream DOI is
`10.1093/bioinformatics/btz554`.
