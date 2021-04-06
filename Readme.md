Vault Dash Docs Generator
=========================

This projects is based on [vault-dash-doc-generator](https://github.com/bartoszj/vault-dash-doc-generator).

### Installation

```bash
rbenv install 2.7.3
bundle install
```

### Build

To build execute command:

```bash
./build.sh <version>
```

Then move the docset into a proper directory.

### Hints

- `vault/website/Makefile`:

    ```
    bash -c "npm install; npm run static"
    ```

- `JavaScript heap out of memory`, `vault/website/Makefile`:

    ```
    --env NODE_OPTIONS=--max-old-space-size=4096
    ```

- `vault/website/pages/downloads/index.jsx`. Can be removed from version 1.5.0:

    ```
    getStaticProps
    ```
