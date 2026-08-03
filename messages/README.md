# `delve/messages/`

Cross-agent message bodies — content-path target for MSG- / REQ- / REP- artifacts (STO-FLOW-019). Layout: `messages/YYYY-MM-DD/HH-MM-SS-<slug>/NNN/<file>.md`.

Don't hand-create directories here — mint via `ccc-bd new {{msg,req,rep}} ...` and the wrapper computes the right path.
