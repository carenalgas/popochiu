---
weight: 7050
---

# Project management

We want Popochiu to be a high-quality FOSS project, much like Godot. We believe that alongside useful features and comprehensive documentation, a transparent and well-structured project management approach is essential to ensure its success.

By adopting a consistent workflow, doing our best to share our goals, and ensuring transparency in our processes, we aim to benefit both adopters and contributors. Adopters can better assess if Popochiu meets their needs, while contributors can engage with the project in an organized and productive manner.

## Issue Tracking

All development activities for Popochiu are [tracked on GitHub Projects](https://github.com/orgs/carenalgas/projects/1).

We’ve organized issues and PRs into various views, created templates for different issue types, and shifted from a milestone-based approach to a _release train_ model. While we can’t guarantee perfectly regular releases, we aim to ship updates at least every other month, ensuring a steady flow of bug fixes, polish, and new features.

### Project Board Organization

Our _pull_ system works perfectly with the release train model, which is why our main project backlog is managed through a set of Kanban-style boards and views. We can decide to add or remove some views,  but certain ones are here to stay. Let's review them:

#### Backlog

The **Backlog** board is the most important: it contains all the tasks we plan to work on.  
Each column represents the current **status** of an issue:

1. **Backlog**: Features we plan to work on in the long term but that still need analysis, design, or more details. Items near the top of this column are higher priority and will be planned soon.
2. **Ready**: These issues are fully detailed and _ready to be worked on_. They represent the tasks we’ll focus on for upcoming releases.
3. **In Progress**: Quite self-explanatory, huh?! These items will likely be released soon, possibly in the next update.
4. **Done**: Completed items that are queued for release.

In addition, we categorize issues into four **lanes** based on their type and priority. From top to bottom:

1. **Bugfixing**: These are both urgent and important. They block the correct functioning of the plugin and need immediate attention.
2. **Polishing**: These issues are less urgent but still important. They’re usually small, low-effort improvements that enhance the quality of life for users and smooth out the tool’s rough edges. They may not be flashy, but they make the plugin _feel_ high quality.
3. **Maturity**: Features or improvements that require significant effort. Working on these items makes the plugin more capable and feature-rich.
4. **Nice-to-Have**: These issues have limited impact or are valuable to only a small group of users. While not critical, they can still be worth pursuing—great for contributors who want to stretch their skills without blocking core development.

We use these categories to achieve two goals: ensuring a healthy mix of bug fixes, polish, and new features; helping users understand how we prioritize issues in the project’s vision.  
On one side, indeed, it’s easy for urgent bug fixes and shiny new features to overshadow the importance of maintenance and refinement. On the other side, users are entitled to decide whether to wait for a feature to be implemented in Popochiu or create their own custom solution for their games.

#### Next Release

This table lists the issues we consider candidates for the next release. We can't be sure everything will be finished on time, but the main goal of this list is to keep everyone in the loop about what to expect in the near future.

#### Release board

This is a convenient view on what's ready to be released. When we publish a new version, we can check all the "Done" work and change its status to "Released". This makes it easier to write release notes and announcements without forgetting some contributions.

### How to submit issues

When opening an issue, please select the appropriate template based on the type of issue you’re reporting:

- **Bug Report**: Use this to report any issues with the current behavior of Popochiu.
- **Feature Request**: Use this to suggest new features or improvements to existing ones.
- **Proposal (RFC)**: For high-level discussions on ideas or potential changes. This is particularly useful for collecting feedback on decisions before they’re finalized.

!!! warning "Reserved Issue Types"
      The following issue types are reserved for maintainers:

      - **Core Feature**: These are official features detailed and defined by the core team.
      - **Task**: These are maintenance tasks that are managed directly by maintainers.

      Please do not open issues of these types.

When opening an issue, please:

1. **Use the provided templates as much as possible**
   Always stick to the format provided by the selected template, unless you have valid and justified reasons not to. This helps maintain consistency and ensures no critical information is missing.

2. **Be clear and reproducible**
   If you’re reporting a bug, include step-by-step instructions to reproduce the issue. Clearly explain what you expected to happen versus what actually occurred. Screenshots, logs, or videos can also be incredibly helpful.

3. **Detail your thought process**
   For feature requests and proposals, explain your reasoning. Provide clear use cases, describe the problem you’re trying to solve, and, if possible, include examples or mockups. The more context you provide, the better we can evaluate your suggestion.

4. **Keep it focused**
   Each issue should address a single topic. Avoid combining multiple bugs or feature requests into one issue, as this can make tracking and addressing the problem more difficult

5. **Check for duplicates**
   Before opening a new issue, search the issue tracker to ensure your topic hasn’t already been reported. If you find a similar issue, feel free to add your input there instead of creating a duplicate.

6. **Bring other community members in the loop**
   Remember, the issue tracker is a shared space for the community. Feel free to point the issue out on discord and invite other members to join the discussion. Evidence and feedback are gold to make sensible decisions about the future of the plugin.

## Code reviews

Code reviews are handled by the project maintainers (who have permission to merge to develop), based on their availability and familiarity with the topic. You can assign your PR to @mapedorr, @stickgrinder, or both, and we’ll make sure to review it as soon as possible.

If we request changes, we’ll do our best to make the process smooth. For smaller adjustments, we’ll provide code suggestions you can easily accept (if you agree with them). For more structural issues, we’ll add explanations or questions to open a discussion. In rare cases, we might make direct commits to your fork (which is why we ask you to check the "Allow edits from maintainers" flag when opening a PR).

This last option is only used if we hit a roadblock during a complex exchange and it’s faster to address the issue directly. The goal is always to collaborate, not to override your work.

!!! tip "Reviewing code is both rewarding and instructive!"
      We encourage the community and other contributors to share their feedback during code reviews.

      If you have trustworthy buddies in the community, feel free to involve them in the review process. This not only enhances the quality of the final result but also helps others learn more about the inner workings of Popochiu.  
      Similarly, don’t hesitate to comment on others’ PRs if you have something meaningful to add or questions to ask. Engaging in this way is indeed a fantastic way to contribute!

Reviews are typically handled within a few days, but since we work in our free time, they can stay untouched for a bit more. Don't worry and feel free to poke us by mentioning us in a comment. It's appreciated, should we forget to check your work out!

Depending on how long a review takes, we can ask you to rebase your code on develop, if the branches diverge to the point they can't be merged automatically.

!!! warning
      In these cases, **never** solve the issue by merging develop back on your branch: **always rebase**!

To speed up complex reviews, we suggest opening a draft PR while you're working on an issue and explicitly asking for feedback on your work in progress. This has multiple benefits: it helps us catch potential issues early before you’ve completed all the work (less frustration), prevents the need to review large PRs all at once (less cognitive load), and reduces downtime between finishing your changes and having them merged into develop (less waiting from your side).

Last important points:

- Please, make sure you have tested your implementation before asking for review.
- Remember: code reviews are all about improving the code and the solution's architecture, never about personal criticism.

## Definition of Done

A task, issue or contribution is considered _done_ when:

1. All knwon edge cases, regressions or limitations are addressed  - or documented if unresolvable.
2. The code follows naming conventions and project standards.
3. The solution has been tested locally and works as intended.
4. Documentation changes and additions are included in the PR.
5. Necessary migrations, if any, are included in the PR.
6. There is no leftover commented-out code, print statements, or temporary work artifacts.
7. Non-trivial code portions include meaningful comments explaining its purpose and reasoning.

Use this as a checklist before stating that your contribution is complete.
