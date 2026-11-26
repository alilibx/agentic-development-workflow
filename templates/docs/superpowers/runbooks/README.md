# Runbooks

One runbook per change whose deploy needs manual steps, a strict order, or a one-off migration: `<KEY-id>-<topic>.md`.

Each runbook says, before the deploy and not during it:

- the steps, in order, with the exact commands;
- why the order matters;
- what fails if a step is skipped;
- how to check that each step worked.

Link it from the PR's deploy notes. Delete it once the change has reached every environment.
