#!/bin/sh

SRC="src"
BUILD="build"
FINAL="dist"
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

# Minify CSS (& HTML?)
MINIFY_CSS="${BUILD}/lightning"
mkdir -p "${MINIFY_CSS}"
cp -r "${SUBFONT}"/. "${MINIFY_CSS}"
find "${MINIFY_CSS}" -name '*.css' \
  -exec pnpm exec node ${SCRIPTS}/lightning '{}' -o '{}.lightning' \; \
  -exec mv '{}.lightning' '{}' \;

# Inline Critical CSS
CRITICAL_CSS="${BUILD}/critical"
mkdir -p "${CRITICAL_CSS}"
cp -r "${MINIFY_CSS}"/. "${CRITICAL_CSS}"
find "${CRITICAL_CSS}" -name '*.html' \
  -exec sh -c 'pnpm exec critical "$1" -b "$2" -i --strict > "$1.critical"' exec-critical '{}' "${CRITICAL_CSS}" \; \
  -exec mv '{}.critical' '{}' \;

# Export to dist
mkdir -p "${FINAL}" 
cp -r "${CRITICAL_CSS}/." "${FINAL}"