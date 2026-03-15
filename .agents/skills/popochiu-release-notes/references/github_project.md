# GitHub Project Queries

Reference for fetching Popochiu release data via the `gh` CLI.

---

## 1. Fetch all project items with `gh project item-list`

Prefer this over a raw GraphQL query. The output is flatter and easier to process.

**Important:** `gh project item-list` defaults to **30** items. Always pass an
explicit `--limit` or you will silently miss cards. Use `--limit 500` here so the
query stays safe even if the board grows substantially.

```bash
gh project item-list 1 --owner carenalgas --limit 500 --format json
```

### Parsing the result

The response is a JSON object with an `items` array. For each entry in `.items`:

1. **Filter by Status = "Done"**: use the top-level `status` field.

2. **Get Priority**: use the top-level `priority` field. Expected values are
   usually `Bugfixing`, `Polishing`, `Maturity`, `Nice-to-Have`.

3. **Get issue data** from `content`: `number`, `title`, `url`, `body`, `type`.
   Use the top-level `labels` array for labels.

A jq filter that extracts the fields needed for release notes:

```bash
jq '[
  .items[] |
  {
    number: .content.number,
    title: .content.title,
    url: .content.url,
    body: (.content.body // ""),
    labels: (.labels // []),
    status: .status,
    priority: .priority
  }
] | map(select(.status == "Done" and .number != null))'
```

Useful count check:

```bash
gh project item-list 1 --owner carenalgas --limit 500 --format json |
jq '{
  bugfixing: ([.items[] | select(.status == "Done" and .priority == "Bugfixing" and .content.number != null)] | length),
  polishing: ([.items[] | select(.status == "Done" and .priority == "Polishing" and .content.number != null)] | length),
  maturity: ([.items[] | select(.status == "Done" and .priority == "Maturity" and .content.number != null)] | length),
  nice_to_have: ([.items[] | select(.status == "Done" and .priority == "Nice-to-Have" and .content.number != null)] | length),
  documentation: ([.items[] | select(.status == "Done" and (.labels | index("documentation")) and .content.number != null)] | length)
}'
```

Save the output to a variable or a temp file for use in subsequent steps.

---

## 2. Find linked PRs for an issue

```bash
gh api "repos/carenalgas/popochiu/issues/{number}/timeline" \
  --jq '[
    .[] |
    select(.event == "cross-referenced") |
    select(.source.issue.pull_request != null) |
    {
      pr_number: .source.issue.number,
      pr_title:  .source.issue.title,
      author:    .source.issue.user.login,
      merged:    .source.issue.pull_request.merged_at
    }
  ] | map(select(.merged != null)) | unique_by(.pr_number)'
```

Replace `{number}` with the actual issue number. This returns only **merged** PRs.

---

## 3. Core-team logins (do NOT credit these as external contributors)

```
carenalgas  stickgrinder
```

If a PR author's login is in this list, skip the contributor credit for that entry.

---

## 4. Useful shortcuts

Check the current project status without GraphQL (REST, read-only):
```bash
gh issue list --repo carenalgas/popochiu --state open --json number,title,labels
```

Look up a specific issue:
```bash
gh issue view {number} --repo carenalgas/popochiu --json number,title,body,labels,url
```

List recently merged PRs that reference a given issue (alternative approach):
```bash
gh pr list --repo carenalgas/popochiu --state merged --search "#{number}" \
  --json number,title,author,mergedAt
```
