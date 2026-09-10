# Install relacs CLI

Downloads a [relacs](https://github.com/stackrox/relacs) release binary and
makes it available in a specified directory for subsequent workflow steps.

The binary is verified against the SHA-256 checksums published with each
release.

The installed binary is cached by runner and version.

## Recommended permissions

The action requires no special permissions.

```yaml
permissions: {}
```

## All options

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `relacs_binary` | no | `relacs` | Name of the installed `relacs` binary. |
| `relacs_install_dir` | no | `$HOME/.local/bin` | Directory where to install `relacs` binary. Supports expansion of `$HOME` and `${HOME}` in custom paths (other environment variables are not expanded). |
| `token` | yes |  | GH token to use for authentication for the `relacs` repository. |
| `version` | no | "" | Release version tag to install (e.g. `v0.4.2`). Omit to install the latest release. |

## Usage

```yaml
name: Install relacs

jobs:
  demo-relacs:
    runs-on: ubuntu-latest
    steps:
    - uses: stackrox/actions/release/install-relacs@v1
      with:
        relacs_install_dir: /home/runner/.local/bin
        token: ${{ secrets.RHACS_BOT_GITHUB_TOKEN }}
        version: v0.4.2

    - run: relacs version
```
