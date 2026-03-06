# Community

This repository is public and community-driven.

## Where to collaborate

- **Discussions** — architecture, roadmap, and operator questions
- **Issues** — reproducible bugs and concrete feature requests
- **Pull requests** — focused code and docs updates with passing checks

## Reports that help the project most

Useful reports usually include:

- exact command used
- distro and environment details
- sanitized logs
- expected vs actual behavior
- whether the failure happened on:
  - minimal xhttp-first install
  - `install --advanced`
  - `migrate-stealth`
  - `recommended` or `rescue` client variant

## Useful field feedback topics

- xhttp reachability and reliability on real-world networks
- `packet-up` rescue behavior on difficult providers
- migration quality from legacy `grpc/http2`
- artifact compatibility in v2rayn, nekoray, and raw xray clients
- rollback or repair behavior after failures

## Please avoid

- screenshots without text logs
- vague "`does not work`" reports
- publishing private keys, `keys.txt`, or sensitive full links
- mixing unrelated bugs into one issue

## PR expectations

- one clear change per PR
- tests and docs updated in the same pass
- rollback and security behavior preserved
- green CI before requesting review

See [../../.github/CONTRIBUTING.md](../../.github/CONTRIBUTING.md) for the full workflow.

## Maintainer contact

- X (Twitter): [x.com/neket371](https://x.com/neket371)

## Interaction rules

- be specific and technical
- challenge ideas, not people
- prefer facts, logs, and repro steps
- keep security disclosures private
