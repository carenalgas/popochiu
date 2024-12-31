---
weight: 7005
---

# title

The purpose of this page is to provide contributors with an overview of Popochiu's history, the project's vision, and best practices for engaging with the maintainers. Understanding these elements ensures that contributions align with the project's architecture and long-term goals.

Like every project, Popochiu benefits from open communication and thoughtful discussions before submitting issues or pull requests, to grow organically and remain maintainable on the long run.

!!! info "Too much talk! I'm a person of action!"
    If you don't want to digest too much _whys_ and want to jump to the _hows_, please read the [Contributions Q&As](#contributions-q&as) section.

    **Warning**: We take no responsibility for frustration, anger, or bitter disappointment if you skip the FAQs and your PRs get rejected!

## Who, why, when

Popochiu is maintained by two people, with the support of a community of contributors. If you’re reading this, you’re probably interested in joining the amazing group of individuals who volunteer their time to make this plugin even better.

The following contains some detailed and essential information on how to contribute. It might feel a bit prescriptive - we’re already telling you what to do and what not to do before you’ve even started - but there’s a good reason for this.

The maintainers of this project have full-time jobs, which, unfortunately, don’t involve Popochiu. While both are entrepreneurs in the video game (@mapedorr) and software development (@stickgrinder) industries - fields that are somewhat related to Popochiu - they maintain this project in their free time. This includes not only creating new features, improving existing ones, and keeping up with Godot’s updates but also engaging with the community and reviewing contributions from others.

We want to ensure that your PRs don’t sit idle for months, and while we prefer not to reject contributions, maintaining a focused and coherent project sometimes requires saying "no". This is how we avoid turning Popochiu into an overly complicated and unmanageable tool.

This section aims to help you understand how you can contribute effectively, making the process smoother for everyone involved. Together, we can continue to make Popochiu great!

## Contribution basics

### Popochiu is an opinionated framework

Throughout Popochiu development, we make deliberate decisions about which features the plugin and engine should expose and which ones they should not. Similarly, we carefully choose how to implement certain functionalities, leveraging specific features of Godot while avoiding others.

Attempting to accommodate every possible use case is neither practical nor desirable. A framework that tries to do everything, in every possible way, becomes overly complex to use, difficult to learn, and costly to maintain.

If you wish to contribute a structural change, an alternative to an existing feature, or support for workflows that deviate from those already provided, the best approach is to first open an issue with a clear proposal (or check if it’s already in the backlog). This allows for a productive discussion with maintainers and the community before submitting a pull request with significant work already done.

By discussing your idea, we can provide a broader perspective and suggest a course of action that aligns with future developments. More often than not, we’ll simply validate your proposal and eagerly await your code with open arms.

### Always assume competence, with a critical stance

