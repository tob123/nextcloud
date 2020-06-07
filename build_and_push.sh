#/bin/bash
set -ex
STG_REPO="docker.io/tob123/nextcloud-staging"
if [[ -n $LATEST && ${DB_TYPE_CI} = "sqlite" ]]; then
		docker buildx build --platform linux/amd64,linux/arm/v7 \
		--build-arg NC_VER=${VERSION} \
		--tag ${STG_REPO}:${VERSION} \
		--tag ${STG_REPO}:${VERSION_MAJOR} \
		--tag ${STG_REPO}:latest \
		--push --progress plain nc
	exit 0
fi
if [[ ${DB_TYPE_CI} = "sqlite" ]]; then
  docker buildx build \
  --platform linux/amd64,linux/arm/v7 \
  --build-arg NC_VER=${VERSION} \
  --tag ${STG_REPO}:${VERSION} \
  --tag ${STG_REPO}:${VERSION_MAJOR} \
  --push --progress plain nc
  exit 0
fi
if [[ -n $LATEST ]]; then
  docker build \
  --build-arg NC_VER=${VERSION} \
  --tag ${STG_REPO}:${VERSION} \
  --tag ${STG_REPO}:${VERSION_MAJOR} \
  --tag ${STG_REPO}:latest nc
  exit 0
fi
docker build \
--build-arg NC_VER=${VERSION} \
--tag ${STG_REPO}:${VERSION} \
--tag ${STG_REPO}:${VERSION_MAJOR} nc
exit 0
