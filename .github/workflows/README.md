# Workflows

## Create demo clusters for version

### All options

| Input                                       | Description                                | Default        |
| ------------------------------------------- | ------------------------------------------ | -------------- |
| [version](#version)                         | Main image version                         |                |
| [create-k8s-cluster](#create-k8s-cluster)   | Whether to create GKE cluster              | `"false"`      |
| [create-os4-cluster](#create-os4-cluster)   | Whether to create Open Shift 4 cluster     | `"false"`      |
| [create-long-cluster](#create-long-cluster) | Whether to create GKE long-running cluster | `"false"`      |
| [dry-run](#dry-run)                         | Whether it is a dry-run                    | `"false"`      |
| [workflow-ref](#workflow-ref)                         | Reference of the called workflow                    |       |

### Detailed options

#### version

Default value: unset

#### create-k8s-cluster

Default value: `false`

#### create-os4-cluster

Default value: `false`

#### create-long-cluster

Default value: `false`

#### dry-run

Default value: `false`

#### workflow-ref

Default value: unset

Must match the reference of the workflow in the `uses` keyword.

### Usage

```yaml
name: Create demo clusters for release candidate
jobs:
  create-clusters:
    name: Setup clusters
    uses: stackrox/actions/.github/workflows/create-cluster.yml@v1
    secrets: inherit
    with:
      version: ${{github.event.inputs.version}}
      create-k8s-cluster: ${{github.event.inputs.create-k8s-cluster == 'true'}}
      create-os4-cluster: ${{github.event.inputs.create-os4-cluster == 'true'}}
      create-long-cluster: ${{github.event.inputs.create-long-cluster == 'true'}}
      dry-run: ${{github.event.inputs.dry-run == 'true'}}
      workflow-ref: v1
```

## Auto retest failed Konflux builds

### Overview

When a Konflux build check fails on a pull request, this action will automatically post a `/retest <check-name>` comment to trigger a rebuild. It includes retry limits to prevent infinite retry loops and automatically cleans up old retest comments when new commits are pushed.

### All options

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `max_retries` | Maximum number of retries for failed builds | No | `3` |
| `check_name_suffix` | Suffix to filter Konflux build check names (e.g., `-on-push`) | No | `-on-push` |
| `retest_command` | Command to trigger Konflux retest (e.g., /retest). Useful to use non default when OpenShift CI uses the same /retest syntax - prevents OpenShift CI from spamming comments saying it does not understand Konflux-specific retest commands. | No | `/retest` |

## Detailed options

- **Automatic Retesting**: Posts retest commands when Konflux builds fail
- **Configurable Retry Limit**: Set maximum retry attempts to prevent infinite loops
- **Auto-Cleanup**: Removes old retest comments when new commits are pushed
- **Filtered Checks**: Only retests checks matching a specific name suffix (e.g., `-on-push`)
- **Custom Retest Command**: Configure the command used to trigger retests (default: `/retest`)
- **Disable via Label**: Add the `disable-konflux-auto-retest` label to a PR to skip automatic retesting


### Usage

Add this to your repository's workflow file (e.g., `.github/workflows/konflux-auto-retest.yml`):

```yaml
name: Auto-retest Konflux Builds

on:
  check_run:
    types: [completed]
  pull_request:
    types: [synchronize]

jobs:
  retest-failed-konflux-builds:
    uses: stackrox/actions/.github/workflows/retest-konflux-builds.yml@v1
    permissions:
      pull-requests: write
      issues: write
    with:
      max_retries: 3
      check_name_suffix: '-on-push'
      retest_command: '/retest'
```
