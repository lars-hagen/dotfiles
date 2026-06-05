# Tavily Map (`POST /map`)

Graph-based site traversal that returns ONLY the URL list, no page content. Same crawl
engine as `/crawl` (bounded by depth/breadth/limit and path/domain filters) but it skips
extraction, so it is far cheaper and faster. Use it to see a site's structure before
committing extraction credits: map first, then hand the URLs you want to `/extract`.

Not for getting page text (use `/extract` or `/crawl`) or finding a page by topic (use
`/search`).

```bash
curl -fsS -X POST https://api.tavily.com/map \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"url":"docs.example.com","max_depth":1,"limit":50}' \
| jq -r '.results[]'
```

`results` is a flat array of URL strings (not objects), so parsing is trivial and there is
no control-character caveat like crawl has.

## Body parameters

| Field             | Type         | Default  | Notes                                                                |
| ----------------- | ------------ | -------- | -------------------------------------------------------------------- |
| `url`             | string       | required | Root URL to start from.                                              |
| `instructions`    | string       | none     | Natural-language focus; keeps only semantically relevant URLs.       |
| `max_depth`       | int 1-5      | 1        | How far from the root to explore.                                    |
| `max_breadth`     | int 1-500    | 20       | Links followed per page.                                             |
| `limit`           | int >=1      | 50       | Total pages traversed before stopping. Always set this.             |
| `select_paths`    | string[]     | null     | Regex of paths to include, e.g. `["/docs/.*","/api/v1.*"]`.          |
| `exclude_paths`   | string[]     | null     | Regex of paths to exclude, e.g. `["/blog/.*"]`.                      |
| `select_domains`  | string[]     | null     | Regex of domains/subdomains to include, e.g. `["^docs\\.x\\.com$"]`. |
| `exclude_domains` | string[]     | null     | Regex of domains to exclude.                                         |
| `allow_external`  | bool         | true     | Follow links to other domains. Set false to stay on-site.            |
| `timeout`         | float 10-150 | 150      | Max wait for the whole map.                                          |
| `include_usage`   | bool         | false    | Adds `usage.credits`.                                                |

No `extract_depth`, `format`, `chunks_per_source`, or image fields: map never extracts.

## Map then extract

The common pattern is cheap discovery followed by targeted extraction of the pages you
actually want, so you never pay to extract a whole site.

```bash
# 1. discover URLs under /documentation/
urls=$(curl -fsS -X POST https://api.tavily.com/map \
  -H "Authorization: Bearer $TAVILY_API_KEY" -H "Content-Type: application/json" \
  -d '{"url":"docs.example.com","select_paths":["/documentation/.*"],"max_depth":2,"limit":50}' \
| jq -c '[.results[]]')

# 2. extract just those (max 20 per /extract call; slice if more)
curl -fsS -X POST https://api.tavily.com/extract \
  -H "Authorization: Bearer $TAVILY_API_KEY" -H "Content-Type: application/json" \
  -d "$(jq -nc --argjson u "$urls" '{urls: $u[:20], format:"markdown"}')" \
| jq -r '.results[] | "\n# \(.url)\n\(.raw_content)"'
```

Narrow the set with `instructions` instead of pulling every URL when you only care about
one topic:

```bash
curl -fsS -X POST https://api.tavily.com/map \
  -H "Authorization: Bearer $TAVILY_API_KEY" -H "Content-Type: application/json" \
  -d '{"url":"docs.example.com","instructions":"authentication and API keys","max_depth":2,"limit":50}' \
| jq -r '.results[]'
```

## Cost and safety

- Map bills discovery only (no extraction), so it is much cheaper than crawl: roughly 1
  credit per ~10 URLs traversed. Add `"include_usage":true` to confirm via `usage.credits`.
- `limit` is the runaway guard; `max_depth`/`max_breadth` shape the tree. Keep them small first.
- `select_paths` only matches links reachable within `max_depth`. If map returns few/0
  URLs, the targets were deeper than `max_depth` allowed; raise depth or loosen paths.
- `instructions` adds a semantic pass that can slow the call noticeably; plain structural
  maps return in well under a second.
- HTTP: `403` means the URL is not supported. Other codes as in the main skill.

## Response shape

```jsonc
{
  "base_url": "docs.example.com",
  "results": ["https://docs.example.com/", "https://docs.example.com/guide", "..."],
  "response_time": 0.07
}
```
