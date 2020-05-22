#/bin/bash
set -ex
STG_REPO="docker.io/tob123/nextcloud-staging"
if [[ -n $LATEST ]]; then
		docker buildx build --platform linux/amd64,linux/arm/v7 \
		--build-arg NC_VER=${VERSION} \
		--tag ${STG_REPO}:${VERSION} \
		--tag ${STG_REPO}:${VERSION_MAJOR} \
		--tag ${STG_REPO}:latest \
		--push --progress plain nc
	exit 0
fi
docker buildx build \
--platform linux/amd64,linux/arm/v7 \
--build-arg NC_VER=${VERSION} \
--tag ${STG_REPO}:${VERSION} \
--tag ${STG_REPO}:${VERSION_MAJOR} \
--push --progress plain nc
