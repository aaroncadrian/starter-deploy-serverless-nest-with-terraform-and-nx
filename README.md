# Starter Template for Deploying NestJs to AWS Serverless Using Nx and Terraform

## Prerequisites

- Must have terraform installed
- Must have AWS CLI installed
- Must have Node.js installed
- Must have yarn installed
  - Or you can use npm instead

## Instructions

1. Clone this repo
2. Run `yarn install`
3. Build a production build of `svc-starter` by running `yarn nx build svc-starter --configuration=production`
4. Initialize terraform by running `yarn nx run svc-starter:tf-init`
5. Apply terraform by running `yarn nx run svc-starter:tf-apply`
