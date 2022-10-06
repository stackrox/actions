#!/usr/bin/env bash

echo "Test script. Ref: $GITHUB_REF_NAME" >> "$GITHUB_STEP_SUMMARY"

echo "Args:"
for arg in "$@"; do
    echo "..$arg..";
done
