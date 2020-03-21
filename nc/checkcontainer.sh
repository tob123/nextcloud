#!/bin/sh
curl -sL http://localhost:${HTTP_PORT}/ | grep login >/dev/null 2>&1
