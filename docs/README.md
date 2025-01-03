# Popochiu official documentation

This folder stores the official documentation for Popochiu, available at https://carenalgas.github.io/popochiu/

The documentation is maintained alongside the code in the same repository, which makes it easier to enforce our _Definition of Done_.

Learn how to configure and run the local environment to contribute to this documentation at: https://carenalgas.github.io/popochiu/contributing-to-popochiu/toolchain-and-dependencies/#documentation

## How to export scripting reference to the local development environment

Scripting reference is automatically exported by GitHub Actions when a new version of the plugin is released.

In case new docs have to be published manually, a make target is available to deploy manually to production. Please refer to the dedicated section below.

Exporting the Engine API refs is necessary to preview it locally. Also, the export procedure will be automatically triggered before every manual deploy to production. To extract the API refs without issuing a deploy, a make command has been made available.

> `make docs-extract`

All of the engine API docs will be exported to markdown format.  
The exported refereces will be available in `The Engine Handbook > Scripting Reference` section of the documentation.

**NOTE**: There is no live-reload for plugin source code. If you change the docblocks in the engine's source files, you will have to manually export local refs again.

**NOTE**: To avoid redundancy, exported API refs are ignored by git, so only the documentation source files and the GDScript source files are versioned.

## How to manually publish the documentation to production

A make command is available for this task, that takes care of everything, that can be issued from every working branch (but will be usually be run from `develop`).

> `make docs-deploy`

> **NOTE**: This command requires writing permissions on Popochiu main repository, so it can be issued only by maintainers and core contributors.

This command will create a local `gh-pages` branch. This branch can be thrown away, but the best option is to keep a local copy of it, because this will speed up subsequent update deploys.

> **NOTE**: The `gh-pages` branch contents will differ entirely from the other branches of the project. You should **NEVER** commit manually on the `gh-pages` branch, nor trying to merge it back to a source branch. It would be **bad**. Like... try to imagine all life as you know it stopping instantaneously and every molecule in your body exploding at the speed of light. Allright, that's bad.

## Additional information

1. For those who make use of DNSDock or Dinghy Proxy, the documentation can be accessed visiting [http://docs.popochiu.local](docs.popochiu.local) on port `80`.
2. If you are really searching for trouble, and/or if you know what you're doing, you can do without GNU Make and use Docker Compose direcly, with:
    * `docker compose up -d` to run the service in background
    * `docker compose down` to stop the service
    * `docker compose up` to run the service and display logs in the console (`ctrl-c` will stop the service and send you back to the console)
