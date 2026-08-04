# Attack graph and cut-set template

Build a bounded authority-state graph. Do not create an encyclopedia of products, CVEs, or techniques.

```markdown
# Assessment attack graph

- Assessment ID:
- Updated UTC:
- Authorization reference:
- Deployment manifest hash:
- Graph owner:

## Terminal goals

### G-001: <falsifiable goal>

- Approved action classes:
- Positive terminal observables:
- Falsifying observations:
- Non-goals:
- Compatible deployment requirements:

#### Minimal cut set CS-001

| Order | Required authority state or transition | Direct observable | Evidence | State |
|---:|---|---|---|---|

## Trust boundaries

| Boundary ID | Side A | Side B | Enforcement | Data/authority crossing | Measurement | State | Evidence |
|---|---|---|---|---|---|---|---|

## Measured interfaces

| Interface ID | Endpoint/operation | Direction | Mediation | Auth | Namespace/tenant | Presence state | Confidence | Evidence |
|---|---|---|---|---|---|---|---|---|

## Deployment provenance

| Component | Runtime version/hash | Configuration/policy | Source revision | Correspondence | Reverified UTC | Evidence |
|---|---|---|---|---|---|---|

## Authority-state graph

```text
START
├── B-001 / I-001
│   ├── H-001 -> S-001 [source-supported]
│   └── H-002 [admission-blocked: missing prerequisite]
└── B-002 / I-002 [closed-source]
```

## Edge ledger

| Edge ID | From | Operation | To authority state | Prerequisites | Positive oracle | Negative control | State | Confidence | Evidence | Reopen condition |
|---|---|---|---|---|---|---|---|---|---|---|

## Proven primitives and explicit non-claims

| Primitive | Demonstrated | Does not establish | Compatible cuts advanced | Evidence |
|---|---|---|---|---|

## Refuted and closed routes

| Hypothesis | Exact deployment tuple | Outcome | Closure class | Closure reason | Evidence | Reopen condition |
|---|---|---|---|---|---|---|

## Open workstreams

Maximum 3. Maximum 12 open hypotheses total.

| Workstream | Exact question | Inputs | Owner/agent | Output schema | Stop condition |
|---|---|---|---|---|---|
```

## State vocabulary

- `inventoried`: interface or transition recorded, not yet evaluated.
- `discovered`: concrete hypothesis exists.
- `admission-blocked`: one or more hard gates fail.
- `source-supported`: exact evidence supports the transition.
- `oracle-ready`: bounded contract and positive observable exist.
- `approved-to-run`: authorization and risk approval verified.
- `running`: one active runtime oracle.
- `demonstrated`: runtime evidence supports the exact claim.
- `negative-exact`: exact hypothesis tuple not reproduced.
- `indeterminate`: evidence incomplete or attribution unavailable.
- `invalid`: control, deployment, or one-variable comparison failed.
- `closed-exact`: exact hypothesis closed by valid evidence.
- `closed-source`: exact reachable source proves required transition absent.
- `parked`: lower priority or prerequisite unavailable.
- `reopened`: new evidence changed a recorded prerequisite.

## Graph rules

- Every edge cites inventory and evidence IDs.
- A cut member is complete only with direct evidence.
- Do not join incompatible deployment lineages.
- A crash is an availability edge unless a stronger primitive is directly proven.
- “Unknown” is not “absent.”
- Two negatives establish repeatability only for that exact tuple.
- Preserve closed paths and reopening conditions.
