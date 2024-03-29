if [ -z $MAKEFILE ]; then
    MAKEFILE=Makefile
fi

current_version=$(cat $MAKEFILE | grep PKG_VERSION | head -n 1 | cut -d "=" -f 2)
current_hash=$(cat $MAKEFILE | grep PKG_HASH | head -n 1 | cut -d "=" -f 2)
echo "Current version: $current_version"

url="https://api.github.com/repos/$REPO/releases/latest"
jq_expr='.tag_name'
if [ ! -z $INCLUDE_PRE_RELEASE ]; then
    url="https://api.github.com/repos/$REPO/releases?per_page=1"
    jq_expr='.[0].tag_name'
fi
resp=$(curl -s "$url")
latest_version=$(echo "$resp" | jq -r $jq_expr)
if [ $latest_version = "null" ]; then
    echo "No release found"
    exit 0
fi

echo "Latest version: $latest_version"
latest_version_number=$(echo $latest_version | cut -d "v" -f 2)
echo "Latest version number: $latest_version_number"

if [ -z $SOURCE_URL ]; then
    SOURCE_URL="https://github.com/$REPO/archive/refs/tags/$latest_version.tar.gz"
else
    # https://github.com/EkkoG/openwrt-natmap/blob/af5b8ccfac6cbd8a2ce44b674920174b847101a8/.github/workflows/check.yml#L23
    # 用处理作版本号不在约定位置的情况
    SOURCE_URL=$(echo $SOURCE_URL | sed "s/{{version}}/$latest_version_number/g")
fi

wget $SOURCE_URL -O output.tar.gz
hash=$(sha256sum output.tar.gz | cut -d " " -f 1)
echo "New hash: $hash"
echo "Current hash: $current_hash"
rm output.tar.gz

if [ $current_hash = $hash ]; then
    echo "Hash not changed"
    exit 0
fi

echo "Update to $latest_version"
sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$latest_version_number/g" $MAKEFILE
sed -i "s/PKG_RELEASE:=.*/PKG_RELEASE:=1/g" $MAKEFILE
sed -i "s/PKG_HASH:=.*/PKG_HASH:=$hash/g" $MAKEFILE

git config user.name "bot"
git config user.email "bot@github.com"
git add .
if [ -z "$(git status --porcelain)" ]; then
    echo "No changes to commit"
    exit 0
fi

if [ -z $BRANCH ]; then
    BRANCH=main
fi

git commit -m "$(TZ='Asia/Shanghai' date +@%Y%m%d) Bump $REPO to $latest_version"

if [ ! -z $CREATE_PR ]; then
    PR_BRANCH="auto-update/$REPO-$latest_version"
    git push "https://x-access-token:$COMMIT_TOKEN@github.com/$GITHUB_REPOSITORY" HEAD:$PR_BRANCH
    gh pr create --title "Bump $REPO to $latest_version" --body "Bump $REPO to $latest_version" --base $BRANCH --head $PR_BRANCH
else
    git push "https://x-access-token:$COMMIT_TOKEN@github.com/$GITHUB_REPOSITORY" HEAD:$BRANCH
fi