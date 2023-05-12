#!/bin/bash

# bundle

if [ -z ${OPENAI_TOKEN} ]; then
  echo Getting OPENAI_TOKEN from lastpass

  export OPENAI_TOKEN=$(lpass show "OpenAI Key" | awk '/Notes/ {print $2}')
fi

rerun "bundler exec rackup"
