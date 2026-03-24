#!/bin/sh
set -e

# Update humans.txt date
sed "s#Last update:.*#Last update: $(date +%Y/%m/%d)#" src/humans.txt > src/humans.txt.tmp && mv src/humans.txt.tmp src/humans.txt

# Copy LICENSE to src so mdBook includes it
cp LICENSE src/LICENSE.txt

# Install mdBook
curl -sSL https://github.com/rust-lang/mdBook/releases/download/v0.5.2/mdbook-v0.5.2-x86_64-unknown-linux-gnu.tar.gz | tar -xz

# install intent
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
sh src/chapters/1/examples/install.sh

# verify intent is available
echo "PATH=$PATH"
command -v intent
intent --help >/dev/null 2>&1

# generate outputs
find src/chapters -path '*/examples/*.sh' | while read -r script; do
  case "$script" in
    */install.sh) continue ;;
  esac

  dir=$(dirname "$script")
  file=$(basename "$script")
  base=${file%.sh}
  out="$dir/$base.out"

  echo "Running $script -> $out"
  if ! (
    cd "$dir"
    sh "./$file"
  ) > "$base.out" 2>&1; then
    echo "FAILED: $script"
    cat "$out"
    exit 1
  fi
done

# Build book
./mdbook build -d public

# Copy installer script to site root
cp static/install-intent.sh public/install-intent.sh