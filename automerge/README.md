# Auto-merge Action

This composite action enables auto-merge for eligible pull requests based on specified labels. Defaults to approving Dependabot PRs with green CI against all branches.

## Features

- Finds PRs with specified label (default: `auto-merge`) for the allowed base branches
- Verifies PRs are in mergeable state (non-draft)
- Checks that required status checks have passed
- Enables auto-merge with squash strategy
- Auto-approves PRs for allowed author

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `allowed-authors` | Authors to filter PRs for auto-merge  (regex)| No | `app/dependabot` |
| `allowed-base-branches` | Allowed base branches for auto-merge (regex) | No | `.*` |
| `dry-run` | Whether to dry-run the auto-merge | No | `false` |
| `github-token` | GitHub token with permissions to merge PRs and approve reviews (`contents: write` and `pull-requests: write` permissions) | Yes | - |
| `labels` | Labels to filter PRs for auto-merge (comma-separated `and` logic) | No | `auto-merge` |
| `limit` | Maximum number of PRs to process per run | No | `50` |
| `repository` | Repository in owner/repo format | No | `${{ github.repository }}` |
| `required-checks` | Required checks to pass for auto-merge (regex) | No | `.*` |

## Usage

```yaml
name: auto-merge

on:
  schedule:
    - cron: '*/15 * * * *'  # Every 15 minutes
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write

concurrency:
  group: auto-merge
  cancel-in-progress: false

jobs:
  auto-merge:
    name: Enable auto-merge for eligible PRs
    runs-on: ubuntu-latest
    if: github.repository_owner == 'stackrox'

    steps:
      - name: Run auto-merge action
        uses: stackrox/actions/automerge@v1
        with:
          github-token: ${{ secrets.RHACS_BOT_GITHUB_TOKEN }}
```
