#!/bin/sh

gitbook build
gh-pages-clean
gh-pages -d _book