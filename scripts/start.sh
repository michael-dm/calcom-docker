#!/bin/sh
set -x

/app/scripts/wait-for-it.sh ${DATABASE_HOST} -- echo "database is up"
npx migrate deploy
yarn start
