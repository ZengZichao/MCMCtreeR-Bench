# Module A: priors

Module A prepares time priors for MCMCtree. It is a six-step navigator, but the
steps are a state navigator rather than a locked wizard: completed steps can be
revisited at any time.

## Step 1: load a tree

Three input methods are available:

- upload a `.tre`, `.nwk`, `.newick`, `.nexus`, `.nex` or `.txt` file;
- paste a Newick string;
- load the `apeData` example from `MCMCtreeR`.

The tree check reports tip count, internal node count, branch lengths, whether
the tree is fully binary, and duplicated tip labels. Duplicated tip labels are
rejected because calibration would be ambiguous.

## Step 2: select calibration nodes

Click an internal node in the persistent tree preview, or choose a node number
from the list. Clicking a selected node again removes it. Tips cannot be
calibrated; clicking a tip produces an explanatory message.

Every selected node shows its descendant tips, which is the practical way to
verify that a fossil calibration covers the intended clade.

## Step 3: calibration table

Each row contains the node, its tip count, the distribution type, minimum and
maximum ages, and a live validation status.

| Distribution | Minimum age | Maximum age |
| --- | --- | --- |
| `cauchy` | required | required |
| `skewT` | required | required |
| `skewNormal` | required | required |
| `gamma` | required | required |
| `bound` | required | required |
| `upper` | not used | required |
| `fixed` | required | not used |

The disabled field is cleared in the state, so a hidden value cannot leak into
the exported file.

## Step 4: advanced parameters

Advanced fields are optional. Leaving a field empty omits it from the upstream
call, which keeps GUI defaults and upstream defaults aligned. Each field has a
hint and a range check. Invalid values block the estimation step.

`gamma` is estimated through `estimateGamma()`, so `estimateAlpha` and
`estimateBeta` are honoured. The upstream `MCMCtreePhy()` wrapper has a
`gamma`/`estimateAlpha` defect and is not used by the GUI.

## Step 5: run the estimation

The estimation calls one `estimateXxx()` function per node. For each node it
stores the parameter matrix, the node label, the calibrated tree, and the
MCMCtree text. The tree is rebuilt from a full-length node-label vector so that
only calibrated nodes receive labels.

## Step 6: preview and export

The preview shows the calibrated tree, the exact `.tre` text, and a parameter
summary. Download the `.tre` file or a PDF/PNG/SVG distribution figure. Export
is disabled when the inputs changed after the last run.

## What the .tre file contains

The `.tre` text starts with the tip count and a `1`, followed by the tree in
MCMCtree format and `//end of file`. Each calibration appears as a quoted node
label such as `'L(1.5,50,0.001,1e-300)'`, `'U(1.2,0.025)'` or `'=0.4'`.
