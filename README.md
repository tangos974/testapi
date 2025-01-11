# Webyn DevOps Case Study: TestAPI

![Coverage](.github/pylint-badge.svg)
![Pylint Score](.github/coverage.svg)

This repository contains my submission for the Webyn DevOps technical challenge. It includes a deployed lightweight API application hosted on Google Cloud Platform (GCP).

---

## Overview

It consists mostly of a simple [Backend API](https://github.com/tangos974/testapi/tree/main/backend) , a [Terraform module](https://github.com/tangos974/testapi/tree/main/IaC) for infrastructure provisioning, and a CI/CD pipeline using [GitHub Actions](https://github.com/tangos974/testapi/tree/main/.github) for continuous integration and delivery.

The backend is written in **Python** using **FastAPI** and **uv** for tooling and dependency management. The API provides two endpoints:

- `GET /hello`: Returns `{ "message": "Hello, World!" }`
- `GET /health`: Returns `{ "status": "ok" }`

Deployed on two different GCP project, one for **development**, which you can see [here](https://tanguys-test-api-836961496858.europe-west1.run.app/docs) and one for **production**, [here](https://tanguys-test-api-1036377815254.europe-west1.run.app/docs). The infrastructure is built using **Google Compute Engine (GCR)**,  the setup emphasizes security, automation, and scalability.

---

## Getting Started

### Prerequisites

- **uv**: Ensure uv is installed on your local machine.
- **Terraform**: Ensure Terraform is installed on your local machine. Version `>= 1.10.3`.
- **Docker**: Install Docker to build and scan the container.
- **Google Cloud SDK**: Configure your GCP account and authenticate using `gcloud auth login`.

### Setup

1. Clone this repository:

   ```bash
   git clone https://github.com/tangos974/testapi
   cd testapi
   ```

2. Create two GCP projects, one for **development** and one for **production**, enable required services in each project:

   ```bash
   gcloud services $project_id enable run.googleapis.com artifactregistry.googleapis.com
   ```

3. Create buckets for Terraform state in each project:

   ```bash
   gcloud storage buckets create gs://tanguys-test-api-tf-state \
   --default-storage-class=standard \
   --location=europe-west1
   ```

4. Initialize Terraform in each project to make sure installation was done right:

   ```bash
   cd IaC
   tf -chdir=./dev init
   tf -chdir=./prod init
   ```

5. Run Terraform in each project:

   ```bash
   tf -chdir=./dev apply
   tf -chdir=./prod apply
   ```

6. Generate a service account key for the CI/CD service account in each project:

   ```bash
   gcloud iam service-accounts create cloud-run-sa \
   --description="Service account for CI/CD deployments" \
   --display-name="CI/CD Deployment Service Account"
   ````

Store the JSON key as secrets in Github Actions, and also add the following environment variables:

```yaml
    APP_NAME: tanguys-test-api

    GCP_ARTIFACT_REGISTRY: tanguys-test-api
        
    GCP_DEV_PROJECT_ID: esoteric-dryad-447111-t9
        
    GCP_PROD_PROJECT_ID: test-api-prod
        
    GCP_REGION: europe-west1
```
You can replace `esoteric-dryad-447111-t9` and `test-api-prod` with your own project IDs, and the other variables with whatever you like, just make sure you also update the two `vars.tf` files in the subdirectories of `IaC` if you change them.

You should now be all set!

## Workflows Github Actions

There are two workflows: `ci_cd.yml` and `promote.yml`. 

### `ci_cd.yml`
The `ci_cd.yml` workflow can be triggered on:
1. The `push` event on the `main` branch of either the app code (testapi/backend) or the github actions code (testapi/.github). It runs the following tasks:
2. Manually, without any further input required, by going [here](https://github.com/tangos974/testapi/actions/workflows/ci_cd.yaml) and clicking the `Run workflow` button. 

#### CI and QA
- Set up python dev env and all QA tools using uv
- Run unit tests, linting, and code coverage checks on the backend service (non-breaking, meaning it does not break the build if some of the tests fail, they are just there to get feedback)
- Generate dynamic badges from the result and push them to the repo:

  - pylint badge: ![Pylint Score](.github/pylint-badge.svg)
  - coverage badge: ![Coverage](.github/coverage.svg)

- Scan the entire repo for miscellaneaous vulnerabilities, bad practices, and security issues using [Checkov](https://github.com/bridgecrewio/checkov)

#### CD
- Build the docker image for the backend service
- Scan the docker image for vulnerabilities using [Trivy](https://github.com/aquasecurity/trivy), this step is breaking, i.e. if any vulnerability is found, the build will fail
- Push the docker image to both GCP projects' Artifact Registries, tagged with a shortened version of the triggering commit SHA
- Deploy the backend service to Cloud Run **only for the dev project**

### `promote.yml`
The `promote.yml` workflow can only be triggered manually, by going [here](https://github.com/tangos974/testapi/actions/workflows/promote.yaml) and clicking the `Run workflow` button, it requires a single input, the tag of the docker image to promote.

Its only action is to update the Cloud Run service in the production project with the desired version of the backend service.

## Reasoning, Notes, and Future Improvements

Since the app is so simple, I assumed it was a very early stage proof of concept.

### Infra Choices
I therefore chose to use a relatively 'simple' infra to deploy the API on GCP, using Cloud Run, to focus on setting up a seamless CI/CD pipeline. The reasoning is the following:
- Doing a more complex infra, like a GKE or GCE instance for example, is overkill for a single, stateless service.
- By using a simpler infra, we can focus more on the CI/CD pipeline which allow developers to have their code automatically tested, reviewed, scanned for vulnerabilities and deployed.
- Least priviledged IAM roles and service accounts were easily set up to reduce the attack surface of the deployed service. 
- Using Cloud Run early in the app development process enforces good devops practices which helps a ton in the long run, like keeping stateless services decoupled (or as loosely coupled as possible), keeping them small and shortlived.
- For example, the Dockerfile for the backend was optimized down to a sub 3 seconds build time without cache and a size of less than 100MB, with subsequent dev builds taking less than 1 second. Not only is precious developer time saved, but if we were to run thousands of equivalent containers in the future on a Kubernetes cluster, the overall infrastructure would be much more efficient in terms of cost and performance.
(Tools used to achieve this included docker scout, dive, trivy, checkov)
- It also allows for a finer control over cost, as for example the development project scales down to zero when not in use, whereas the production project has instant response time thanks to a minimum instance count of 1. Since Cloud Run costs  

### CI/CD Choices

- Providing a visual overview of test results dynamically and automatically using badges enables non-blocking quick feedback to developers.
- Security scanning tools like Trivy and Checkov are used to ensure the entire codebase is secure, free from vulnerabilities or sensitive information leakage.
- All iterations of builds are logged through GitHub Actions, and tagged to allow for faster service-level recovery/rollback in case of failure.
- Prod deploys are voluntarily "locked" behind a manual approval process to prevent accidental overwrites of the live service, and can easily be limited to a trusted subset of developers.
- The CI/CD using of the pipeline is kept as lean and simple as possible, with a single trigger for the main branch of the app and a single trigger for the main branch of the github actions repository. The percentage of areas of the SLDC it covers on the other hand, is expanded as much as possible to take away the repetitivity and automate all that can be away from engineers.
- This is also somewhat of an 'intern-compatible' solution, as a developper with no knowledge of gcloud or terraform would still be able to make functional alterations, deployments, and rollbacks without having to write a single cli command.

### Cost Considerations

Doing cost predictions is always hard, and cloud providers calculators are reputed to provide low price estimates. However, here, even with relatively high traffic (1M requests per month to production) and storage (0.5 GB on Artifact Registry with image sizes of 100MB leaves a LOT of margin, and 0.5 on Cloud Storage for just storing terraform state is a super high estimate).
With the above, the GCP calculator [gives us a price of less than 0.1 euros per month](https://cloud.google.com/products/calculator?hl=en&dl=CjhDaVEwTXprMk9HUXlZUzFsT1RBNExUUmpOelV0WVdZNE15MDVaV1ZsWW1WaE5qUmtZallRQVE9PRAcGiQ1MDE3MUU1MC0yQjVBLTQzMzEtOUQxNi1EMkFDNkVCQzQ5RUE) of 0.07 euros.
Given that it doesn't account for [service-level minimum instances vs per-revision minimum instances](https://cloud.google.com/run/docs/about-instance-autoscaling), the actual cost per month is a little higher, and we can give an estimate from the actual cost of the minimum prod instance being up for a day, as seen in the project dashboard, which is 0.06 euros, for a total monthly cost of 0.06 * 30 + 0.07 = **1.87 euros**.

## Future Improvements

- Automatically named and versioned releases, from either code-level tools ([bump2version](https://github.com/c4urself/bump2version) comes to mind for Python) or service-level tools (like [semantic-release](https://github.com/semantic-release/semantic-release)). This would be absolutely crucial if this service was a small part of a larger app, needing to interact with other services or other parts of the app - in that case, one needs to know which versions of all services are currently running to make sure they are compatible. Since here, our 'app' is in fact a single backend service, there is no need to worry about compatibility, hence versionned releases are just a matter of convenience.
- Implement a monitoring solution to alert on failures, and have an automatic rollback process for prod deploys to allow for a controlled recovery of the live service in case of failure.
- A load balancer in front of the prod service would allow finer control over the deployment strategy (Canary, Blue/Green, etc.)