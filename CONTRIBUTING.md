# Contributing

Please submit contributions via GitHub pull requests. This document outlines the process to help get your contribution accepted.

## Sign off Your Work

The Developer Certificate of Origin (DCO) is a lightweight way for contributors to certify that they wrote or otherwise have the right to submit the code they are contributing to the project.
Here is the full text of the [DCO](http://developercertificate.org/).
Contributors must sign-off that they adhere to these requirements by adding a `Signed-off-by` line to commit messages.

```text
This is my commit message

Signed-off-by: John Doe <john.doe@public.contributor.org>
```

`git commit` has a `-s` option to add the "Signed-off-by" line to your commits:

```text
-s, --signoff
    Add Signed-off-by line by the committer at the end of the commit log
    message. The meaning of a signoff depends on the project, but it typically
    certifies that committer has the rights to submit this work under the same
    license and agrees to a Developer Certificate of Origin (see
    http://developercertificate.org/ for more information).
```

## How to Contribute

1. Fork this repository
1. Develop and test your changes
1. Sign off your commits
1. Submit a pull request

***NOTE***: Pull requests should include changes to no more than one chart. Please submit separate PRs if changing multiple charts.

### Technical Requirements

* Follow [Helm Chart Best Practices](https://helm.sh/docs/topics/chart_best_practices/)
* Must pass CI jobs for linting and installing changed charts with the [chart-testing](https://github.com/helm/chart-testing) tool
* Any change to a chart requires a version bump following [semver](https://semver.org/) principles. See [Immutability](#immutability) and [Versioning](#versioning) below

Once changes have been merged, a job will run to package and release the changed charts.

### Immutability

Chart releases must maintain immutability. Any alteration to a chart, even if it involves only documentation changes, necessitates a version bump for the chart.

### Versioning

Clear versioning helps users understand the nature of changes and make informed decisions about updating their deployments. Following [semver](https://semver.org/) simplifies the release process and enhances collaboration among users and maintainers.

Charts should be introduced at `0.1.0` and all changes must be documented in the chart's CHANGELOG.md file. Any breaking (backwards incompatible) changes to a chart must:

1. Bump the MAJOR version
2. Within the README.md.gotmpl, create a section titled "Upgrade Instructions." Outline the specific manual procedures required for transitioning to the designated MAJOR version.

### Generate README

The readme of each chart can be re-generated with the following command (run inside the chart directory):

```shell
docker run --rm --volume "$(pwd):/helm-docs" -u "$(id -u)" jnorwood/helm-docs:v1.11.0
```
