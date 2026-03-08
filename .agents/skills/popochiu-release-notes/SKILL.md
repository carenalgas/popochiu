---
name: popochiu-release-notes
description: Write release notes for a new Popochiu version. Use this skill whenever the user says "write release notes for vX.X.X", "draft the release notes", "prepare the release", "it's time to tag a new version", or anything indicating a Popochiu release is being prepared. The skill fetches "Done" issues from the Carenalgas GitHub project, groups them by configured priority, credits external contributors, and produces a polished draft in the team's characteristic voice — ready to review and commit to release-notes/.
---

# Popochiu Release Notes

Draft release notes for a new version of Popochiu by fetching "Done" issues from
the GitHub project, grouping them by priority into sections, crediting contributors,
and writing the first draft directly to the target file so the user can iterate on
it in the editor.

## Context

- **Repo**: `carenalgas/popochiu`
- **GitHub Project**: `https://github.com/orgs/carenalgas/projects/1/`
- **Draft output location**: `release-notes/vX.X.X.md`
- Uses the `gh` CLI for all GitHub data. See `references/github_project.md` for
  the exact queries.

---

## Workflow

### Step 1 — Get the version number

Extract the target version from the user's prompt (e.g. "write release notes for
v2.0.4" → `v2.0.4`). If not provided, ask for it before proceeding.

---

### Step 2 — Fetch "Done" issues from the GitHub project

Use `gh project item-list` instead of hand-written GraphQL. It is easier to read,
less error-prone, and already flattens the custom project fields into predictable
JSON keys like `status`, `priority`, `labels`, and `content`.

**Important:** `gh project item-list` defaults to **30 items**. Always pass an
explicit limit large enough for the full board, e.g. `--limit 500`.

Run the command described in `references/github_project.md` to get all project
items whose **Status** field is `"Done"`.

For each issue, collect:
- Issue **number**, **title**, **URL**
- **Priority** custom field value: one of `bugfixing`, `polishing`, `maturity`,
  `nice-to-have`
- **Labels** (look for `documentation`)
- **Body** (scan for breaking-change language: "breaking", "migration required",
  "upgrade steps", "you must", etc.)

---

### Step 3 — Find linked PRs and external contributors

For each issue, check for merged PRs that reference it:

```bash
gh api "repos/carenalgas/popochiu/issues/{number}/timeline" \
  --jq '[.[] | select(.event == "cross-referenced") |
         select(.source.issue.pull_request != null) |
         {pr: .source.issue.number, author: .source.issue.user.login}] | unique'
```

Consider a contributor **external** (worth crediting) when their GitHub login does
**not** appear in the list of core-team members: `carenalgas`, `stickgrinder`,
`matjam`, `quovernight`. When in doubt, omit the credit — it's better to miss one
than to misattribute.

---

### Step 4 — Map issues to sections

| Priority value   | Section         |
|------------------|-----------------|
| `bugfixing`      | **Fixes**       |
| `polishing`      | **Improvements**|
| `maturity`       | **Improvements**|
| `nice-to-have`   | **Improvements**|

**Override rules (applied before the table above):**
- Issue has a `documentation` label, or title/body clearly describes a docs change
  → **Documentation** section (prose paragraph, not bullet list)
- Issue body contains breaking-change language → flag for **Final Notes** and
  summarise what users need to do before/after upgrading

If an issue's priority is missing or ambiguous, make a best-effort call and note it
at the end of the draft so the user can sanity-check.

Before drafting, do a quick count by section so truncation bugs are obvious:
- Count `Bugfixing` issues that will become **Fixes**
- Count `Polishing`, `Maturity`, and `Nice-to-Have` issues that will become
  **Improvements**
- Count documentation-labeled issues that will be absorbed into
  **Documentation**

Report these counts in the summary below the draft.

---

### Step 5 — Write the draft

Use this structure (omit sections that have no entries):

```markdown
# Popochiu vX.X.X

[Intro paragraph]

## Fixes

- [Entry description](issue_url).
- [Entry description](issue_url) — Thanks to [@username](https://github.com/username).

## Improvements

- [Entry description](issue_url).

## Documentation

[Short prose paragraph summarising the documentation work.]

## Final Notes

[Upgrade instructions or important caveats for users.]
```

**Entry format:**
- Link text is a natural-language description of the fix/improvement, derived from
  the issue title. Shorten or rephrase if the title is long or technical.
- Contributor credit goes inline at the end of the bullet, only for external
  contributors: `— Thanks to [@username](https://github.com/username).`
- If multiple external contributors worked on the same issue, list them all.

**Writing the intro paragraph:**
Write 2–4 sentences in the Popochiu team's voice: first-person plural ("we"),
warm, enthusiastic, occasionally playful. Look at the mix of issues to pick a
theme:
- Mostly bugfixes → small-but-solid maintenance release ("Another round of polish…")
- Big new features → celebrate them prominently
- Mixed → highlight the most noteworthy items

Calibrate enthusiasm to release size. A two-fix patch doesn't need an exclamation
parade; a major feature drop can afford more fanfare. Study the existing notes in
`release-notes/` for tone reference if needed.

For the **Documentation** section, write prose (2–4 sentences) instead of bullets,
as seen in v2.0.3. Describe what changed and why it matters to users/contributors.

For **Final Notes**, be clear and practical: what must the user do, in what order,
and what can go wrong. Mirror the upgrade-instruction style in v2.0.0.

---

### Step 6 — Write the draft file and report back

Write the complete draft directly to `release-notes/vX.X.X.md`.

If the file already exists, update it in place instead of asking the user to copy
and paste the text manually.

Then tell the user the file has been written and add a short summary note:
- Total issues included and how they were distributed across sections
- Any issues you couldn't categorise confidently (so the user can verify)
- Any issues where no contributor could be determined

The default workflow is now editor-first: write the initial draft to the file,
then iterate with the user in the editor.
