# aws-ecr-argocd-orb

CircleCi Orb to build and push to AWS ECR and deploy to EKS via kubectl rollout restart.

## Development

When submitting your changes as a pull request, the CI pipeline will automatically trigger a dev release of the orb.

After merging a PR, there is an automatic production release.
To define new semver version of the release make sure to include the `[semver:FOO]` pattern in the merge commit message, where `FOO` is `major`, `minor`, `patch`, or `skip` (to skip promotion).
