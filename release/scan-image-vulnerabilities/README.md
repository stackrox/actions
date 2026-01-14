# Scan Image Vulnerabilities

Scan a container image in Quay.io for vulnerabilities using `roxctl image scan` and fail if fixable critical or important vulnerabilities are found.

This action waits for an image to be available in Quay.io, scans it using roxctl, and generates a detailed vulnerability report in the GitHub step summary, while making the raw report available as JSON in the workspace as `scan-result.json`.

## Required permissions

```yaml
permissions:
  # Needed for stackrox/central-login to create the JWT token.
  id-token: write
```

## All options

| Input                                     | Description                                        | Required | Default   |
| ----------------------------------------- | -------------------------------------------------- | -------- | --------- |
| [image](#image)                           | Image name (without registry prefix)               | Yes      |           |
| [version](#version)                       | Image version tag                                  | Yes      |           |
| [wait-limit](#wait-limit)                 | Maximum time to wait for image (seconds)           | No       | `"7200"`  |
| [summary-prefix](#summary-prefix)         | Title prefix for the GitHub step summary           | Yes      |           |
| [quay-bearer-token](#quay-bearer-token)   | Quay.io bearer token for wait-for-image            | Yes      |           |
| [central-url](#central-url)               | ACS Central URL                                    | Yes      |           |

### Detailed options

#### image

Image name without the registry prefix. The action will automatically prepend `quay.io/` to construct the full image reference.

Example: `"rhacs-eng/main"`

#### version

Image version tag to scan.

Example: `"3.76.1"`

#### wait-limit

Maximum time in seconds to wait for the image to be available on Quay.io before failing.

Default: `"7200"` (2 hours)

#### summary-prefix

Prefix for the vulnerability report in the GitHub step summary. Use this to help users of the action classify images into groups when multiple matrix scans are performed in a workflow.

Example: `"Upstream Image Scan Results"`

#### quay-bearer-token

Bearer token for authenticating with the Quay.io API. This is required by the wait-for-image action to check if the image is available.

#### central-url

URL of the ACS/RHACS Central instance to use for scanning.

Example: `"https://central.example.com"`

## Usage

The action integrates with the [stackrox/central-login](https://github.com/stackrox/central-login) action, which uses OIDC login for authentication of the `roxctl` CLI.
The ACS Central needs to be configured to allow exchanging tokens from GitHub Actions workflow runs.

Additionally, an image integration for Quay.io must be configured in the ACS Central so that it can pull images requested for scanning.

```yaml
name: Scan image for vulnerabilities

jobs:
  scan:
    runs-on: ubuntu-latest
    permissions:
      id-token: write  # Required for ACS Central OIDC login
    steps:
    - uses: stackrox/actions/release/scan-image-vulnerabilities@v1
      with:
        image: rhacs-eng/main
        version: 3.76.1
        summary-prefix: "Main Image Scan"
        quay-bearer-token: ${{ secrets.QUAY_BEARER_TOKEN }}
        central-url: https://central.example.com
```
