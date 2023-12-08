# AWS Lambda layer customized for WordPress

### This repository is a fork of [`brefphp/aws-lambda-layers`](https://github.com/brefphp/aws-lambda-layers). It combines directly inherited code from the original with our own developments, heavily inspired by the forked source.

---

### Introduction

This repository hosts the Docker image code for AWS Lambda layer creation, optimized for Sigan.io's ongoing development. It's crucial to note that this repository is currently a work in progress and not ready for general use, as it's undergoing frequent updates.

The Docker image is engineered to emulate AWS Lambda's environment, enabling more efficient local testing of lambda functions without the need for constant deployments. For HTTP-triggered lambda functions, use the `sigan-io/local-api-gateway` image, a lightweight Node.js server simulating an AWS API Gateway.

Built on Amazon Linux 2023 (`provided.al2023`), the image incorporates PHP 8.2 and essential extensions for WordPress compatibility. Prioritizing a lean build, it excludes extensions not vital for WordPress or Sigan.io's requirements, such as `postgres`.

### Requirements

We use [Earthly](https://earthly.dev/) to build the image and [Docker](https://www.docker.com/) to run it locally. You need to have both installed for local development.

### Usage

After installing Earthly and Docker you'll have available the `build` commands defined in `package.json`:

- `npm run build:php-fpm` : Builds the `production` version of the image.
- `npm run build:php-fpm-dev` : Builds the `development` version of the image (So far it only changes that it contains `XDebug`).
- `npm run build` : Builds both versions.
