# terraform-lock-fix-action
GitHub Action to update .terraform.lock.hcl

## Example

Example to automatically fix `.terraform.lock.hcl` in Renovate Bot's pull requests.

This action internally uses [tfutils/tfenv](https://github.com/tfutils/tfenv) to install Terraform.
It can automatically detect your project's Terraform versions.

See https://github.com/tfutils/tfenv#tfenv-install-version for more details.

```yaml
name: terraform-lock-fix
on:
  push:
    branches:
      - renovate/*

jobs:
  terraform-lock-fix:
    runs-on: ubuntu-latest
    steps:
      - name: checkout
        uses: actions/checkout@v2
        with:
          fetch-depth: 2
      - name: fix
        uses: seqsense/terraform-lock-fix-action@v0
        with:
          git_user: @@MAINTAINER_NAME@@
          git_email: @@MAINTAINER_EMAIL_ADDRESS@@
          github_token: ${{ secrets.GITHUB_TOKEN }}
          commit_style: squash
          push: force
```
