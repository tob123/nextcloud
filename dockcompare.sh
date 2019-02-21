#!/bin/bash
#set -x
#these 2 variables are set by travis
#VERSION="14.0.7"
#LATEST_MINOR="yes"
#
# the rest is locally in this script
PROD_REPO="docker.io/tob123/nextcloud"
STG_REPO="docker.io/tob123/nextcloud-staging"
AC_EXEC="docker exec ac_anchore-engine_1 anchore-cli"
IMAGE_COMPARE="false"
PROD_PUSH="false"
#try to store the variable from travis and restore it later
VERS_TRAV=$VERSION

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
docker tag ${STG_REPO}:${VERSION} ${PROD_REPO}:${VERSION}
docker push ${PROD_REPO}:${VERSION}
}

anch_image () {
if ${AC_EXEC} image add ${PROD_REPO}:${VERSION}; then
  IMAGE_COMPARE=true
  dock_pull
  anch_content
  anch_diff
  else PROD_PUSH="true"
fi
}

anch_image
if [ ${PROD_PUSH} = "true" ]; then
tag_push
PROD_PUSH="false"
fi

if [ -n $LATEST_MINOR ]; then
  MAJOR_TAG=$(echo $VERSION | awk -F. {' print $1'})
  VERSION=${MAJOR_TAG}
  ${AC_EXEC} image add ${STG_REPO}:${VERSION}
  ${AC_EXEC} image wait ${STG_REPO}:${VERSION}
  anch_image
  if [ ${PROD_PUSH} = "true" ]; then
  tag_push
  PROD_PUSH="false"
  fi
fi
VERSION=${VERS_TRAV}
#docker tag tob123/nextcloud-staging:${VERSION} tob123/nextcloud-staging:${MAJOR_TAG}
#docker push tob123/nextcloud-staging:${MAJOR_TAG}

