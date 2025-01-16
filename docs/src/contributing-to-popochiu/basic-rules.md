---
weight: 7010
---

# Introduction

The purpose of this page is to provide contributors with an overview of Popochiu's history, the project's vision, and best practices for engaging with the maintainers. Understanding these elements ensures that contributions align with the project's architecture and long-term goals.

Like every project, Popochiu benefits from open communication and thoughtful discussions before submitting issues or pull requests, to grow organically and remain maintainable on the long run.

!!! info "Too much talk! I'm a person of action!"
    If you don't want to digest too much _whys_ and want to jump to the _hows_, please read the [Contribution Q&As](../qna) page.

    **Warning**: We take no responsibility for frustration, anger, or bitter disappointment if you skip reading important informations and your PRs get rejected!

---

## Who, why, when

Popochiu is maintained by two people, with the support of a community of contributors. If you’re reading this, you’re probably interested in joining the amazing group of individuals who volunteer their time to make this plugin even better.

The following contains some detailed and essential information on how to contribute. It might feel a bit prescriptive - we’re already telling you what to do and what not to do before you’ve even started - but there’s a good reason for this.

The maintainers of this project have full-time jobs, which, unfortunately, don’t involve Popochiu. While both are entrepreneurs in the video game (@mapedorr) and software development (@stickgrinder) industries - fields that are somewhat related to Popochiu - they maintain this project in their free time. This includes not only creating new features, improving existing ones, and keeping up with Godot’s updates but also engaging with the community and reviewing contributions from others.

We want to ensure that your PRs don’t sit idle for months, and while we prefer not to reject contributions, maintaining a focused and coherent project sometimes requires saying "no". This is how we avoid turning Popochiu into an overly complicated and unmanageable tool.

This section aims to help you understand how you can contribute effectively, making the process smoother for everyone involved. Together, we can continue to make Popochiu great!

---

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

Adventure games are so simple that they used to captivate us on an [80286 with 640kb of base RAM](https://youtu.be/eesSmqsfXGU?si=5q4zU-s-8b8z1AL6): running one on modern hardware - even a portable console or a phone - is a breeze. This allows us to focus on the performance that really matters: **how efficiently people can read, write, and maintain Popochiu's code**. By prioritizing clarity and maintainability, we make the codebase more stable and predictable for everyone.

Extensive comments, meaningful variable and function names, adherence to coding standards... all essential ingredients to the success of our project.

---

## Areas of Contribution

When you think about "open source contribution", writing code is probably the first thing that comes to mind. But like any software project, code is just the tip of the iceberg!

Here are some of the many ways you can make a positive impact on Popochiu; even if you're not a developer:

* **Be an active member of the community**: Helping newcomers, pointing people to the right resources, assisting them with troubleshooting, or even just reassuring them that yes, they’ve encountered a bug and yes, it’s already on the board - this kind of support is invaluable. It frees up maintainers and contributors to focus on new features and fosters a friendly, mature environment for everyone.
* **Test and provide feedback**: Your feedback is critical. Engage in discussions, share your experiences, and help us identify what’s a real problem and what’s not. Reporting bugs or issues clearly and with reproducible steps is a huge help for the team.
* **Write or improve documentation**: Documentation takes time - not just to write, but to determine what’s truly valuable for others. If you notice missing information, discover how to achieve something non-obvious, or get clarification on something unclear, take a moment to add it to the documentation! Great code is useless if people don’t know what it does or how to use it.
* **Create assets**: Are you a designer, musician, or visual artist? Consider contributing template game assets to help others get started. Animation skeletons, sound effects, background music, GUI layouts - your creativity could inspire and assist countless developers.
* **Expand the demo game**: Popochiu [comes with a demo game](https://github.com/carenalgas/popochiu-sample-game) to help users explore the plugin before diving into their own projects. It’s small and simple. Why not extend it with more implemented use cases? It’s a great way to help others learn and experiment.
* **Spread the word**: Host game jams, write guides, create video tutorials, or document your Popochiu-based project on your blog. Sharing your experience with the plugin and creating meaningful content can inspire others and bring new developers - and potential contributors - into the Popochiu community.

---

## Useful Knowledge

1. Popochiu is built with Godot, so it’s essential to [learn the basics of the engine](https://docs.godotengine.org/en/latest/) and its [GDScript language](https://docs.godotengine.org/en/latest/tutorials/scripting/gdscript/index.html) before opening a PR. While extensive knowledge is a bonus, you can still contribute even if you’re new to this world—just make sure to review the previous sections carefully. It’s even more important in that case!  
2. Specifically, familiarity with **Control nodes** and how to connect them using signals is incredibly helpful, both for coding custom game UIs and extending the editor plugin. We highly recommend taking the time to learn these concepts.  
3. A broad understanding of the plugin and engine architecture will make navigating the code much easier. Be sure to check out the [Project Overview](project-overview) section for a primer.  
4. For those contributing structural or large-scale features, knowledge of **design patterns** and **clean code principles** is a huge advantage. We strongly encourage reading Robert Nystrom’s free online book, [Game Programming Patterns](http://gameprogrammingpatterns.com/). Familiarity with the [SOLID principles](https://en.wikipedia.org/wiki/SOLID) is also highly valuable.  
5. Not everything is about code! The plugin extends the Godot Editor with custom UIs, so skills in **interaction design**, **UI design**, or **user/developer experience** can significantly improve Popochiu’s usability for everyone.  
6. Finally, taking the time to read this entire section of the documentation is **highly** appreciated. It makes everything easier for everyone involved.  
