# Candidate ledger template

Use hard admission gates before ranking. Never allow impact to compensate for unacceptable risk.

## Ledger

```markdown
# Candidate ledger

| ID | Goal/cut | Candidate | State | Reachability | Authority gain | Applicability | Oracle | Risk class | Next information gain | Evidence |
|---|---|---|---|---|---|---|---|---|---|---|
```

## Candidate card

```markdown
## H-001: <falsifiable candidate>

### Identity

- Terminal goal and cut advanced:
- Component, version, hash, source revision:
- Symbol, operation, interface, boundary:
- Advisory/CVE/PoC references:
- Advisory-derived hypothesis: yes/no

### Claim axes

- severity_ceiling: none/low/medium/high/critical/unknown
- version_applicability: true/false/unknown
- configuration_applicability: true/false/unknown
- interface_reachability: unreachable/privileged/reachable/unknown
- demonstrated_primitive: none/observed/corroborated/unknown
- demonstrated_terminal_impact: none/bounded/complete/unknown
- confidence: observed/corroborated/inferred/speculative

### Authority transition

- Starting authority:
- Exact operation:
- Expected resulting authority:
- Why this advances a cut:
- Explicit non-claims:

### Prerequisites

| Prerequisite | Required value | Measured value | State | Evidence |
|---|---|---|---|---|

### Admission gates

- [ ] Authorization covers goal, target, boundary, action, and risk.
- [ ] Exact version/configuration applicability established.
- [ ] Interface and nested operation measured reachable.
- [ ] Authority transition is explicit and non-denial.
- [ ] Stable control exists.
- [ ] Active changes one causal variable.
- [ ] Positive oracle is externally observable.
- [ ] Cleanup is bounded and verifiable.
- [ ] Stop conditions are machine-checkable.
- [ ] Negative outcome has information value.

### Proposed experiment

- Contract ID:
- Stable control:
- Single active variable:
- Positive oracle:
- Negative or indeterminate outcomes:
- Externally delivered phases:
- Health signals and thresholds:
- Cleanup and restoration:
- Maximum requests/objects/bytes/time/retries:
- Stop conditions:

### Evidence

- Supporting:
- Disconfirming:
- Unknowns:
- Public research queries and immutable references:

### Outcome

- Run IDs:
- Exact deployment tuple:
- Observation:
- Interpretation:
- State transition:
- Claim supported:
- Claims not supported:
- Cleanup verified:
- Closure or next gate:
- Reopen condition:
```

## Priority method

After hard gates, rank lexicographically:

1. Expected progress across an approved cut.
2. Information gain if negative.
3. Oracle specificity and causal isolation.
4. Deployment applicability confidence.
5. Reversibility and blast radius.
6. Execution and recovery cost.

Optional numeric scores may summarize these factors, but MUST NOT override admission, risk, authorization, or stop gates.

## Closure semantics

The exact hypothesis tuple is:

```text
(authorization, deployment fingerprint, configuration, prerequisites,
 input, operation, predicted transition, control, oracle, environment)
```

A valid negative closes only that tuple. Use `closed-source` for broader closure only when exact reachable source proves the transition impossible. Record every closed path and precise reopening condition.