As Joel Spolsky aptly noted in his classic post [Things You Should Never Do, Part 1](https://www.joelonsoftware.com/2000/04/06/things-you-should-never-do-part-i/), **_“It’s harder to read code than to write it.”_** Understanding *what* code does is challenging enough, but grasping *why* it was written that way can be even harder.

When exploring Popochiu’s code for the first time, you might find it difficult to navigate and feel that many things were done “wrong”. Rest assured, however, that the architecture reflects careful reasoning, analysis, and - of course - a bit of personal taste. This applies to core as well as contributed code.

Is it perfect? Certainly not. Popochiu began as a solo project on Godot 3.5, and over time, some original decisions have shown their limits. Godot itself evolves, offering new possibilities that outshine older approaches. While some choices hold up well, others are due for improvement.

How can you distinguish between deliberate decisions and past missteps? Communication is key. Reach out to the maintainers on Discord or open an issue to discuss your ideas with the community. What seems like a poor choice might make sense in a broader context. Or it might confirm your instincts, giving you the opportunity to improve things.

By collaborating and discussing upfront, you can ensure your contribution is impactful and warmly welcomed!

### Leave the place better than you found it

We strive to build upon design patterns and best practices, keeping the code clean and readable at all times.

Adventure games are so simple that they used to captivate us on a 286: running one on modern hardware - even a portable console or a phone - is a breeze. This allows us to focus on the performance that really matters: **how efficiently people can read, write, and maintain Popochiu's code**. By prioritizing clarity and maintainability, we make the codebase more stable and predictable for everyone.

Extensive comments, meaningful variable and function names, adherence to coding standards... all essential ingredients to the success of our project.

## Areas of Contribution

When you think about "open source contribution", writing code is probably the first thing that comes to mind. But like any software project, code is just the tip of the iceberg!

Here are some of the many ways you can make a positive impact on Popochiu; even if you're not a developer:

* **Be an active member of the community**: Helping newcomers, pointing people to the right resources, assisting them with troubleshooting, or even just reassuring them that yes, they’ve encountered a bug and yes, it’s already on the board - this kind of support is invaluable. It frees up maintainers and contributors to focus on new features and fosters a friendly, mature environment for everyone.
* **Test and provide feedback**: Your feedback is critical. Engage in discussions, share your experiences, and help us identify what’s a real problem and what’s not. Reporting bugs or issues clearly and with reproducible steps is a huge help for the team.
* **Write or improve documentation**: Documentation takes time - not just to write, but to determine what’s truly valuable for others. If you notice missing information, discover how to achieve something non-obvious, or get clarification on something unclear, take a moment to add it to the documentation! Great code is useless if people don’t know what it does or how to use it.
* **Create assets**: Are you a designer, musician, or visual artist? Consider contributing template game assets to help others get started. Animation skeletons, sound effects, background music, GUI layouts - your creativity could inspire and assist countless developers.
* **Expand the demo game**: Popochiu [comes with a demo game](https://github.com/carenalgas/popochiu-sample-game) to help users explore the plugin before diving into their own projects. It’s small and simple. Why not extend it with more implemented use cases? It’s a great way to help others learn and experiment.
* **Spread the word**: Host game jams, write guides, create video tutorials, or document your Popochiu-based project on your blog. Sharing your experience with the plugin and creating meaningful content can inspire others and bring new developers - and potential contributors - into the Popochiu community.

## Useful knowledge

1. Popochiu is built with Godot, so please take the time to learn the basics of this game engine and it's GDScript 2 language before opening a PR. Extensive knowledge is great of course, but you can contribute even if you're new to this world. In that case, make sure you read the above paragraphs! It's even more important.
2. Specifically, knowing how to use Control nodes and wire them with signals is very useful both when coding custom game UIs and to extend the editor plugin. We strongly recommend you learn about this stuff.
3. Understanding the architecture of the plugin and the engine in broad lines help a lot making sense of its code. Please, review the [Project Overview](project-overview) section for a primer.
4. If you want to contribute structural or big things, knowledge about design patterns and clean code is a great plus. We can't recommend reading [Game Programming Patterns](http://gameprogrammingpatterns.com/) free online book by Robert Nystrom more! Also, understanding [SOLID principles](https://en.wikipedia.org/wiki/SOLID) makes a huge difference.
5. Not all is code: the plugin extends the Godot Editor interface in a variety of ways, exposing custom UI. Skills in interaction or UI design, as well as user/developer experience is invaluable to make Popochiu easy to use to everyone.
6. Last but not least, taking the time to read this whole section of the docs is **very** appreciated.

## Contribution Q&As

**Q:** Is there any guideline for opening a PR?
**A:** Yes! Please read the [Coding Standards](coding-standards) section for all the relevant information about that.

**Q:** I'm working with an unstable/unsupported version of Godot and I have worked around some errors. Should I open a PR?
**A:** It depends. If you are using a development or otherwise unstable version of Godot other than a release candidate, then **no**, we will close the PR without even looking at it. The reason is we already spent time addressing bugs that were due to Godot, not Popochiu and that solved themselves once Godot reached a more stable status.  
If you're testing a release-candidate, we can be interested in reviewing the PR, but you'll have to test it against the next stable release when it's available before it gets merged. Also, the solution should always work on the officially supported Godot version, if it differs from the most recent one.

**Q:** Yeah, but since I saw a bug using a newer version, can I at least open an issue so that we don't forget to check it later down the road?
**A:** **We don't accept bugs related to unsupported versions of Godot**, and close them without review. Period.

**Q:** Creating my game with Popochiu I developed a customization and I think it can be useful to everyone. What should I do?
**A:** Customizations are great, but making them accessible to the broad public may require more work than just committing the code you have at hand. The best course of action is to [review the project board](https://github.com/orgs/carenalgas/projects/1/views/1) and see if what you did is already tracked, requested or in progress. If not, you can open a feature request, with your detailed use case, mentioning that you are willing to take it over. We can discuss implementation details and if you really want to contribute a working solution, you'll be more than welcome.

**Q:** I think Popochiu must be significantly improved in a specific area and I have the solution. Should I open a PR?
**A:** The above: open an issue, describe your findings and allow us to understand the context and make sure you also did, before sending your code over. If we agree that there is room for improvement and we have a shared understanding of the course of action, we'll be more then happy to receive your help.

**Q:** My Issue/PR has been closed and I don't agree with the maintainers' decision. What should I do now?
**A:** First of all, we never close a discussion without providing an explanation. Should this happen (probably by mistake), your can still comment on the discussion. If you think we didn't get the point, let's go on discussing this.
