---
weight: 7020
---

## Plugin and Engine

The development of the Engine and Plugin requires only the Godot game engine.

We strive to keep Popochiu compatible with the latest stable version of Godot, so you are encouraged to use the most recent stable version to contribute to the plugin.

You may want to test Popochiu on non-stable versions, but please ensure your contribution process happens on a stable, supported version, or we won't be able to test and approve your code.

The only exception to this is for RC (_release candidates_), but please see [the related answers on the Q&A page](../qna/) for additional details.

## DevOps Automation

Popochiu relies on GitHub Actions and Workflows to automate releases and publishing this docs.

There is no need for specific tools for that, but you can find the related stuff in the `.github/workflows` directory.

!!! note
    Contributors are probably not supposed to do any change to automation, but should your change require some specific build step, feel free to propose it.

The _Dockerfiles_ for the docs can be found in the `docs` folder. There are two of them:

1. `Dockerfile.DocsExtractor` defines the image to run a script originally written by GDQuest crew to extract Documentation Comments to Markdown files. That's what we use to publish the [Scripting Reference](../the-engine-handbook/scripting-reference/index).
2. `Dockerfile.MkDocs` defines the MkDocs image that is run locally to preview changes to the documentation (see below)

!!! note
    Contributions to improve and optimize the capabilities of the extractor or the documentation site are welcome, as long as they follow the contributions guidelines. Please see [Contributing Documentation](../contributing-documentation) section.

## Documentation

Popochiu Documentation is written in [Markdown](https://www.markdownguide.org) and rendered by [MkDocs](https://www.mkdocs.org).

The only dependencies needed to build the docs are:

* Docker
* Docker Compose
* GNU Make

By using these tools we can create an encapsulated, platform-agnostic and production-parity local development environment for documentation, that's fully portable and doesn't require contributors to install any complex dependencies, leaving the host system clean and free from possible conflicts.

We hereby provide summary instructions to setup the necessary packages on each supported OS.

### Running the documentation locally

Docker is available natively on any GNU/Linux distribution, but Windows and MacOSX are supported by Docker Desktop or other means.

#### GNU/Linux

This quick guide provides direct information for Ubuntu, Arch and derivatives of both distros.
If you use a different distro, odds are good that you know what you're doing, so please Google your sources.

Please refer to the documentation of you distribution to learn how to install Docker and Docker Compose:

* [Ubuntu and derivatives](https://docs.docker.com/engine/install/ubuntu/)
* [Arch and derivatives](https://wiki.archlinux.org/title/Docker#Installation)

Please remember to install Docker as well as the Compose plugin.

Make is provided by the `build-essential` metapackage on Ubuntu and derivatives, while on Arch and derivatives you can install `base-devel`:

* **Ubuntu**: `sudo apt install build-essential`
* **Arch**: `sudo pacman -Sy base-devel`

That's it. You can jump to the [Run the documentation](#run-the-documentation) section to learn how to preview your changes locally.

#### MS Windows

You can install all the necessary packages natively on Windows or use a WSL environment (see next paragraph). If you prefer to stay on native Windows, please read on.

> **TIP**: We strongly suggest you run make from a bash or similar Shell like the one provided by _Git Bash_. Should you use WSL2, your distro shell will be compatible out of the box. If you run make natively on PowerShell, YMMV.

##### Method 1: Native Toolchain

Please [follow the official documentation](https://docs.docker.com/desktop/install/windows-install/) to install Docker Desktop on Windows.

The Compose plugin is automatically available on Windows when you install Docker Desktop.

About Make, there are different ways to install it:

1. Use the Chocolatey package: `choco install make` (**preferred option**, requires [Chocolately Package Manager to be installed](https://chocolatey.org/install) first)
2. Direct download of [Make for Windows](https://gnuwin32.sourceforge.net/packages/make.htm)
3. Use [GnuWin32](http://gnuwin32.sourceforge.net/install.html) (particularly suitable for older Windows versions (2000/XP/2003/Vista/7/2008 with msvcrt.dll)

##### Method 2: WSL2

Another way to run the docs locally is to activate [Windows Subsystem for Linux (WSL/WSL2)](https://learn.microsoft.com/en-us/windows/wsl/install-win10), and chose one of the available distros (Ubuntu being a very sane choice).

Should you go down this route, once you have WSL configured with an Ubuntu or Arch instance, please follow the instructions for GNU/Linux.

Once you're done, read the [Run the docs](#run-the-docs) section to learn how to preview your changes locally.

#### MacOSX

Please [follow the official documentation](https://docs.docker.com/desktop/install/mac-install/) to install Docker Desktop on MacOSX.

The Compose plugin is automatically available on Mac when you install Docker Desktop.

About Make, there are different ways to install it:

* Use Homebrew package manager: `brew install make`  (**preferred option**, requires [Homebrew Package Manager to be installed](https://brew.sh/#install) first)
* Run XCode: `xcode-select --install` (confirm installation in the popup window and agree to the ToS)

Once you're done, read on to learn how to preview your changes locally.

### Run the documentation

To run the documentation, just enter the `docs` directory in the project's repository and issue this command:

> `make docs-up`

This will start the Docker container, and will bind port 286 of the host to the running instance of MkDocs in the container. To view the docs live in your browser, just visit [http://localhost:286](http://localhost:286).

To stop the container service, just issue

> `make docs-down`

The documentation supports live reloading, so your browser will automatically update when you save a file you're working on, or when you create a new file or folder.

### Closing notes

Please, read the [Contributing documentation](../contributing-documentation) section before pushing changes to Popochiu Documentation.

Instructions on how to publish the documentation to the official site are available to maintainers in the dedicated [README.md](https://github.com/carenalgas/popochiu/blob/develop/docs/README.md) file.
