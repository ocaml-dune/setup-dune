# `setup-dune`: a GitHub Action to install Dune and optionally build a project with Dune package management

## How to use it

Create a `.github/workflows/dune.yml` file with something like:

```yaml
name: Build and test

on: [push, pull_request]

jobs:
  build:
    strategy:
      matrix:
        runs-on: [ ubuntu-latest, macos-latest ]
    runs-on: ${{ matrix.runs-on }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v6
      - name: Use dune
        uses: ocaml-dune/setup-dune@v2
```

## Inputs

| Key         | Meaning                                                                | Default value           |
| ----------- | ---------------------------------------------------------------------- | ----------------------- |
| `version`   | version of dune to use                                                 | `nightly`               |
| `steps`     | which steps should be run                                              | `all`                   |
| `directory` | where is the project that should be built and tested                   | current directory (`.`) |
| `workspace` | argument for the `--workspace` option (relative to `directory`)        | empty (Dune’s default)  |
| `display`   | argument for the `--display` option                                    | empty (Dune’s default)  |


### Details

The `version` can have the following special values:

- `nightly` for the latest [nightly release](https://nightly.dune.build/): this
  is the default at the moment since dune package management is still moving
  fast and targeted at early adopters.
- `latest` for the latest stable release of dune: for CI systems that want more
  stable use of dune package management.

`steps` should be either a space-separated list of the steps to perform or one
of two special values.

- The steps are named: `install-dune`, `enable-pkg`, `lazy-update-depexts`,
  `install-gpatch`, `install-depexts`, `build`, and `runtest`.

  - `enable-pkg` enables Dune package management by creating a configuration
    containing `(pkg enabled)` (for Dune 3.21 or later).
  - `lazy-update-depexts`, when present, will trigger a `brew update` or
    `apt-get update` just before any other external dependency installation
    (during `install-gpatch` on macOS or on `install-depexts` on all OSes); if
    no such installation is required, the update is skipped (hence the `lazy`).

  The other steps should be pretty self-explanatory.
- If `steps` is given the `all` value, all those steps are performed.
- If `steps` is given the empty value, only the `install-dune` step is
  performed.

It can be useful to set an explicit value for `steps` for instance when:

- your project doesn’t require `gpatch`, as updating `brew` and installing
  `gpatch` takes some time already,
- you have a repository with more than one project and you want to trigger
  `setup-dune` more than once but still install dune and run `{apt,brew} update`
  (if needed) only the first time.

## Outputs

| Key              | Meaning                                                     |
| ---------------- | ----------------------------------------------------------- |
| `dune-cache-hit` | whether the Dune cache was found in the GitHub Action cache |

## Contributions

Contributions are most welcome!

- [File issues](https://github.com/ocaml-dune/setup-dune/issues) to report bugs or feature requests.
- [Contribute code or documentation](./CONTRIBUTING.md).

---

This project has been created and is maintained by [Tarides](https://tarides.com).
