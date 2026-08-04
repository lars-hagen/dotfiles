# Reporting, handoff, and closeout

## Claim model

Every finding reports independently:

- Theoretical severity ceiling.
- Version applicability.
- Configuration applicability.
- Interface reachability.
- Demonstrated primitive.
- Demonstrated terminal impact.
- Confidence.
- Disconfirming evidence.
- Explicit non-claims.

Do not write “secure,” “not vulnerable,” or “no issues.” Write “not reproduced under conditions …” and state tested coverage and exclusions.

## Finding template

```markdown
# F-001: <owner-facing title>

- Goal/cut advanced:
- Affected component and exact deployment:
- Authorization and scope:
- Severity ceiling:
- Applicability:
- Reachability:
- Demonstrated primitive:
- Demonstrated terminal impact:
- Confidence:

## Owner-facing summary

## Preconditions and measured boundary

## Observation

Facts only, with evidence IDs.

## Interpretation

## Demonstrated impact

## Explicit non-claims and untested areas

## Stable control and bounded reproduction conditions

Describe owner reproduction conditions without importing unnecessary third-party operational detail.

## Cleanup and residual state

## Recommended remediation direction

## Duplicate/known-issue check

## Evidence index
```

## Handoff template

```markdown
# Handoff

- Updated UTC:
- Assessment ID:
- Current STATE:
- Authorization status and expiry:
- Exact artifact revisions summarized:
- Deployment fingerprint and drift status:
- Active terminal goals and cut states:
- Demonstrated primitives:
- Explicit non-claims:
- Active candidate and state:
- Last valid run and last externally confirmed phase:
- Last verified cleanup:
- Incident status:
- Residual state/access:
- Open approvals/amendments:
- One exact next action:
- Preconditions to reverify before action:
- Do-not-repeat list with reopening conditions:
- Artifact manifest location:
- Reproduction prerequisites:
- Known traps and invalidated assumptions:
```

A successor reads `STATE.md`, authorization, handoff, last run, and cleanup evidence in that order. If any is missing or ambiguous, remain `FROZEN`.

## Decision log

```markdown
| Decision ID | UTC | Decision | Alternatives | Requested by | Decided by | Evidence | Rationale | Artifacts affected |
|---|---|---|---|---|---|---|---|---|
```

Record severity changes, scope changes, risk acceptance, candidate selection, reopening, incident resumption, and rejected shortcuts.

## Closeout

Do not set `CLOSED` until:

- Active access, test accounts, sessions, credentials, and temporary resources are removed.
- Cleanup and restoration are independently verified.
- Residual items are resolved or explicitly accepted by the owner.
- Findings and artifacts are delivered with sensitivity labels.
- Retention and destruction dates are recorded.
- Coverage and untested areas are explicit.
- Incidents and disclosure obligations are resolved.
- Owner acknowledgment is recorded.

```markdown
# Closeout

- Closed UTC:
- Owner acknowledgment:
- Access removed:
- Test resources removed:
- Residual items and acceptance:
- Artifact delivery:
- Retention/destruction schedule:
- Coverage statement:
- Untested areas:
- Findings summary:
- Incident/disclosure status:
- Reopening process:
```
