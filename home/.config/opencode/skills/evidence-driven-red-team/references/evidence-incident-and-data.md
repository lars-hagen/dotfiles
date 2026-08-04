# Evidence, incident, and sensitive-data handling

## Evidence event

Prefer append-only JSONL or an equivalent immutable event stream.

```json
{
  "schema": "edrt-event/v1",
  "assessment_id": "A-001",
  "run_id": "R-001",
  "candidate_id": "H-001",
  "goal_id": "G-001",
  "phase": "ACTIVE_ORACLE",
  "utc": "RFC3339",
  "monotonic_ns": 0,
  "collector": "parent",
  "observer": "external-observer-id",
  "deployment_manifest_sha256": "",
  "method": "",
  "action": "",
  "expected": "",
  "observed": "raw fact without causal interpretation",
  "interpretation": "",
  "health": {"status": "", "samples": 0},
  "artifact_sha256": [],
  "cleanup_state": "pending",
  "redactions": [],
  "previous_event_sha256": ""
}
```

Record clock source, tool versions, deployment identity, collector, method, raw observation, separate interpretation, hashes, and redactions. Preserve originals; corrections are new events referencing superseded records.

## Artifact manifest

```markdown
| Artifact ID | Path | Type | Created UTC | Collector | SHA-256 | Sensitivity | Redactions | Custody/transfer |
|---|---|---|---|---|---|---|---|---|
```

## Sensitive-data classes

- `public`: safe for normal report distribution.
- `assessment-internal`: locators, topology, notebook/session IDs, non-secret operational metadata.
- `owner-confidential`: proprietary code, configurations, vulnerabilities, tenant information.
- `restricted`: personal data, unrelated data, credentials, tokens, cookies, private keys, signed URLs.

Do not retain `restricted` material in normal artifacts. Record only a redacted reference and notify the owner. Never prove a credential works without separate authorization.

## Incident triggers

Freeze on:

- Unexpected availability or latency change.
- Alert, page, ticket, or human contact connected to activity.
- Unplanned write, deletion, persistence, or privilege.
- Unrelated or cross-tenant data.
- Credential or key material.
- Loss of external observation.
- Cleanup or restoration failure.
- Authorization expiry, revocation, or scope drift.

## Incident record

```markdown
# X-001: Incident

- Detected UTC:
- Assessment/run/candidate:
- Last externally confirmed phase:
- Raw observation:
- Activity stopped UTC:
- Current state: FROZEN
- Minimal evidence preserved:
- Preapproved cleanup/recovery performed:
- Cleanup outcome:
- Owner notified UTC, contact, channel:
- Data involved and redaction handling:
- Suspected relationship, explicitly qualified:
- Residual state:
- Resume authorization reference:
- Corrective actions:
```

Do not improvise broad remediation inside the target. Perform only preapproved cleanup or recovery. Resume related active work only after written review and approval.

## Evidence failure semantics

- `indeterminate`: required evidence missing, attribution unavailable, or final phase not externally observed.
- `invalid`: control instability, deployment drift, uncontrolled variables, or contract violation.
- `negative-exact`: all prerequisites and evidence valid, but exact predicted transition not observed.
- `incident`: unexpected impact or data handling event; no retry before review.
