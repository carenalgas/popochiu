---
name: Release [Reserved]
about: Release flight list - Reserved for maintainers
title: Release X.Y.Z
labels: chore
assignees: stickgrinder,mapedorr

---

### Description

Follow the steps below to prepare a new release of Popochiu.

### Cheklist

#### Preliminary steps

* [ ] Check all open PRs to make sure everything done and approved is merged to `develop`
* [ ] Write release notes by reviewing the [next release](https://github.com/orgs/carenalgas/projects/1/views/8) board.
* [ ] Write release announcement for Discord and Itch
* [ ] Define the release in the format `vX.Y.Z` (**remember the `v`**); let's call this RELEASE

#### Release commit

* [ ] Add release notes in markdown format into a `/release-notes/<RELEASE>.md` file
* [ ] Update the plugin version in the `plugin.cfg` file
* [ ] Commit everything and push to `develop` in the format `refs #<issue_number>:`

#### Release workflow

* [ ] Open a PR to main and merge it (**NEVER SQUASH or the branches will diverge!**)
* [ ] Pull main locally
* [ ] Tag main with `<RELEASE>` (e.g. the tag can be `v1.2.3`, remember the `v`) and `git push --tags`
* [ ] Watch the hamsters run... (both the `release` and `deploy-docs` pipelines)
  * [ ] Check the docs have been deployed. If not, do it manually issuing `make docs-deploy` from within the docs directory

#### Post-release steps

* [ ] Post release announcement on Discord and Itch
* [ ] Celebrate, get drunk, have fun
