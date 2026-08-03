# Contracts

Versioned text that vault-os owns and other systems consume.

`agent-contract-1.0.md` is the cross-vault contract block injected into every
shared agent definition. It was previously copy-pasted into each of the six
agent bodies in `global/agents/`, which meant a bump could not propagate: the
2026-08-03 audit found the text frozen inside `agent-config`'s vendored agent
prompts with no route back to this repository.

Extracting it here makes it a **declared input**. `agent-config` composes agent
prompts from its own body plus this file, so bumping the contract to 1.1 here
reaches every installed agent through a normal release rather than six manual
edits.

Rules:

- This file is canonical. Do not edit a rendered copy in a provider directory.
- Bump the filename and the `vault-os-agent-contract:` marker together.
- A consumer that pins 1.0 keeps reading this file; add a new one for 1.1.
