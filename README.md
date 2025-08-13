# Personal Site

This is my personal site that can be found hosted on
http://jaredbean.name.  I use to try out different web technologies and/or JS frameworks.

## Build

Starting this out as lite and vanilla as possible.  No build system just a POSIX sh build
script that passes the source through a couple minifiers and outputs it in `dist/`.

### Build Command
```sh
./scripts/build.sh
```

### Clean Command
```sh
rm -r build/
```

## Stack
 - [`pnpm`](https://pnpm.io/) for managing my dependencies.
 - `vite` just for a dev server.
### Production Builds
 - [`html-minifier-next`](https://github.com/j9t/html-minifier-next) for HTML minification.
 - [`subfont`](https://github.com/Munter/subfont) to download my fonts from Google Fonts and subset them to just the characters used in the site (drastically reducing their size).
 - [`lightningcss`](https://lightningcss.dev/) for CSS minification and a _little_ transpilation (until CSS nesting is better supported)
 - [`critical`](https://github.com/addyosmani/critical) for 'above-the-fold' or 'critical' CSS inlining in the HTML.
### Code Cleanliness
 - [`pre-commit`](https://pre-commit.com/) for running most of the code cleanliness tools on git commits.
 - [Nu HTML Validator](https://validator.w3.org/nu/about.html) for ensuring my HTML is valid (and I haven't missed a closing tag, etc.)
 - [`biome`](https://biomejs.dev/reference/cli/#biome-check) for formatting and linting CSS and JavaScript.
 - [`shellcheck`](https://github.com/koalaman/shellcheck) for linting shell scripts.

