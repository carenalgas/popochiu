---
weight: 9070
---

# Contribution Q&A

**Is there a guideline for opening a PR?**
: Yes! Please review the [Coding Standards](../conventions#pull-requests) section for all the relevant details.

**Can I contribute even if I’m not familiar with Godot or GDScript?**
: You can contribute in [many different ways](../introduction#areas-of-contribution). If you want to dive into coding, contributing is a great way to learn! Just be aware that we may request changes or, in some cases, reject your PR entirely. That’s part of the process.

**Are there tasks suitable for beginners in open source or game development?**
: Look for issues labeled `Good first issue` in the [project backlog](https://github.com/orgs/carenalgas/projects/1). Also evaluate contributing on a `Nice-to-have` feature to start with some non-critical stuff (see the [Backlog section](../project-management/#backlog))

**Is there a preferred format or style for contributing to the documentation?**
: Documentation is written in MarkDown and built with MkDocs and all the relevant information can be found in the [Contributing documentation](../contributing-documentation) section. A dockerized environment is available for running the site locally; see [this section](../toolchain-and-dependencies#documentation) for details on how to run it.

**Are there any coding standards or best practices specific to Popochiu?**
: [Yes](../conventions).

**How do I know if a feature I want to add is already planned or under development?**
: Look at the [project board](https://github.com/orgs/carenalgas/projects/1/views/1), particularly the `Ready` and `In Progress` columns.

**Is there a roadmap or list of priorities for future development?**
: Yes, you can keep an eye on the [project board](https://github.com/orgs/carenalgas/projects/1/views/1). The [Project management](../project-management#project-board-organization) page provide details on how to interpret it.

**Is there a process for suggesting new features?**
: Yes, follow the guidelines in the [Project management](../project-management#how-to-submit-issues) section.

**I believe Popochiu needs significant improvement in a specific area, and I have a solution. Should I open a PR?**
: Start by opening an issue. Describe your findings and allow us to understand the context before submitting any code. If we agree there’s room for improvement and align on the course of action, we’ll be thrilled to receive your contribution.

**I customized Popochiu for my game and think it could be useful to others. What should I do?**
: Customizations are why we love FOSS! However, making them accessible to everyone often requires more effort than simply committing code that works for you on your project.  
Start by [reviewing the project board](https://github.com/orgs/carenalgas/projects/1/views/1) to see if your idea is already tracked, requested, or in progress. If not, open a feature request or proposal with a detailed use case, mentioning your willingness to contribute. We’ll discuss implementation details with you and other interested community members, and if you’re ready to work through those details, your contribution will be more than welcome.

**I'm using an unstable/unsupported version of Godot and worked around some errors. Should I open a PR?**
: It depends. If you’re using a development or unstable version of Godot (other than a release candidate), then **no**: we’ll close the PR without review.  
If you’re testing with a release candidate, we may be interested in reviewing the PR, but you’ll need to test it against the next stable release before it can be merged. Also, the solution must always work with the officially supported Godot version.  
We’ve previously addressed bugs caused by unstable versions of Godot that resolved themselves with later stable releases, which is why we avoid such PRs.

**Yeah, but since I'm working with a newer version and found a bug, can I at least open an issue so we don’t forget to check it later?**
: Please do not. Such issues will be closed and labeled as `wontfix`. We cannot accept bug reports for unsupported Godot versions. No exceptions.

**OK, so how do I know what's the officially supported versions of Godot for Popochiu?**
: We strive to keep Popochiu compatible with the latest stable version of Godot. Check the [Compatibility Chart](https://github.com/carenalgas/popochiu?tab=readme-ov-file#compatibility-chart) for precise information.

**How do you handle conflicts or disagreements on contributions?**
: Like many other FOSS projects, Popochiu follows a [benevolent dictatorship](https://en.wikipedia.org/wiki/Benevolent_dictatorship) model, with [@mapedorr](https://github.com/mapedorr) as the _benevolent dictator_, ultimately having the final say in any controversy. While maintainers are responsible for making every final decisions, we strive to consider all perspectives and ask for evidence before resolving conflicts.

**My issue/PR was closed, and I don’t agree with the maintainers’ decision. What should I do?**
: We never close discussions without providing an explanation. If this happens (likely by mistake), you can still comment on the discussion. If you believe we missed your point, let’s continue the conversation. If you think your perspective reflects a broader community view, invite others to join the discussion in the issue’s comments. This helps us consider your proposal from a new perspective. We’re always open to clarifying or revisiting our decisions if it's for the greater good.

**Who are Core Contributors, and how do I become one?**  
: Core contributors are regular contributors who’ve done significant work on the project and shown they’re reliable, committed, and great at teamwork. They are granted write access to the main repository, so they don’t need to work on their own fork, making things easier for everyone.  
Becoming a core contributor is not a prize or reward, and should not be a goal. It naturally follows from consistent and meaningful involvement in the project.

**How do I write tests for Popochiu?**
: This area is shamefully uncovered. Popochiu currently lacks automated tests coverage. If you’re willing to write tests for the engine or the plugin, we’d love to discuss it with you ([find out how to contact us](../get-in-touch)).

**How can I test my changes locally before opening a PR?**
: Testing must be done manually (see above). If you need a throwaway project for testing, download the [Popochiu Sample Game](https://github.com/carenalgas/popochiu-sample-game).

**How should I handle licensing for assets or code I contribute?**
: By contributing code to the project, you agree to license it under the very permissive [MIT License](https://github.com/carenalgas/popochiu/blob/develop/LICENSE).  
Non-code contributions are licensed under the [Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/deed.en). Future updates to this license may occur, but your authorship will always be credited.
