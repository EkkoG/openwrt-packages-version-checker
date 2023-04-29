A script to check if there have new version of the origin repository of the OpenWrt packages.

When there have new version, it will change the version number and hash in the Makefile and commit it.

# Usage

```
name: Openwrt Build Bot
on:
  schedule:
  - cron: 0 16 * * *
  push:
    branches:
      - main

jobs:
  check:
    name: Check new version of XX
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - uses: EkkoG/openwrt-packages-version-checker@main
        env:
          COMMIT_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          REPO: heiher/natmap
          BRANCH: main
          MAKEFILE: Makefile
          INCLUDE_PRE_RELEASE: true
          CREATE_PR: true
          SOURCE_URL: https://github.com/heiher/natmap/releases/download/{{version}}/natmap-{{version}}.tar.gz
```