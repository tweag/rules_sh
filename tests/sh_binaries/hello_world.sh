#!/usr/bin/env bash
if [[ $# -ge 1 ]]; then
  exec >"$1"
fi
echo "Hello World"
