#!/bin/sh
set -e

# Update humans.txt date
date +%Y/%m/%d
sed "s#Last update:.*#Last update: $(date +%Y/%m/%d)#" src/humans.txt

# Install mdBook
curl -sSL https://github.com/rust-lang/mdBook/releases/download/v0.4.40/mdbook-v0.4.40-x86_64-unknown-linux-gnu.tar.gz | tar -xz

# Build book
./mdbook build -d public