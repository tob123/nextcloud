#!/bin/bash
set -ex
#these 3 variables are set by travis. for example:
#VERSION="14.0.7"
#VERSION_MAJOR="14"
#
# the rest is locally in this script
PROD_REPO="docker.io/tob123/nextcloud"
STG_REPO="docker.io/tob123/nextcloud-staging"
AC_EXEC="anchore-cli"
IMAGE_COMPARE="false"
PROD_PUSH="false"
#try to store the variable from travis and restore it later

anch_content () {
${AC_EXEC} image wait ${PROD_REPO}:${VERSION}
PROD_OS=`mktemp`
PROD_FILES=`mktemp`
STG_OS=`mktemp`
STG_FILES=`mktemp`
${AC_EXEC} image content ${PROD_REPO}:${VERSION} os > ${PROD_OS}
${AC_EXEC} image content ${PROD_REPO}:${VERSION} files > ${PROD_FILES}
${AC_EXEC} image content ${STG_REPO}:${VERSION} os > ${STG_OS}
${AC_EXEC} image content ${STG_REPO}:${VERSION} files > ${STG_FILES}
}

dock_pull () {
docker pull ${STG_REPO}:${VERSION}
}

anch_diff () {
if diff ${PROD_OS} ${STG_OS}; then
  echo no difference found in image content on package level
  else echo difference found in image content on package level. triggering push
  PROD_PUSH="true"
fi
if diff ${PROD_FILES} ${STG_FILES}; then
  echo no difference found in image content on file level
  else echo difference found in image content on file level. triggering push
  PROD_PUSH="true"
fi
rm ${PROD_OS} ${PROD_FILES} ${STG_OS} ${STG_FILES}
}

tag_push () {
	docker buildx build \
	--platform linux/amd64,linux/arm64 \
	--build-arg NC_VER=${VERSION} \
	--tag ${PROD_REPO}:${VERSION} \
	--tag ${PROD_REPO}:${VERSION_MAJOR} \
	--push --progress plain nc
}
tag_push_latest () {
	docker buildx build \
	--platform linux/amd64,linux/arm64 \
	--build-arg NC_VER=${VERSION} \
	--tag ${PROD_REPO}:${VERSION} \
	--tag ${PROD_REPO}:${VERSION_MAJOR} \
	--tag ${PROD_REPO}:latest \
	--push --progress plain nc
}

anch_image () {
if ${AC_EXEC} image add ${PROD_REPO}:${VERSION}; then
  IMAGE_COMPARE=true
#  dock_pull
  anch_content
  anch_diff
  else PROD_PUSH="true"
fi
}

anch_image
if [[ ${PROD_PUSH} = "true" && -n $LATEST ]]; then
  tag_push_latest
  exit 0
fi
if [[ ${PROD_PUSH} = "true" ]]; then
  tag_push
fi
