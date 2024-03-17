# Popochiu official documentation

This folder stores the official documentation for Popochiu, available at https://carenalgas.github.io/popochiu/

The documentation is maintained alongside the code in the same repository, which makes it easier to enforce our _Definition of Done_.

Popochiu Documentation is written in [Markdown](https://www.markdownguide.org) and rendered with [MkDocs](https://www.mkdocs.org). Please, read on to learn how to work on the docs.

## Running the documentation locally

This repo provides an encapsulated, platform-agnostic and production-parity local development environment, based on Docker and GNU Make.

Docker is available natively on any GNU/Linux distribution, but Windows and MacOSX are supported by Docker Desktop or other means.

The only dependencies needed to build the docs are:

* Docker
* Docker Compose
* GNU Make

We hereby provide summary instructions to setup the necessary dependencies on each supported OS.

### GNU/Linux

This quick guide provides direct information for Ubuntu, Arch and derivatives of both distros.
If you use a different distro, odds are good that you know what you're doing, so please Google your sources.

Please refer to the documentation of you distribution to learn how to install Docker and Docker Compose:

* [Ubuntu and derivatives](https://docs.docker.com/engine/install/ubuntu/)
* [Arch and derivatives](https://wiki.archlinux.org/title/Docker#Installation)

Please remember to install Docker as well as the Compose plugin.

Make is provided by the `build-essential` metapackage on Ubuntu and derivatives, while on Arch and derivatives you can install `base-devel`:

* **Ubuntu**: `sudo apt install build-essential`
* **Arch**: `sudo pacman -Sy base-devel`

That's it. You can go to the "Run the docs" section to learn how to run your dock.

### MS Windows

You can install all the necessary packages natively on Windows or use a WSL environment (see next paragraph). If you prefer to stay on native Windows, please read on.

> **TIP**: We strongly suggest you run make from a bash or similar Shell like the one provided by _Git Bash_. Should you use WSL2, your distro shell will be compatible out of the box. If you run make natively on PowerShell, YMMV.

#### Method 1: Native Toolchain

Please [follow the official documentation](https://docs.docker.com/desktop/install/windows-install/) to install Docker Desktop on Windows.

The Compose plugin is automatically available on Windows when you install Docker Desktop.

About Make, there are different ways to install it:

1. Use the Chocolatey package: `choco install make` (**preferred option**, requires [Chocolately Package Manager to be installed](https://chocolatey.org/install) first)
2. Direct download of [Make for Windows](https://gnuwin32.sourceforge.net/packages/make.htm)
3. Use [GnuWin32](http://gnuwin32.sourceforge.net/install.html) (particularly suitable for older Windows versions (2000/XP/2003/Vista/7/2008 with msvcrt.dll)

#### Method 2: WSL2

Another way to run the docs locally is to activate [Windows Subsystem for Linux (WSL/WSL2)](https://learn.microsoft.com/en-us/windows/wsl/install-win10), and chose one of the available distros (Ubuntu being a very sane choice).

Should you go down this route, once you have WSL configured with an Ubuntu or Arch instance, please follow the instructions for GNU/Linux.

### MacOSX

Please [follow the official documentation](https://docs.docker.com/desktop/install/mac-install/) to install Docker Desktop on MacOSX.

The Compose plugin is automatically available on Mac when you install Docker Desktop.

About Make, there are different ways to install it:

* Use Homebrew package manager: `brew install make`  (**preferred option**, requires [Homebrew Package Manager to be installed](https://brew.sh/#install) first)
* Run XCode: `xcode-select --install` (confirm installation in the popup window and agree to the ToS)

## Run the documentation

To run the documentation, just enter the `docs` directory in the project's repository and issue this command:

> `make docs-up`

This will start the Docker container, and will bind port 286 of the host to the running instance of MkDocs in the container. To view the docs live in your browser, just visit [http://localhost:286](http://localhost:286).

To stop the container service, just issue

> `make docs-down`

The documentation supports live reloading, so your browser will automatically update when you save a file you're working on, create a new file or folder.

Please, read the contribution rules before pushing changes to Popochiu Documentation.

## How to export scripting reference to the local development environment

Scripting reference ~~is~~ will be automatically exported by GitHub Actions when the doc is published to production.

> **NOTE**: At the time of writing, the documentation has to deployed manually to production. Please refer to the dedicated section below.

Exporting the Engine API refs is necessary to preview it locally. Also, the export procedure will be automatically triggered before every manual deploy to production. To extract the API refs without issuing a deploy, a make command has been made available.

> `make docs-extract`

All of the engine API docs will be exported to markdown format.  
The exported refereces will be available in `The Engine Handbook > Scripting Reference` section of the documentation.

**NOTE**: There is no live-reload from the plugin source code. If you change the docblocks in the engine's source files, you will have to manually export local refs again.

**NOTE**: To avoid redundancy, exported API refs are ignored by Git, so only the documentation source files and the GDScript source files are versioned.

## How to publish the documentation to production

~~MkDocs is automatically triggered by GitHub Actions automation so that new versions of the documentation are published whit every new release.~~

At the time of writing, the documentation has to be deployed manually to Github Pages. A make command is available for this task, that takes care of everything, that can be issued from every working branch (but will be usually be run from `develop`).

> `make docs-deploy`

> **NOTE**: This command requires writing permissions on Popochiu main repository, so it can be issued only by core project contributors.

This command will create a local `gh-pages` branch. This branch can be thrown away, but the best option is to keep a local copy of it, because this will speed up subsequent update deploys.

> **NOTE**: The `gh-pages` branch contents will differ entirely from the other branches of the project. You should **NEVER** commit manually on the `gh-pages` branch, nor trying to merge it back to a source branch. It would be bad. Like... try to imagine all life as you know it stopping instantaneously and every molecule in your body exploding at the speed of light. Allright, that's bad.

## Additional information

1. For those who make use of DNSDock or Dinghy Proxy, the documentation can be accessed visiting [http://docs.popochiu.local](docs.popochiu.local) on port `80`.
2. If you are really searching for trouble, and/or if you know what you're doing, you can do without GNU Make and use Docker Compose direcly, with:
    * `docker compose up -d` to run the service in background
    * `docker compose down` to stop the service
    * `docker compose up` to run the service and display logs in the console (`ctrl-c` will stop the service and send you back to the console)
