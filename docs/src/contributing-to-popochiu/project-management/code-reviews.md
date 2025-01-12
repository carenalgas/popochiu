---
weight: 7730
---

# Code reviews

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
