#!/usr/bin/env bash

set -e

if [ -s .env ]; then
  mv .env .env_bak
fi

cp .env_example .env
.binstubs/rspec --color
#.binstubs/cucumber --strict

if [ -s .env_bak ]; then
  mv .env_bak .env
fi

