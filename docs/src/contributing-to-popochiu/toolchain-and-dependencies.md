---
weight: 7020
---

# Toolchain and dependecies

## Plugin and Engine

Developing the Engine and Plugin requires only the Godot game engine.

We strive to keep Popochiu compatible with the latest stable version of Godot, so contributors are encouraged to use the most recent stable version when working on the plugin.

While testing Popochiu on non-stable versions is allowed, all contributions must be made using a stable, supported version. Contributions based on non-stable versions cannot be tested or approved.

The only exception is for RC (_release candidates_), but please refer to [the related answers on the Q&A page](../qna/) for details.

## DevOps Automation

Popochiu relies on GitHub Actions and Workflows to automate releases and publish documentation.

No specific tools are needed to interact with these workflows, but all automation-related files are located in the `.github/workflows` directory.

!!! note
    Contributors are generally not expected to modify automation scripts. However, if your changes require specific build steps, feel free to propose them.

Dockerfiles for documentation are located in the `docs` directory:

1. **`Dockerfile.DocsExtractor`**: Defines the image used to run a script (originally by the GDQuest team) that extracts documentation comments into Markdown files. This is used to publish the [Scripting Reference](../the-engine-handbook/scripting-reference/index).
2. **`Dockerfile.MkDocs`**: Defines the MkDocs image used to preview changes to the documentation locally (see below).

!!! note
    Contributions that improve or optimize the extractor or documentation site are welcome, as long as they follow the contribution guidelines. See the [Contributing Documentation](../contributing-documentation) section for more information.

## Documentation

Popochiu's documentation is written in [Markdown](https://www.markdownguide.org) and rendered using [MkDocs](https://www.mkdocs.org).

The only tools needed to build the documentation are:

- Docker
- Docker Compose
- GNU Make

These tools provide an encapsulated, platform-agnostic, and production-ready local development environment. This approach avoids requiring contributors to install complex dependencies, keeping their systems clean and free from conflicts.

Below are summary instructions for setting up the required packages on supported operating systems.

### Running the Documentation Locally

Docker is available natively on GNU/Linux distributions, while Windows and macOS are supported via Docker Desktop or alternative solutions.

#### GNU/Linux

This guide provides specific instructions for Ubuntu and Arch Linux. If you're using another distribution, refer to its official documentation.

- **Docker Installation:**
  - [Ubuntu and derivatives](https://docs.docker.com/engine/install/ubuntu/)
  - [Arch and derivatives](https://wiki.archlinux.org/title/Docker#Installation)

- **Docker Compose:** Ensure the Compose plugin is installed alongside Docker.

- **GNU Make Installation:**
  - Ubuntu: `sudo apt install build-essential`
  - Arch: `sudo pacman -Sy base-devel`

Once everything is set up, proceed to the [Run the Documentation](#run-the-documentation) section to preview your changes.

#### MS Windows

On Windows, you can either install the required tools natively or use WSL (Windows Subsystem for Linux).

!!! tip
    Running `make` is easier from a bash-like shell (e.g., Git Bash). If you use WSL2, your distribution shell is compatible by default. PowerShell may work, but behavior can vary.

##### Method 1: Native Toolchain

1. Install Docker Desktop following the [official documentation](https://docs.docker.com/desktop/install/windows-install/).
2. The Compose plugin is included with Docker Desktop.
3. Install Make using one of the following methods:
   - **Chocolatey**: `choco install make` (**preferred**)
   - Direct download: [Make for Windows](https://gnuwin32.sourceforge.net/packages/make.htm)
   - **GnuWin32**: [GnuWin32 installer](http://gnuwin32.sourceforge.net/install.html)

##### Method 2: WSL2

Enable [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install-win10) and choose a distribution (Ubuntu is recommended). Once configured, follow the GNU/Linux instructions above.

#### MacOS

Follow the [official Docker Desktop installation guide](https://docs.docker.com/desktop/install/mac-install/). The Compose plugin is included by default.

To install GNU Make:

- **Homebrew**: `brew install make` (**preferred**)
- **XCode**: `xcode-select --install` (agree to the license in the popup).

Once installed, proceed to the next section to preview your changes.

### Run the Documentation

To preview the documentation, navigate to the `docs` directory in the repository and run:

```bash
make docs-up
```

This command starts a Docker container and binds port 286 to the MkDocs instance. Open [http://localhost:286](http://localhost:286) in your browser to view the documentation live.

To stop the container, run:

```bash
make docs-down
```

The documentation supports live reloading, so any changes you save will automatically update in your browser.

### Closing notes

Before pushing changes to the documentation, please read the [Contributing Documentation](../contributing-documentation) section.

For maintainers, instructions for publishing the documentation to the official site are available in the dedicated [README.md](https://github.com/carenalgas/popochiu/blob/develop/docs/README.md) file.
