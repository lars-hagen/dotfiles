# Tavily Search (`POST /search`)

Find pages and answer questions. Returns results ranked by relevance score, each with
title, URL, content snippet, and optionally raw page content or an AI answer.

```bash
curl -fsS -X POST https://api.tavily.com/search \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"quantum computing breakthroughs","search_depth":"basic","max_results":10}' \
| jq -r '.results[] | "\(.score)\t\(.url)"'
```

Default to `search_depth:"basic"` and `max_results:10`. Escalate to `advanced` only when
precision matters. Read the per-result `.content` snippet; avoid `include_raw_content` (use
`/extract` on a specific URL when you actually need the full page).

## Body parameters

| Field                        | Type            | Default   | Notes                                                                 |
| ---------------------------- | --------------- | --------- | --------------------------------------------------------------------- |
| `query`                      | string          | required  | Keep under ~400 chars. Think search query, not prompt.                |
| `search_depth`               | string          | `basic`   | `ultra-fast`, `fast`, `basic`, `advanced` (see table below).          |
| `chunks_per_source`          | int 1-3         | 3         | Snippets per source; `advanced` depth only.                           |
| `max_results`                | int 0-20        | 5         | Number of results returned.                                           |
| `topic`                      | string          | `general` | `general`, `news`, `finance`.                                         |
| `time_range`                 | string          | null      | `day`/`week`/`month`/`year` (or `d`/`w`/`m`/`y`).                      |
| `start_date` / `end_date`    | string          | null      | `YYYY-MM-DD`, filters by publish/update date.                         |
| `include_answer`             | bool \| string  | false     | `true`/`basic` quick answer, `advanced` detailed. Adds `.answer`. Skip it if you will synthesize with your own model. |
| `include_raw_content`        | bool \| string  | false     | `true`/`markdown` or `text`. Folds extraction into the search.        |
| `include_images`             | bool            | false     | Adds top-level `images` + per-result `images`.                        |
| `include_image_descriptions` | bool            | false     | Needs `include_images`; adds AI descriptions.                         |
| `include_favicon`            | bool            | false     | Favicon URL per result.                                               |
| `include_domains`            | string[]        | []        | Whitelist, max 300 domains. Supports wildcards, e.g. `*.gov`, `linkedin.com/in`. |
| `exclude_domains`            | string[]        | []        | Blacklist, max 150 domains.                                           |
| `country`                    | string          | null      | Boost a country (lowercase name); `topic:general` only.              |
| `auto_parameters`            | bool            | false     | Tavily auto-tunes params from the query. May cost 2 credits.          |
| `exact_match`                | bool            | false     | Only results containing quoted phrase(s) in the query.                |
| `include_usage`              | bool            | false     | Adds `usage.credits` to the response.                                 |

## Search depth

| Depth        | Speed   | Relevance | Best for                          | Cost     |
| ------------ | ------- | --------- | --------------------------------- | -------- |
| `ultra-fast` | Fastest | Lower     | Real-time chat, autocomplete      | 1 credit |
| `fast`       | Fast    | Good      | Need chunks, latency matters      | 1 credit |
| `basic`      | Medium  | High      | General-purpose (default)         | 1 credit |
| `advanced`   | Slower  | Highest   | Precision, specific facts         | 2 credits |

## Examples

```bash
# Domain-filtered
-d '{"query":"SEC filings Apple","include_domains":["sec.gov","reuters.com"]}'

# Country-boosted general search
-d '{"query":"election results","topic":"general","country":"denmark"}'
```

Dynamic query without interpolation pitfalls:

```bash
Q="latest on $TOPIC"
jq -nc --arg q "$Q" '{query:$q,search_depth:"basic",max_results:10}' \
| curl -fsS -X POST https://api.tavily.com/search \
    -H "Authorization: Bearer $TAVILY_API_KEY" -H "Content-Type: application/json" -d @- \
| jq -r '.results[].url'
```

## Tips

- Break complex questions into sub-queries; one query per intent (issue them as parallel calls).
- `score` measures relevance, not correctness. Post-filter for strict needs: `jq '.results[] | select(.score > 0.5)'`.
- Avoid `include_raw_content`; the `.content` snippet is usually enough, and `/extract` handles the rare full-page need on a known URL.
- `time_range` or `start_date`/`end_date` for recency-sensitive topics.
- `include_domains` to pin trusted sources; `exclude_domains` to drop noise.
- Response also carries `response_time` and (with `include_usage`) `usage.credits`.

## Response shape

```jsonc
{
  "query": "...",
  "answer": "...",        // only with include_answer
  "results": [
    { "title": "...", "url": "...", "content": "...", "score": 0.81, "raw_content": null }
  ],
  "images": [],
  "response_time": 1.67
}
```
