---
weight: 7008
---

# Contribution Q&As

**Is there a guideline for opening a PR?**
: Yes! Please review the [Coding Standards](coding-standards) section for all the relevant details.

**My issue/PR was closed, and I don’t agree with the maintainers’ decision. What should I do?**
: We never close discussions without providing an explanation. If this happens (likely by mistake), you can still comment on the discussion. If you believe we missed your point, let’s continue the conversation. We’re open to clarifying or revisiting our decisions.

**I customized Popochiu for my game and think it could be useful to others. What should I do?**
: Customizations are why we love FOSS! However, making them accessible to everyone often requires more effort than simply committing your existing code. Start by [reviewing the project board](https://github.com/orgs/carenalgas/projects/1/views/1) to see if your idea is already tracked, requested, or in progress. If not, open a feature request or proposal with a detailed use case, mentioning your willingness to contribute. We’ll discuss implementation details with you and other interested community members, and if you’re ready to work through those details, your contribution will be more than welcome.

**I believe Popochiu needs significant improvement in a specific area, and I have a solution. Should I open a PR?**
: Start by opening an issue. Describe your findings and allow us to understand the context before submitting any code. If we agree there’s room for improvement and align on the course of action, we’ll be thrilled to receive your contribution.

**I'm using an unstable/unsupported version of Godot and worked around some errors. Should I open a PR?**
: It depends. If you’re using a development or unstable version of Godot (other than a release candidate), then **no**: we’ll close the PR without review.  
If you’re testing with a release candidate, we may be interested in reviewing the PR, but you’ll need to test it against the next stable release before it can be merged. Also, the solution must always work with the officially supported Godot version.  
The reason is we’ve already spent time addressing bugs caused by development versions instability that resolved themselves before a new stable version was released.

**Yeah, but since I'm working with a newer version and found a bug, can I at least open an issue so we don’t forget to check it later?**
: Please, do not. Such issue will be closed and labeled as `wontfix`. We can not accept bug reports for unsupported Godot versions, no exceptions.

**How do I know what's the officially supported versions of Godot for Popochiu?
: We strive to keep Popochiu compatible with the latest stable version of Godot. Keep an eye on the [Compatibility Chart](https://github.com/carenalgas/popochiu?tab=readme-ov-file#compatibility-chart) for more precise information.

**Can I contribute even if I’m not familiar with Godot or GDScript?**
: You can contribute in [many different ways](#areas-of-contribution). If you want to get your hands dirty with code, well, it's a great way to learn, so feel free. Only understand that we may require many changes before merging your PR and, in some cases, we may have to reject it entirely. That's part of the game.

**How should I handle licensing for assets or code I contribute?**
: By contributing code to the project, you accept to license it under the very permissive [MIT License](https://github.com/carenalgas/popochiu/blob/develop/LICENSE).  
All content contributed to the project that doesn't fall into the repository, will be licensed under [Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/deed.en) license. We may want to upgrade to newest versions of _CC BY-SA_ should they become available. You will always take full credit as author of the contribution.

**Is there a roadmap or list of priorities for future development?**
: Yes, you can keep an eye on the [project board](https://github.com/orgs/carenalgas/projects/1/views/1). The [Project Management](project-management#project-board-organizations) page hold some information on how to read it.

**Is there a process for suggesting new features?**
: Yes, follow the guidelines in the [Project Management](project-management#how-to-submit-issues) section.

**How do I know if a feature I want to add is already planned or under development?**
: Take a look at the [project board](https://github.com/orgs/carenalgas/projects/1/views/1), specifically into the `Ready` and `In Progress` column.

**How do I write tests for Popochiu?**
: This area is shamefully uncovered. Popochiu doesn’t yet have automated tests coverage. If you’re willing to take on writing tests for the engine or the plugin, we’re absolutely interested in discussing it with you ([find out how to contact us](contact-us)).

**How can I test my changes locally before opening a PR?**
: You will have to do it manually (see above). If you need a throwaway project to do desctructive testing, you can download [Popochiu Sample Game](https://github.com/carenalgas/popochiu-sample-game).

**Are there tasks suitable for beginners in open source or game development?**
: You can find some issues labeled as `Good first issue` in the [project backlog](https://github.com/orgs/carenalgas/projects/1).

**How do you handle conflicts or disagreements on contributions?**
: Like many other FOSS projects Popochiu adopt a [benevolent dictatorship](https://en.wikipedia.org/wiki/Benevolent_dictatorship) government model, with [@mapedorr](https://github.com/mapedorr) being the _benevolent dictator_. It can sound harsh, but maintainers will ultimately decide on how to settle the controversy, with @mapedorr having the last word on it.  
Of course we'll do our best to listen to every voice and we'll ask all parties to provide evidences before settling on a decision.

**Is there a preferred format or style for contributing to the documentation?**
: The documentation is written in MarkDown, and is based on MkDocs. Contribution is also made simpler by a dockerized environment which allows to run this site locally. Please review the [toolchain-and-dependencies#documentation] section for information.

**Are there any coding standards or best practices specific to Popochiu?**
: [Yes](conventions#coding-standards).
