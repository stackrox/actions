# Auto-merge Action

This composite action enables auto-merge for eligible pull requests based on specified labels.

## Features

- Finds PRs with specified label (default: `auto-merge`)
- Verifies PRs are in mergeable state (non-draft)
- Checks that all status checks have passed
- Enables auto-merge with squash strategy
- Auto-approves Dependabot PRs

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `github-token` | GitHub token with permissions to merge PRs and approve reviews (`contents: write` and `pull-requests: write` permissions) | Yes | - |
| `repository` | Repository in owner/repo format | No | `${{ github.repository }}` |
| `label` | Label to filter PRs for auto-merge | No | `auto-merge` |
| `limit` | Maximum number of PRs to process | No | `50` |

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
