# Authorization and scope

Use this reference before any active engagement and whenever scope changes.

## Authorization record

```markdown
# Authorization

- Assessment ID:
- Owner organization:
- Approving authority and role:
- Identity and role verification method:
- Asset-control assertion:
- Authorization evidence reference:
- Issued UTC:
- Starts UTC:
- Expires UTC:
- Revocation channel:
- Emergency contact and out-of-band channel:
- Stop phrase:

## In scope

| Target ID | Exact identifier | Owner | Environment | Tenant | Approved goals | Permitted action classes |
|---|---|---|---|---|---|---|

## Out of scope

| Identifier or category | Reason |
|---|---|

## Conditions

- Testing windows:
- Blackout periods:
- Maximum risk and availability budget:
- Monitoring owner and signals:
- Cleanup and recovery owner:
- Third-party/provider terms:
- Data classes permitted:
- Data retention and destruction:
- Disclosure, embargo, and distribution:
- Safety-critical or regulated constraints:

## High-risk action classes

| Action class | Authorized? | Exact target | Rate/count/bytes/duration | Window | Monitor | Rollback | Expected value |
|---|---|---|---|---|---|---|---|

## Amendments

| Amendment ID | UTC | Change | Reason | Approver | New expiry or conditions |
|---|---|---|---|---|---|
```

## Scope amendment triggers

Freeze related active work when discovering:

- A new target, tenant, owner, trust boundary, interface, credential source, or data class.
- Shared infrastructure not controlled by the authorizer.
- A new terminal goal or action class.
- Unexpected destructive or availability impact.
- Provider or third-party restrictions.
- Deployment drift that changes applicability or risk.

An amendment must identify the exact change, rationale, additional risk, monitoring, cleanup, expiry, and approving authority.

## Action classes

Define engagement-specific classes. Suggested neutral taxonomy:

- `A0`: offline analysis of already-held artifacts.
- `A1`: passive target observation with no new requests.
- `A2`: bounded read-only interaction.
- `A3`: bounded reversible state validation.
- `A4`: controlled privilege or boundary validation.
- `A5`: high-risk volume, randomness, persistence, social, or availability testing.

The authorization must name exact classes. A higher class does not automatically include unrelated targets, tenants, data, credentials, or goals.

## Shared and third-party assets

An in-scope name resolving to an unapproved provider, CDN, SaaS, shared host, or another tenant is not automatically in scope. Record the observation and request clarification. Do not test the third party.

## Credential rule

Discovery does not authorize use. Do not copy secret material into durable artifacts. Record only a redacted location, type, discovery time, and evidence ID. Notify the owner and recommend rotation. Use requires a separate amendment naming the credential and action.

## Refusal patterns

```text
Authorization is expired or ambiguous, so active work is frozen. I can continue offline documentation and resume after renewed written authorization names the target, goal, action class, and window.
```

```text
The requested action crosses an unapproved tenant or third-party boundary. I will not interact with it. I can document the boundary and prepare a scope-amendment request.
```

```text
The action is high-risk and the authorization does not define limits, monitoring, rollback, and emergency handling. I can design the bounded plan, but I will not run it without those approvals.
```
