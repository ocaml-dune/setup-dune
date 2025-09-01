# `setup-dune`: a GitHub Action to install and setup `dune`, developer preview

## How to use it

Create a `.github/workflows/dune.yml` file with something like:

```yaml
name: Build and test

on: [push, pull_request]

jobs:
  build:
    strategy:
      matrix:
        runs-on: [ ubuntu-latest, macos-latest, macos-13 ]
    runs-on: ${{ matrix.runs-on }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Use dune
        uses: ocaml-dune/setup-dune@v0
        with:
          automagic: true
```

## Inputs

| Key         | Meaning                                                 | Default value           |
| ----------- | ------------------------------------------------------- | ----------------------- |
| `version`   | version of dune to use                                  | `dev`                   |
| `directory` | where is the project that should be built and tested    | current directory (`.`) |
| `automagic` | when `true`, triggers `pkg lock`, `build` and `runtest` | `false`                 |
| `steps`     | fine-grain control over the steps to run                | empty, use `automagic`  |

### Details

The `version` can have the following special values:

- `dev` for the Developer Preview, which is the default at the moment,
- `latest` for the latest stable release.

When `steps` is empty, the set of steps to run is set according to `automagic`.
Otherwise `steps` should be the space-separated list of steps to perform
(`automagic` is ignored in that case). The complete list of steps is:
`install-dune lock lazy-update-depexts install-gpatch install-depexts build
runtest`. All are enabled when `automagic` is `true` except for `install-gpatch`
which is enabled only on macOS; only `install-dune` is enabled when `automagic`
is false.

It can be useful to tune `steps` for instance when:

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
