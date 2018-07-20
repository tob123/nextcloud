#!/bin/sh
curl -sL http://localhost:8000/ | grep login >/dev/null 2>&1
