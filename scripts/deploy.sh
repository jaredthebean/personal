#!/bin/sh
set -ex

CONFIG="config/deployment";
SCRIPTS="scripts";
ENV="${CONFIG}/.env";
LOCAL_ENV="${CONFIG}/local.env";

err() {
  echo "$@" >&2;
}
# Check if the variable is set
is_set() {
  # case the variable name passed in ($1) is unset:
  #   `${varName+set} = ${varName} = ''` and
  #   `[ -n '' ]` returns false/1
  # case the variable name passed in is set:
  #   `${varName+set} = 'set'` and
  #   `[ -n 'set' ]` returns true/0
  eval "[ -n \"\${${1}+set}\" ]"
}

# shellcheck source=config/deployment/.env
. "${ENV}"

if [ ! -f "${LOCAL_ENV}" ]; then
  # If we are running non-interactively - AKA STDIN and STDERR are connected to
  # a terminal
  if ! [ -t 0 ] && [ -t 2 ]; then
    err "Need need local configuration file '${LOCAL_ENV}'" ;
    err "See 'README.md#Deployment' for more details or run \
    './${SCRIPTS}/populate-local-env.sh' to create one interactively";
    exit 1;
  fi
  ./${SCRIPTS}/populate-local-env.sh > "${LOCAL_ENV}"
fi
# shellcheck source=config/deployment/local.env
. "${LOCAL_ENV}"

REQUIRED_VARS="BUCKET BLUE_GREEN_FILE REDIRECTS"

# Checks and prints out error message for any unset, but required variables.
# Exits with error if any required variable is unset after all are checked.
for var_name in ${REQUIRED_VARS}; do
  if ! is_set "${var_name}"; then
    unset_var_name='detected';
    err "Need '${var_name}' set in '${ENV}' or '${LOCAL_ENV}'";
  fi
  if [ -n "${unset_var_name+set}" ]; then
    unset unset_var_name
    exit 1
  fi
done

CURRENT_STAGE="$(cat "${BLUE_GREEN_FILE}")"
if [ "${CURRENT_STAGE}" = "blue" ]; then
  NEW_STAGE="green";
elif [ "${CURRENT_STAGE}" = "green" ]; then
  NEW_STAGE="blue";
else
  err "Current stage deployed to is neither green nor blue." \
    "Current stage is: '${CURRENT_STAGE}'." 
  exit 1
fi

aws s3 rm --recursive "s3://${BUCKET}/${NEW_STAGE}"
# Upload css and svg's with a cache time of 1wk
# TODO: Cache-bust these resources (at least the CSS) as
#   they change more than once a week and the cache-control applies to both
#   our CDN (Cloudfront) _and_ the end-users browser, whose entries we can't
#   invalidate.
aws s3 sync \
  --exclude '*' --include '*.css' --include '*.svg' \
  --cache-control 'max-age=604800' \
  dist "s3://${BUCKET}/${NEW_STAGE}"
# Fonts get a month
aws s3 sync \
  --exclude '*' \
  --include '*.woff2' \
  --cache-control 'max-age=2592000' \
  dist "s3://${BUCKET}/${NEW_STAGE}"
# Everything else isn't cached
aws s3 sync \
  --exclude '*.css' --exclude '*.svg' --exclude '*.woff2' \
  dist "s3://${BUCKET}/${NEW_STAGE}"

EMPTY=$(mktemp);

while read -r line; do
  if [ "${line#\#}" != "${line}" ]; then
    continue;
  fi
  IFS="$(printf '\t')" read -r redirect obj_path <<EOF
${line}
EOF
  if [ -z "${redirect}" ] || [ -z "${obj_path}" ]; then
    err "Invalid redirect" \
      "\t Redirect: '${redirect}'" \
      "\t S3 Object Path: '${obj_path}'"
  else
    aws s3 cp --website-redirect \
      "${redirect}" "${EMPTY}" "s3://${BUCKET}/${NEW_STAGE}${obj_path}";
  fi
done < "${REDIRECTS}"
rm "${EMPTY}";

# Update Cloudfront distribution to point to the new blue/green stage
# Make some temp files to store current and new config
CURRENT_CLOUDFRONT_CONFIG_FILE="$(mktemp)";
NEW_CLOUDFRONT_CONFIG_FILE="$(mktemp)";

# Get the current config
aws cloudfront get-distribution-config --id "${CLOUDFRONT_ID}" \
  > "${CURRENT_CLOUDFRONT_CONFIG_FILE}"
# Extract its ETag to send with the update request in case somebody else is
# trying to update at the same time. (Unlikely for this site, but good practice)
CLOUDFRONT_CONFIG_ETAG="$(jq -r '.ETag' < "${CURRENT_CLOUDFRONT_CONFIG_FILE}")"
# Edit the config to point to the new stage being deployed's folder
# in our S3 bucket.
jq ".DistributionConfig.Origins.Items[0].OriginPath=\"/${NEW_STAGE}\"" \
  < "${CURRENT_CLOUDFRONT_CONFIG_FILE}" \
  | jq '.DistributionConfig' > "${NEW_CLOUDFRONT_CONFIG_FILE}";
# Send the update request
aws cloudfront update-distribution \
  --id "${CLOUDFRONT_ID}" \
  --if-match "${CLOUDFRONT_CONFIG_ETAG}" \
  --distribution-config "file://${NEW_CLOUDFRONT_CONFIG_FILE}" > /dev/null;
# Cleanup our temp files.
rm "${NEW_CLOUDFRONT_CONFIG_FILE}" "${CURRENT_CLOUDFRONT_CONFIG_FILE}";
# Invalidate all paths as this is a small site, we pay per path specified
# (wildcards count as one path), and we don't have any monster files that will
# suffer tremendously from not being in the CDN.
aws cloudfront create-invalidation \
  --distribution-id "${CLOUDFRONT_ID}" \
  --paths '/*' > /dev/null;

echo "${NEW_STAGE}" > "${BLUE_GREEN_FILE}";