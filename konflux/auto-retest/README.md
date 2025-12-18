# Retest Failed Konflux Builds Action

This reusable GitHub Action automatically retests failed Konflux builds on pull requests by posting `/retest` comments when check runs fail.

## Overview

When a Konflux build check fails on a pull request, this action will automatically post a `/retest <check-name>` comment to trigger a rebuild. It includes retry limits to prevent infinite retry loops and automatically cleans up old retest comments when new commits are pushed.

## Features

- **Automatic Retesting**: Posts `/retest` commands when Konflux builds fail
- **Configurable Retry Limit**: Set maximum retry attempts to prevent infinite loops
- **Auto-Cleanup**: Removes old `/retest` comments when new commits are pushed
- **Filtered Checks**: Only retests checks matching a specific name suffix (e.g., `-on-push`)

## Usage

### Basic Example

Add this to your repository's workflow file (e.g., `.github/workflows/konflux-auto-retest.yml`):

```yaml
name: Auto-retest Konflux Builds

on:
  check_run:
    types: [completed]
  pull_request:
    types: [synchronize]

jobs:
  retest-failed-builds:
    runs-on: ubuntu-latest
    steps:
    - name: Retest failed builds
      uses: stackrox/actions/konflux/auto-retest/retest-failed-builds.yml@v1
      with:
        max_retries: 3
        check_name_suffix: '-on-push'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `max_retries` | Maximum number of retries for failed builds | No | `3` |
| `check_name_suffix` | Suffix to filter Konflux build check names (e.g., `-on-push`) | No | `-on-push` |
