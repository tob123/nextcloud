#/bin/bash
set -ex
docker push tob123/nextcloud-dev:${VERSION}
if [[ -n $LATEST_MINOR ]]; then
  MAJOR_TAG=$(echo $VERSION | awk -F. {' print $1'})
  docker tag tob123/nextcloud-dev:${VERSION} tob123/nextcloud-dev:${MAJOR_TAG}
  docker push tob123/nextcloud-dev:${MAJOR_TAG}
fi
if [[ -n $LATEST ]]; then
  docker tag tob123/nextcloud-dev:${VERSION} tob123/nextcloud-dev:latest
  docker push tob123/nextcloud-dev:latest
fi
