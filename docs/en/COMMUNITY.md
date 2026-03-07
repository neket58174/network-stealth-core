# community

## where to ask for help

use the repository discussion and issue surfaces appropriately:

- **discussions** for design questions, roadmap ideas, and deployment trade-offs
- **issues** for reproducible bugs and contract mismatches
- **security reporting** for vulnerabilities, using private disclosure only

## what makes a good support request

include enough data to keep the problem reproducible without exposing secrets.

good reports include:

- exact command that was run
- current version or commit
- output of `sudo xray-reality.sh status --verbose`
- output of `sudo xray-reality.sh diagnose`
- whether the node is legacy, migrated, or fresh strongest-direct
- relevant `scripts/measure-stealth.sh` output for real-network problems
- whether `emergency` was needed on the tested network

## redact before posting

do not publish:

- private keys
- full client links
- raw xray client json
- private server addresses if they identify your node

redact `uuid`, `short_id`, `private_key`, and domain-specific secrets.

## contribution expectations

if you propose a change to the managed contract, include:

- why the default path should change or stay unchanged
- tests
- bilingual docs updates
- migration notes if older managed installs are affected

## project direction

the project intentionally favors:

- fewer install questions
- one strongest safe default
- honest export capability reporting
- saved operator evidence over guesswork

changes that weaken those goals will get stronger scrutiny.
