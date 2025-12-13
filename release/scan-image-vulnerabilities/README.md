# Scan Image Vulnerabilities

Scan a container image on quay.io for vulnerabilities using `roxctl image scan` and fail if fixable critical or important vulnerabilities are found.

This action waits for an image to be available on Quay.io, scans it using roxctl, and generates a detailed vulnerability report in the GitHub step summary, while making the raw report available as JSON in the workspace as `scan-result.json`.

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

Required: Yes

#### version

Image version tag to scan.

Example: `"3.76.1"`

Required: Yes

#### wait-limit

Maximum time in seconds to wait for the image to be available on Quay.io before failing.

Required: No

Default: `"7200"` (2 hours)

#### summary-prefix

Title prefix for the vulnerability report in the GitHub step summary. This helps identify which image the scan results correspond to when multiple scans are performed in a workflow.

Example: `"Image Scan Results"`

Required: Yes

#### quay-bearer-token

Bearer token for authenticating with the Quay.io API. This is required by the wait-for-image action to check if the image is available.

Required: Yes

#### central-url

URL of the ACS/RHACS Central instance to use for scanning.

Example: `"https://central.example.com"`

Required: Yes

## Usage

The action requires credentials for ACS Central to be available. It integrates with the `stackrox/central-login@v1` action which uses OIDC authentication.

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

## Behavior

The action performs the following steps:

1. **Wait for image**: Waits for `quay.io/$IMAGE:$VERSION` to be available on Quay.io
2. **Login to Central**: Authenticates with ACS Central using OIDC
3. **Install roxctl**: Installs the roxctl CLI tool
4. **Scan image**: Scans the image for vulnerabilities
5. **Generate report**: Outputs a formatted table of vulnerabilities to the GitHub step summary
6. **Check results**: Fails the workflow if any **fixable** CRITICAL or IMPORTANT vulnerabilities are found

If vulnerabilities are found, the step summary will include:

- Component name and version
- CVE ID and severity
- Fixed version (if available)
- Link to CVE information
