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

Only one input for now.

- `automagic`: if `true`, it will run automatically `dune pkg lock`, `dune build` and `dune runtest`. Defaults to `false`.
- `install-depexts`: if `true`, it will automatically install system dependencies (depexts) listed by `dune show depexts` using the appropriate package manager (`apt-get` on Linux, `brew` on macOS). Defaults to `false`.

## Outputs

Only one output for now.

- `dune-cache-hit`: reports whether the Dune cache was found in the GitHub Action cache.

## Contributions

Contributions are most welcome!

- [File issues](https://github.com/ocaml-dune/setup-dune/issues) to report bugs or feature requests.
- [Contribute code or documentation](./CONTRIBUTING.md).

---

This project has been created and is maintained by [Tarides](https://tarides.com).
