# Experiment contract and result template

Write the contract before target interaction. Append results without rewriting original expectations.

```markdown
# T-001 / R-001: <bounded validation>

## Authorization and identity

- Assessment ID:
- Candidate ID:
- Goal/cut:
- Authorization and action-class reference:
- Approver:
- Window:
- Deployment manifest SHA-256:
- Build/deployment artifact SHA-256:
- Operator:
- External observer:

## Hypothesis

- Starting authority:
- Single changed variable:
- Predicted transition:
- Positive non-denial oracle:
- Falsifying observation:
- Explicit non-claims:

## Bounds

- Maximum requests:
- Maximum objects:
- Maximum bytes:
- Maximum duration:
- Maximum retries:
- Rate/concurrency:
- Blast radius:
- Expected health impact:

## Stable control

- Control variant:
- Variables held constant:
- Baseline health signals:
- Control success oracle:
- Control cleanup:

## Active variant

- Exact one-variable difference:
- Precondition checks:
- Active sequence:
- Positive oracle:
- Negative classification:
- Indeterminate/invalid conditions:

## External phase contract

| Order | Phase | Must be externally persisted before | Expected evidence |
|---:|---|---|---|
| 1 | PRECHECK | any target operation | authorization, deployment, health |
| 2 | BASELINE_HEALTH | control | samples and thresholds |
| 3 | CONTROL_START | next control action | variant and timestamp |
| 4 | CONTROL_ORACLE | cleanup | raw control observable |
| 5 | CONTROL_CLEANUP | active | cleanup verification |
| 6 | HEALTH_SAMPLE | active | target health |
| 7 | ACTIVE_START | trigger | one-variable declaration |
| 8 | ACTIVE_ORACLE_OR_TIMEOUT | cleanup | raw active observable |
| 9 | ACTIVE_CLEANUP | restoration | cleanup result |
| 10 | RESTORATION_VERIFY | final health | residual-state check |
| 11 | FINAL_HEALTH | seal | health samples |
| 12 | SEAL_MANIFEST | finish | artifact hashes |

## Stop conditions

- Authorization expiry, revocation, or drift.
- Health threshold breach or unexpected outage.
- Alert or human contact tied to activity.
- Unrelated, cross-tenant, credential, or personal data.
- Unplanned mutation or privilege beyond approved cut.
- Loss of external observation.
- Cleanup or restoration failure.
- Uncontrolled variable or deployment drift.

## Cleanup and recovery

- Exact cleanup sequence:
- Restoration verification:
- Preapproved recovery only:
- Cleanup owner:
- Residual state if cleanup fails:

---

## Result append

- Started UTC / monotonic:
- Finished UTC / monotonic:
- Control observation:
- Active observation:
- Health samples:
- Last externally confirmed phase:
- Cleanup observation:
- Restoration observation:
- Artifacts and SHA-256:
- Redactions:
- Unexpected events:
- Result state: demonstrated/negative-exact/indeterminate/invalid/incident
- Narrow claim supported:
- Explicit non-claims:
- Disconfirming evidence:
- Candidate state transition:
- Next single action or closure:
```

## Result rules

- Observation contains measured facts only. Interpretation is separate.
- Missing required phases means `indeterminate`.
- Unstable control, changed deployment, or multiple variables means `invalid`.
- A timeout or crash is not a stronger primitive without direct evidence.
- Cleanup success requires verification, not only a successful command return.
- Preserve raw artifacts even when the run fails.
