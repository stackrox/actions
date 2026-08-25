# Convert JUnit test failures into Jira tickets

Scans a directory of JUnit XML reports and creates (or deduplicates) Jira issues
for test failures using [`junit2jira`](https://github.com/stackrox/junit2jira).
Optionally uploads a CSV of test metrics to GCS for BigQuery ingestion.

If the GitHub job failed but produced no test-level `<failure>` records, the
action synthesises a JUnit failure so infrastructure/setup failures are still
reported.

The action is self-contained: it bundles its own helper scripts and does not
require the calling repository to provide any `scripts/ci` helpers.

## Recommended permissions

The action doesn't require any specific permission.

```yaml
permissions: {}
```

## All options

| Input                          | Description                                                                             | Default                        |
| ------------------------------ | --------------------------------------------------------------------------------------- | ------------------------------ |
| [dry-run](#dry-run)            | When true, runs junit2jira with `--dry-run` and does not create Jira issues              | `false`                        |
| [jira-user](#jira-user)        | User used to authenticate with Jira                                                      |                                |
| [jira-token](#jira-token)      | Token used to authenticate with Jira                                                     |                                |
| [jira-url](#jira-url)          | Base URL of the Jira instance                                                            | `https://redhat.atlassian.net/`|
| [directory](#directory)        | Directory containing the JUnit XML files to scan                                         |                                |
| [threshold](#threshold)        | Minimal number of failures that results in a single cumulative Jira issue                | `5`                            |
| [gcp-account](#gcp-account)    | Optional GCP service account JSON. When set, the action authenticates gcloud itself      | unset                          |
| [gcp-project](#gcp-project)    | GCP project to set as active when authenticating with gcp-account                        | `acs-san-stackroxci`           |
| [gcp-metrics](#gcp-metrics)    | Whether to upload test metrics to GCS for BigQuery                                       | `true`                         |
| [gcs-bucket](#gcs-bucket)      | GCS bucket root used to store test metrics                                               | `gs://stackrox-ci-artifacts`   |
| [gcs-subdir](#gcs-subdir)      | Subdirectory (relative to the bucket root) used to store test metrics                    | `test-metrics/upload`          |
| [version](#version)            | `junit2jira` release version to download                                                 | `v0.0.27`                      |

## Outputs

| Output      | Description                                        |
| ----------- | -------------------------------------------------- |
| `new-jiras` | `"true"`/`"false"` — whether new issues were created |

### Detailed options

#### dry-run

When `true`, `junit2jira` runs with `--dry-run` and no issues are created.
Commonly wired to only create issues on pushes:
`${{ github.event_name != 'push' }}`.

Default value: `false`

#### jira-user

User used to authenticate with Jira. Pass via a secret, e.g.
`${{ secrets.JIRA_USER }}`.

#### jira-token

Token used to authenticate with Jira. Pass via a secret, e.g.
`${{ secrets.JIRA_TOKEN }}`. If empty, the reporting step is skipped so the
action no-ops gracefully on forks/PRs without secrets.

#### jira-url

Base URL of the Jira instance.

Default value: `https://redhat.atlassian.net/`

#### directory

Directory containing the JUnit XML files to scan. `junit2jira` scans it
recursively for `*.xml` files.

#### threshold

Minimal number of failed tests that results in a single cumulative Jira issue
instead of one issue per failure.

Default value: `5`

#### gcp-account

Optional GCP service account JSON. When provided, the action authenticates with
gcloud itself (via `google-github-actions/auth`). When omitted, the action
assumes the caller has already authenticated gcloud.

Default value: unset

#### gcp-project

GCP project to set as active when authenticating with `gcp-account`.

Default value: `acs-san-stackroxci`

#### gcp-metrics

Whether to upload the test metrics CSV to GCS for BigQuery ingestion. Requires
an authenticated gcloud session (see `gcp-account`).

Default value: `true`

#### gcs-bucket

GCS bucket root used to store test metrics.

Default value: `gs://stackrox-ci-artifacts`

#### gcs-subdir

Subdirectory (relative to the bucket root) used to store test metrics.

Default value: `test-metrics/upload`

#### version

`junit2jira` release version to download.

Default value: `v0.0.27`

## Usage

The action assumes gcloud is already authenticated (e.g. via
`google-github-actions/auth`) unless `gcp-account` is provided.

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      # ... run tests, producing JUnit XML under junit-reports/ ...

      - name: Report test failures to Jira
        if: (!cancelled())
        id: junit2jira
        uses: stackrox/actions/test/junit2jira@main
        with:
          dry-run: ${{ github.event_name != 'push' }}
          jira-user: ${{ secrets.JIRA_USER }}
          jira-token: ${{ secrets.JIRA_TOKEN }}
          directory: junit-reports
```

To have the action authenticate to GCP itself, pass a service account:

```yaml
      - uses: stackrox/actions/test/junit2jira@main
        with:
          jira-user: ${{ secrets.JIRA_USER }}
          jira-token: ${{ secrets.JIRA_TOKEN }}
          directory: junit-reports
          gcp-account: ${{ secrets.GCP_SERVICE_ACCOUNT }}
```
