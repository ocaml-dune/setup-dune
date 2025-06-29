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

## Outputs

- `dune-cache-hit`: reports whether the Dune cache was found in the GitHub Action cache.
- `dune-cache-primary-key`: the primary key used for the Dune cache. See [Customizing the Caching Strategy](#customizing-the-caching-strategy).
- `dune-cache-root`: the path to the Dune cache root directory. See [Customizing the Caching Strategy](#customizing-the-caching-strategy).

## Customizing the Caching Strategy

Advanced users may want to manage the Dune cache themselves, for example to save the cache after additional steps or with a custom key. You can use the `dune-cache-root` and `dune-cache-primary-key` outputs to do this. Here is an example of how to save the cache manually in your workflow:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Use dune
        id: setup-dune
        uses: ocaml-dune/setup-dune@v0
        with:
          automagic: false
      # ... your custom build/test steps ...
      - name: Save Dune cache
        uses: actions/cache/save@v4
        with:
          path: ${{ steps.setup-dune.outputs.dune-cache-root }}
          key: ${{ steps.setup-dune.outputs.dune-cache-primary-key }}
```

This approach gives you full control over when and how the cache is saved.

## Contributions

Contributions are most welcome!

- [File issues](https://github.com/ocaml-dune/setup-dune/issues) to report bugs or feature requests.
- [Contribute code or documentation](./CONTRIBUTING.md).

---

This project has been created and is maintained by [Tarides](https://tarides.com).
