#!/bin/bash

cd "${GITHUB_WORKSPACE}" \
  || (echo "Workspace is unavailable" >&2; exit 1)

if [ -z "${INPUT_GITHUB_TOKEN}" ]
then
  echo "github_token is not provided" >&2
  exit 1
fi

set -eu

if [ ! "$(git show HEAD --pretty=format:%ae -s)" = "bot@renovateapp.com" ]
then
  echo "HEAD commit author is not Renovate Bot" >&2
  exit 0
fi

BRANCH=$(git symbolic-ref -q --short HEAD) \
  || (echo "You are in 'detached HEAD' state" >&2; exit 1)

echo "Setting up authentication"
cp .git/config .git/config.bak
revert_git_config() {
  mv .git/config.bak .git/config
}
trap revert_git_config EXIT

git config --unset http."https://github.com/".extraheader || true
git config --global --add http."https://github.com/".extraheader "Authorization: Basic $(echo -n "x-access-token:${INPUT_GITHUB_TOKEN}" | base64 | tr -d '\n')"
git config user.name ${INPUT_GIT_USER}
git config user.email ${INPUT_GIT_EMAIL}

INPUT_LOCK_FILE_PATHS=${INPUT_LOCK_FILE_PATHS:-$(find . -name .terraform.lock.hcl | xargs -r -n1 dirname)}
INPUT_PLATFORMS=${INPUT_PLATFORMS:-"windows_amd64 darwin_amd64 darwin_arm64 linux_amd64 linux_arm64"}
platform_opts=""
for platform in ${INPUT_PLATFORMS}
do
  platform_opts="-platform=${platform} ${platform_opts}"
done

echo "Updating"
echo ${INPUT_LOCK_FILE_PATHS} | xargs -r -n1 echo | while read dir
do
  cd ${dir}
  tfenv install
  echo -e 'terraform {\n  backend "local" {}\n}' > backend_override.tf
  rm -f .terraform.lock.hcl
  terraform init
  terraform providers lock ${platform_opts}
  rm -f backend_override.tf
  cd "${GITHUB_WORKSPACE}"
done

if git diff --exit-code
then
  echo "Up-to-date"
  exit 0
fi
# test
case ${INPUT_COMMIT_STYLE:-add} in
  add)
    git add .;
    git commit -m ${INPUT_COMMIT_MESSAGE:-"Fix .terraform.lock.hcl"};
    ;;
  squash)
    git add .;
    git commit --amend --no-edit;
    ;;
  *)
    echo "Unknown commit_style value: ${INPUT_COMMIT_STYLE}" >&2;
    exit 1;
    ;;
esac

echo "Pushing to the repository"
origin=https://github.com/${GITHUB_REPOSITORY}
case ${INPUT_PUSH:-no} in
  no)
    ;;
  yes)
    git push --verbose ${origin} ${BRANCH};
    ;;
  force)
    git push --verbose -f ${origin} ${BRANCH};
    ;;
  *)
    echo "Unknown push value: ${INPUT_PUSH}" >&2;
    exit 1;
    ;;
esac
