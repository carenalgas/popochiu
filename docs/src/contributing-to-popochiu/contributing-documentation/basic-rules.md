---
weight: 7710
---

# Basics

Contributing to Popochiu's documentation is as important as contributing to the codebase itself. An accessible, clear, well-maintained and up-to-date documentation eenables game makers can make the most out of the project. If you are not so much into code (or even if you are) you can give back to the project by helping us with this vital aspect of Popochiu.

The documentation maintainer is **@stickgrinder**.

## Basic rules

1. **Tools**: Take the time to get familiar with [MkDocs](https://www.mkdocs.org/) and Markdown format.
2. **Language**: Documentation must be written in clear and grammatically decent English.
3. **Tone**: Maintain an informal but clear and accessible tone. Humor is great, but avoid unnecessary jokes or digressions.
4. **Respectfulness**: Content and examples must be respectful and appropriate for all audiences (keep it safe for both family and work).
5. **Use of AI Tools**: While LLMs can be used for grammar checking, improving phrasing or generating examples, they must **never** be used to generate or expand content from scratch. Also, the contributor must **always** check the generated content and make sure it's fit for purpose.

---

## Previewing the documentation locally

To contribute to the documentation, the first essential step is to make sure you can preview your changes locally. A Docker-based environment is available for this purpose. This setup allows you to test your changes in real-time and ensures the output matches what will be published.

For instructions on setting up the local preview environment, refer to the specific [Run the documentation locally](../../toolchain-and-dependencies#run-the-documentation-locally) section.

!!! note
    If you're not familiar with Docker and have never installed it before, this step may seem like a bit of a pain, but trust us: it's a _do once and forget_ process and it will make everything easier.

---

## When to Contribute to Documentation

Documentation contributions are critical whenever:

1. A **new feature** is developed.
2. The **public interface** of an existing feature is modified, including GUI changes in the plugin or public methods in the engine.

The rule of thumb is that, if you add or change something that game developers will have to know, than you have to document it!

!!! tip "Documenting the Engine API"
    Documenting Engine API elements like functions, signals, and variables is often as simple as adding a well formatted and complete [documentation comment](../../conventions/comments) to your public code. Of course, from time to time, it may require some more work, like updating an existing guide or tutorial.

!!! tip "Updating visual assets"
    When the editor interface changes or get some new feature, screenshots or other visuals may need to be updated.  
    Taking consistent screenshots is a tough job: we recommend using the **Popochiu Sample Game**. Clone the repo and update the `addons/popochiu` folder with your changes.

    Remember to annotate the screenshots if it adds to clarity and readability of your explanation. If possible use Godot dark theme and red annotations for consistency.

---

## Understanding Documentation Types

Before you start writing, it's important to understand what type of documentation you’re contributing to. Popochiu’s documentation broadly follows the categories defined by the [Diátaxis framework](https://diataxis.fr/), by which content fall into one of four types (each with a specific _user's main goal_ in brackets):

- **Tutorials**: Step-by-step guides that show how stuff work (**learning**)
- **How-to Guides**: Focused, task-oriented instructions to achieve a certain goal . think recipes (**achieving a goal**).  
- **Explanations**: Conceptual overviews and background information (main goal: **understanding**)
- **Reference**: Well-organized list of techical details and descriptions (main goal: **finding information**)

### Documentation Sections and Content Types

Each section in Popochiu's documentation aligns with a type from the Diátaxis framework. Here's a quick overview:

| **Section**              | **Content types**        | **Purpose**                                                                                                               |
|--------------------------|--------------------------|---------------------------------------------------------------------------------------------------------------------------|
| Getting Started          | Tutorials, Explanations  | Provides the basics for installing Popochiu, taking first steps, and joining the community.                               |
| The Editor Handbook      | References, Tutorials    | Showcases the functionality of the Popochiu plugin, explains how it works, and serves as a go-to guide for its use.       |
| The Engine Handbook      | References, Explanations | Explains the plugin's architecture and provides a comprehensive API reference for game developers.                        |
| How to Develop a Game    | Tutorials, How-To        | Guides users through setting up their first game, learning by doing, and building confidence to explore advanced features. |
| Advanced Techniques      | Tutorials, How-To        | Offers in-depth guides and practical examples for getting the most out of Popochiu (and beyond).                          |
| Contributing to Popochiu | Explanations, References | Provides all the information contributors need to get involved in Popochiu development.                                    |

If you add new stuff, make sure you put in in the right place. If in doubt, reach out for **@stickgrinder**.

---

## Contributing to missing documentation

Some areas of the documentation are marked as **TODO**. If you think you know how to complete them (yay!):

1. Draft an outline for the missing content.
2. Commit the outline and open a draft PR.
3. Assign **@stickgrinder** as a reviewer.
4. Incorporate feedback and proceed with the full write-up.

If you can't - or don't want to incorporate all the feedback (for example if we ask you to expand the docs too much and you are unable to provide all the necessary work), we can still cooperate to complete it together.
