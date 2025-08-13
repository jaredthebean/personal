#!/bin/sh

# Organized in stages as we minify, transpile and otherwise 'productionize' our source
# so that it loads fast and is decently well supported by the browsers of today.

# Each stage conceptually takes the code from the stage before it,
# runs a single productionizing tool on it and produces a more productionized
# version of the code that it places in its own folder on the filesystem.

# Directories relative to the root of the repo
# The src directory (can also be seen as stage 0)
SRC="src"
# The build directory - all stage folders are contained within it
BUILD="build"
# The directory that contains the final productionized build.
# Can be seen as the final stage.
FINAL="dist"
# Contains various scripts used by the build process.
SCRIPTS="scripts"

#  Minify HTML
HTML="${BUILD}/html"
mkdir -p "${HTML}"
cp -r "${SRC}"/. "${HTML}"
find "${HTML}" -name '*.html' \
  -exec pnpm exec html-minifier-next -c "${PWD}/${SCRIPTS}/html-minifier.config.json" -o '{}.min' '{}' \; \
  -exec mv '{}.min' '{}' \;

# Subfont
SUBFONT="${BUILD}/subfont"
mkdir -p "${SUBFONT}"
pnpm exec subfont --no-fallbacks --font-display "block" --inline-css -r -o "${SUBFONT}" "${HTML}"

# Minify CSS
MINIFY_CSS="${BUILD}/lightning"
mkdir -p "${MINIFY_CSS}"
cp -r "${SUBFONT}"/. "${MINIFY_CSS}"
find "${MINIFY_CSS}" -name '*.css' \
  -exec pnpm exec node ${SCRIPTS}/lightning '{}' -o '{}.lightning' \; \
  -exec mv '{}.lightning' '{}' \;

# Inline 'above-the-fold' critical CSS
CRITICAL_CSS="${BUILD}/critical"
mkdir -p "${CRITICAL_CSS}"
cp -r "${MINIFY_CSS}"/. "${CRITICAL_CSS}"
find "${CRITICAL_CSS}" -name '*.html' \
  -exec sh -c 'pnpm exec critical "$1" -b "$2" -i --strict > "$1.critical"' exec-critical '{}' "${CRITICAL_CSS}" \; \
  -exec mv '{}.critical' '{}' \;

# Export to dist
mkdir -p "${FINAL}" 
cp -r "${CRITICAL_CSS}/." "${FINAL}"