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

## Periodic retest failed Konflux builds

### Overview

Periodically scans all open pull requests for failed Konflux build checks and posts a
`/retest <check-name>` comment to trigger a rebuild. Retries up to `max_retries` times
per check per commit, then stops. Old retest comments from previous commit cycles are
cleaned up automatically so the retry counter always reflects the current commit only.

Add the `disable-konflux-auto-retest` label to a PR to opt it out of automatic retesting.

### All options

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `max_retries` | Maximum number of retries per failed check per commit | No | `3` |
| `check_name_suffix` | Suffix to filter Konflux check names (e.g. `-on-push`, `-on-pull-request`) | No | `-on-push` |
| `retest_command` | Comment body used to trigger a Konflux retest. Use a non-default value when OpenShift CI shares the same `/retest` syntax, to avoid cross-system noise. | No | `/retest` |
| `konflux_app_id` | GitHub App ID for Red Hat Konflux, used to filter check suites | No | `296509` |

### Usage

Create a workflow file in your repository (e.g. `.github/workflows/konflux-retest-periodic.yml`):

```yaml
name: Periodic Retest Failed Konflux Builds

on:
  schedule:
    - cron: '5,15,25,35,45,55 * * * *' # every 10 minutes
  workflow_dispatch:

jobs:
  retest:
    uses: stackrox/actions/.github/workflows/periodic-retest-konflux-builds.yml@main
    with:
      check_name_suffix: '-on-push'
```
