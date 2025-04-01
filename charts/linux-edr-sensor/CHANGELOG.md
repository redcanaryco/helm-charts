# Changelog

All notable changes to this project will be documented in this file.

The project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.12] - 2025-04-01

### Changed
- Updated `appVersion` to the `1.11.0-26258` docker tag for the sensor image

## [0.1.11] - 2025-02-05

### Changed
- GKE and OpenShift are now listed as supported distributions in README.md
- The `persistence` value now also controls the `nodestate` mount for the container and allows setting it via `persistence.nodestateDir`. This is necessary for proper GKE support.
- The README.md file now describes the required `persistence.nodestateDir` setting for GKE installs.

## [0.1.10] - 2025-01-09

### Changed
- Added support for installing in OpenShift/OKd clusters.

## [0.1.9] - 2024-11-05

### Changed
- Updated `appVersion` to the `1.10.2-25540` docker tag for the sensor image

## [0.1.8] - 2024-10-31

### Changed
- Updated `appVersion` to the `1.10.1-25453` docker tag for the sensor image

## [0.1.7] - 2024-07-30

### Changed
- Updated `appVersion` to the `1.9.0-24205` docker tag for the sensor image

## [0.1.6] - 2024-05-01

### Changed
- Updated `appVersion` to the `1.8.0-23707` docker tag for the sensor image

## [0.1.5] - 2024-03-14
- Updated README to remove pre-release disclaimer.

## [0.1.4] - 2024-02-12

### Changed
- Updated `appVersion` to the `1.7.2-22699` docker tag for the sensor image

## [0.1.3] - 2023-11-13

### Changed
- Updated `appVersion` to the `1.6.0-21823` docker tag for the sensor image
- Updated the chart-testing action to `2.6.1`

## [0.1.2] - 2023-09-06

### Changed
- Updated `appVersion` to the `1.5.4-21043` docker tag for the sensor image

## [0.1.1] - 2023-08-22

### Added

- Updated readme to include GA disclaimer and notes for multi-architecture k8s clusters
- Support for affinities to daemonset template along with associated values
- Amazon EKS and Azure AKS included in list of tested k8s distributions

## [0.1.0] - 2023-08-03

### Added

- Initial release of the linux-edr-sensor helm chart
