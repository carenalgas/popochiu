---
weight: 9350
---

# Code versioning

The project is versioned in a Git repo, hosted on GitHub.

## Workflow for maintainers and core contributors

The project maintainers follow a branching model inspired by [git-flow](https://www.gitkraken.com/learn/git/git-flow).

The following key branches are vital to the project's workflow:

- **`main`**: Used for releases. Work done on `develop` is merged into `main` and tagged with a version number in the `vX.Y.Z` format.
- **`develop`**: The integration branch (even though no automated tests are currently available). All work should be branched off from and merged back into this branch.
- **`release/<version>`**: These branches are no longer in use and remain for historical reference. Currently, only the 2.0 major version is supported, with a "roll-forward" strategy applied to address any issues in new releases.
- **`gh-pages`**: Contains the documentation you are reading now. This branch is managed by the release automation system and should never be modified manually.

Maintainers work directly on the main repository by branching from `develop` using the following naming conventions:

- **`feature/<issue_number>-easy-to-read-name`**: For developing new features, improvements, or planned work.
- **`fix/<issue_number>-easy-to-read-name`**: For bug fixes, whether urgent or not.
- **`docs/<issue_number>-easy-to-read-name`**: For documentation updates, when done in isolation (documentation for new functions must accompany the related code in the same PR).

Including the issue number in the branch name makes it easy to trace the branch back to its context.

---

## Workflow for other contributors

Contributors working on their own forks are not required to follow this branching model. They can choose to:

- Commit directly to their `develop` branch and open a PR targeting our `develop` branch.
- Create a branch using their preferred naming convention and open a PR targeting our `develop` branch.

While following the same naming conventions is not mandatory, it is encouraged to maintain a clean and organized repository.

---

## Commits conventions

Commit messages **must** follow this format:

`refs #<issue_number>: Clear commit message, explaning why - not what.`

This format allows seamless navigation between commits and issues in the GitHub interface. While GitHub supports other keywords besides refs, we stick to it consistently to avoid confusion or misinterpretation.

Commit messages must:

* Start with a capital letter and end with a full stop.
* Provide informative content explaining why the change was made, not what (since the "what" is visible in the code).

**Good**:

```{.text .code-example-good}
refs #123: Made the function to flip the character's sprite public.
```

**Very Good**:

```{.text .code-example-good}
refs #123: Function to flip the character is now public to simulate the "Confused John Travolta" meme.
```

**Bad**:

```{.text .code-example-bad}
refs #123: changes to the character flip function
```

---

## Pull requests conventions

Pull requests titles must follow [the same format as commit messages](#commit-format).

For large PRs with extensive changes, please use the description field to provide an overview, helping reviewers understand the context and purpose of your work.

!!! warning "Important"
    Always [check the "Allow edits by maintainers" flag](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/allowing-changes-to-a-pull-request-branch-created-from-a-fork#enabling-repository-maintainer-permissions-on-existing-pull-requests) when opening a PR. This option allows maintainers to pull and push changes directly to your PR branch on your fork. It makes collaboration smoother, especially for complex or extensive changes.
