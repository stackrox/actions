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
| `version` | no | latest | Release version tag to install (e.g. `v0.4.2`). Omit to install the latest release. |

## Usage

```yaml
name: Install relacs

jobs:
  demo-relacs:
    runs-on: ubuntu-latest
    steps:
    - uses: stackrox/actions/releacs/install-relacs@v1
      with:
        version: v0.4.2

    - run: relacs version
```
