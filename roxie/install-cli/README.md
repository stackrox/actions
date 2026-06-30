# Install roxie CLI

Downloads a [roxie](https://github.com/stackrox/roxie) release binary and
makes it available in `PATH` for subsequent workflow steps.

The binary is verified against the SHA-256 checksums published with each
release.

## Recommended permissions

The action doesn't require any specific permission.

```yaml
permissions: {}
```

## All options

| Name | Required | Default | Description |
| --- | --- | --- | --- |
| `version` | no | latest | Release version tag to install (e.g. `v0.4.2`). Omit to install the latest release. |

## Usage

```yaml
name: Deploy ACS

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: stackrox/actions/roxie/install-cli@v1
      with:
        version: v0.4.2
    - run: roxie version
```
