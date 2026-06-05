# Tavily Extract (`POST /extract`)

Pull clean markdown or text from one or more URLs (max 20 per request). Handles
JavaScript-rendered pages with `extract_depth:"advanced"`.

```bash
curl -fsS -X POST https://api.tavily.com/extract \
  -H "Authorization: Bearer $TAVILY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"urls":["https://example.com/article"],"format":"markdown"}' \
| jq -r '.results[].raw_content'
```

## Body parameters

| Field               | Type             | Default    | Notes                                                              |
| ------------------- | ---------------- | ---------- | ------------------------------------------------------------------ |
| `urls`              | string \| string[] | required | One URL or an array, max 20.                                       |
| `query`             | string           | none       | Rerank extracted chunks by relevance to this intent.               |
| `chunks_per_source` | int 1-5          | 3          | Requires `query`; caps chunks per URL in `raw_content`.            |
| `extract_depth`     | string           | `basic`    | `basic` (fast) or `advanced` (JS pages, tables, embedded content). |
| `format`            | string           | `markdown` | `markdown` or `text`.                                              |
| `include_images`    | bool             | false      | Adds `images` array per result.                                    |
| `include_favicon`   | bool             | false      | Favicon URL per result.                                            |
| `timeout`           | float 1-60       | 10/30      | Max wait per extraction; default 10s basic, 30s advanced.          |
| `include_usage`     | bool             | false      | Adds `usage.credits`.                                              |

## Extract depth

| Depth      | When to use                                  | Cost              |
| ---------- | -------------------------------------------- | ----------------- |
| `basic`    | Simple pages, fast. Try this first.          | 1 credit / 5 URLs |
| `advanced` | JS-rendered SPAs, dynamic content, tables.   | 2 credits / 5 URLs |

## Examples

```bash
# Multiple URLs at once
-d '{"urls":["https://example.com/page1","https://example.com/page2"]}'

# Query-focused: only the relevant chunks, not the whole page
-d '{"urls":["https://example.com/docs"],"query":"authentication API","chunks_per_source":3}'

# JS-heavy page with a longer timeout
-d '{"urls":["https://app.example.com"],"extract_depth":"advanced","timeout":45}'
```

Extract many URLs from a file, one per line:

```bash
jq -nc --argjson urls "$(jq -R . urls.txt | jq -s .)" '{urls:$urls,format:"markdown"}' \
| curl -fsS -X POST https://api.tavily.com/extract \
    -H "Authorization: Bearer $TAVILY_API_KEY" -H "Content-Type: application/json" -d @- \
| jq -r '.results[] | "\n# \(.url)\n\(.raw_content)"'
```

## Tips

- Batch up to 20 URLs per call; split larger lists across calls.
- `query` + `chunks_per_source` returns only relevant chunks instead of full pages.
- Start with `basic`; escalate to `advanced` if content is missing.
- If a `/search` result `.content` snippet already answers the need, skip extract entirely.
- Check `failed_results` for URLs that could not be processed.

## Response shape

```jsonc
{
  "results": [
    { "url": "...", "raw_content": "...", "images": [], "favicon": "..." }
  ],
  "failed_results": [ { "url": "...", "error": "..." } ],
  "response_time": 0.02
}
```
