---
name: tavily
description: "Search the web and extract page content via the Tavily REST API using raw curl (no CLI, no SDK). Load when the user wants to search the web, find articles or sources, look up current information, get recent news, or pull clean text/markdown from one or more URLs: phrases like \"search for\", \"find me\", \"look up\", \"what's the latest on\", \"extract\", \"grab the content from\", \"read this webpage\". Returns LLM-optimized JSON with relevance scores, content snippets, optional AI answers, and clean markdown. Endpoints: /search, /extract, /crawl, /map."
allowed-tools: Bash(curl:*) Bash(jq:*)
---

# Tavily (raw curl)

LLM-optimized web search and content extraction over the Tavily REST API. No CLI or
SDK: plain `curl` against `https://api.tavily.com` plus `jq` for parsing.

## Auth

Bearer token in the `TAVILY_API_KEY` env var (already exported in `~/.zshenv`).
Every request sends `Authorization: Bearer $TAVILY_API_KEY`. Never paste the key into
commands or committed files; reference the env var.

Verify it is present before calling:

```bash
[ -n "$TAVILY_API_KEY" ] && echo "key set" || echo "TAVILY_API_KEY missing"
```

## Endpoints

| Need                         | Endpoint               | Reference                                    |
| ---------------------------- | ---------------------- | -------------------------------------------- |
| Find pages on a topic        | `POST /search`         | [references/search.md](references/search.md)  |
| Get clean content from a URL | `POST /extract`        | [references/extract.md](references/extract.md) |
| Bulk-extract a site section  | `POST /crawl`          | [references/crawl.md](references/crawl.md)     |
| List a site's URLs (no text) | `POST /map`            | [references/map.md](references/map.md)         |

Default search to `search_depth:"basic"` with `max_results:10`. When you need a page's full text, call
`/extract` on the URL rather than `include_raw_content` (avoid it; the `.content` snippet
usually suffices). Reach for `/crawl` only when you do not have the URLs and need many
pages under one site (e.g. a whole docs section); always cap it with `limit`.

## Quick start: search

```bash
curl -fsS -X POST https://api.tavily.com/search \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"who is Leo Messi?","search_depth":"basic","max_results":10}' \
| jq -r '.results[] | "## \(.title)  [\(.score)]\n\(.url)\n\(.content)\n"'
```

Every result already carries a `.content` snippet (LLM-optimized summary); print that.
For full page text, hit `/extract` on the specific URL instead of `include_raw_content`.

Recent news with an AI answer:

```bash
curl -fsS -X POST https://api.tavily.com/search \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"AI policy news","topic":"news","time_range":"week","include_answer":"advanced"}' \
| jq -r '.answer'
```

## Quick start: extract

```bash
curl -fsS -X POST https://api.tavily.com/extract \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"urls":["https://en.wikipedia.org/wiki/Artificial_intelligence"],"format":"markdown"}' \
| jq -r '.results[].raw_content'
```

`urls` accepts a single string or an array (max 20 per request).

## jq recipes

```bash
# URLs only
... | jq -r '.results[].url'
# title + snippet, ranked
... | jq -r '.results[] | "# \(.title)\n\(.content)\n\(.url)\n"'
# keep only confident hits (score is relevance, not correctness; post-filter)
... | jq -r '.results[] | select(.score > 0.5) | .url'
# just the AI answer (needs include_answer in the body)
... | jq -r '.answer'
# failed extractions
... | jq -r '.failed_results[]? | "\(.url): \(.error)"'
```

## Errors and cost

- Always quote URLs and use a single-quoted JSON body so the shell leaves `?`, `&`, `"` alone.
- For dynamic bodies, build JSON with `jq -n` (e.g. `jq -nc --arg q "$Q" '{query:$q}'`) instead of string interpolation.
- HTTP status: `400` bad input, `401` bad/missing key, `429` rate limited, `432/433` plan/PayGo limit, `500` server. The body is `{"detail":{"error":"..."}}`. Add `-w '%{http_code}'` or drop `-f` to inspect error bodies.
- Cost: search `basic`/`fast`/`ultra-fast` = 1 credit, `advanced` = 2; extract `basic` = 1 credit / 5 URLs, `advanced` = 2 / 5. Add `"include_usage":true` to the body to see `usage.credits`.

See the reference files for every parameter, depth tables, and tuning tips.
