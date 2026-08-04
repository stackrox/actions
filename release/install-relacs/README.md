# Install relacs CLI

Downloads a [relacs](https://github.com/stackrox/relacs) release binary and
makes it available in `PATH` for subsequent workflow steps.

The binary is verified against the SHA-256 checksums published with each
release.

## Recommended permissions

The action requires no special permissions.

```yaml
permissions: {}
```

## All options

| Name | Required | Default | Description |
| --- | --- | --- | --- |
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
        token: ${{ secrets.RHACS_BOT_GITHUB_TOKEN }}
        version: v0.4.2

    - run: relacs version
```
