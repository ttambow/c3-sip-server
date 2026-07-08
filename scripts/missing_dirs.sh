#!/usr/bin/env bash

mkdirs()
{
  [[ ! -d ./lib ]] && mkdir -p ./lib
  [[ ! -d ./resources ]] && mkdir -p ./resources
  [[ ! -d ./test ]] && mkdir -p ./test
}

main()
{
  mkdirs
}

main
