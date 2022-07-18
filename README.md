# Setup Neovim - GitHub Action

Setup Neovim on Github Actions.

## Usage

See [action.yml](./action.yml)

**Basic (stable release):**

```yml
steps:
  - uses: actions/checkout@v2
  - uses: MunifTanjim/setup-neovim-action@v1
  - run: |
      nvim --version
```

**Specific Tag:**

```yml
steps:
  - uses: actions/checkout@v2
  - uses: MunifTanjim/setup-neovim-action@v1
    with:
      tag: nightly
  - run: |
      nvim --version
```

For list of available tags, check: https://github.com/neovim/neovim/tags

**Compile from Source:**

```yml
steps:
  - uses: actions/checkout@v2
  - uses: MunifTanjim/setup-neovim-action@v1
    with:
      tag: source
  - run: |
      nvim --version
```

## License

Licensed under the MIT License. Check the [LICENSE](./LICENSE) file for details.
