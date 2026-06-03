# terraform-ci user inline policies are at the 2048-byte AWS limit.
# Permissions for new resources are added to the GitHub Actions OIDC role
# in github-oidc.tf, which has no size limit (role policy limit is 10 KB).
