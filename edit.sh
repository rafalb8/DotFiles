#!/bin/sh

find . -name '*.patch' -exec git apply {} \; -delete