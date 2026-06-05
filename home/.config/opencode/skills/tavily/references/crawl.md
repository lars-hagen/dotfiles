# Tavily Crawl (`POST /crawl`)

Graph-based site traversal with built-in extraction. Give it a root URL; it follows links
(bounded by depth/breadth/limit and path filters) and returns each page's content. Use it
for "everything under `/docs/`" style bulk extraction when you do NOT have the URL list.

Not for known URLs (use `/extract`) or finding a page by topic (use `/search`).

```bash
curl -fsS -X POST https://api.tavily.com/crawl \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"url":"docs.example.com","max_depth":1,"limit":20}' \
| jq -r '.results[] | "\n# \(.url)\n\(.raw_content)"'
```

Start conservative (`max_depth:1`, `limit:20`) and scale up. Always set `limit`.

> Parsing caveat: crawl `raw_content` can contain literally unescaped control characters,
> which makes strict parsers reject the whole response. If `jq` errors with
> `Invalid string: control characters ... must be escaped`, parse with Python
> `json.loads(..., strict=False)` (see the bulk-save recipe below). The simple `jq`
> pipes above work for clean responses; the Python path is the robust fallback.

## Body parameters

| Field               | Type       | Default    | Notes                                                                |
| ------------------- | ---------- | ---------- | -------------------------------------------------------------------- |
| `url`               | string     | required   | Root URL to start from.                                              |
| `instructions`      | string     | none       | Natural-language focus; reranks/discovers semantically.              |
| `chunks_per_source` | int 1-5    | 3          | Requires `instructions`; caps relevant chunks per page.              |
| `max_depth`         | int 1-5    | 1          | How far from the root to explore.                                    |
| `max_breadth`       | int 1-500  | 20         | Links followed per page.                                             |
| `limit`             | int >=1    | 50         | Total pages processed before stopping. Always set this.             |
| `select_paths`      | string[]   | null       | Regex of paths to include, e.g. `["/docs/.*","/api/v1.*"]`.          |
| `exclude_paths`     | string[]   | null       | Regex of paths to exclude, e.g. `["/blog/.*"]`.                      |
| `select_domains`    | string[]   | null       | Regex of domains/subdomains to include, e.g. `["^docs\\.x\\.com$"]`. |
| `exclude_domains`   | string[]   | null       | Regex of domains to exclude.                                         |
| `allow_external`    | bool       | true       | Follow links to other domains. Set false to stay on-site.            |
| `extract_depth`     | string     | `basic`    | `basic` or `advanced` (JS pages, tables).                            |
| `format`            | string     | `markdown` | `markdown` or `text`.                                                |
| `include_images`    | bool       | false      | Image URLs per page.                                                 |
| `include_favicon`   | bool       | false      | Favicon URL per page.                                                |
| `timeout`           | float 10-150 | 150      | Max wait for the whole crawl.                                        |
| `include_usage`     | bool       | false      | Adds `usage.credits`.                                                |

## Default: crawl and use the content

Like search and extract, the normal path is to crawl and read the returned content (feed
it to the model), not to write files. Add `instructions` + `chunks_per_source` to get only
the relevant chunks per page instead of whole pages, which keeps context small.

```bash
curl -fsS -X POST https://api.tavily.com/crawl \
  -H "Authorization: Bearer $TAVILY_API_KEY" -H "Content-Type: application/json" \
  -d '{"url":"docs.example.com","instructions":"authentication and API keys","chunks_per_source":3,"max_depth":2,"limit":20}' \
| jq -r '.results[] | "\n# \(.url)\n\(.raw_content)"'
```

## Optional: save pages to disk

Only when you actually want offline files (e.g. downloading a docs section). Parse with
Python `strict=False` so unescaped control characters in `raw_content` do not break it
(strict jq would reject the whole response).

```bash
mkdir -p ./docs
curl -fsS -X POST https://api.tavily.com/crawl \
  -H "Authorization: Bearer $TAVILY_API_KEY" -H "Content-Type: application/json" \
  -d '{"url":"docs.example.com","select_paths":["/docs/.*"],"max_depth":2,"limit":50}' \
| python3 -c '
import sys, json, re
data = json.loads(sys.stdin.read(), strict=False)
for r in data["results"]:
    name = re.sub(r"[/?#]", "_", re.sub(r"^https?://", "", r["url"])) + ".md"
    with open(f"./docs/{name}", "w") as f:
        f.write(r.get("raw_content") or "")
print("wrote", len(data["results"]), "pages")
'
```

## Cost and safety

- Crawl bills extraction (`basic` 1 credit / 5 pages, `advanced` 2 / 5). Adding
  `instructions` raises discovery cost to 2 credits / 10 pages. Add `"include_usage":true`
  to watch `usage.credits`.
- `limit` is the runaway guard: it caps total pages. `max_depth` and `max_breadth` shape
  the tree; keep them small first.
- `select_paths` only matches links reachable within `max_depth`. If a crawl returns 0
  pages, the target paths were deeper than `max_depth` allowed; raise depth or loosen paths.
- Run [`/map`](map.md) first if you want to see structure (URL list only) before committing extraction credits.
- HTTP: `403` means the URL is not supported for crawling. Other codes as in the main skill.
- `raw_content` may include unescaped control characters; if `jq` chokes, parse with
  Python `json.loads(text, strict=False)` as in the bulk-save recipe.

## Response shape

```jsonc
{
  "base_url": "docs.example.com",
  "results": [
    { "url": "...", "raw_content": "...", "favicon": "..." }
  ],
  "response_time": 1.23
}
```
