#!/bin/sh

echo "What bucket are we deploying to?";
read -r BUCKET;
echo "What is the ID of the Cloudfront distribution we are fronting the bucket with?";
read -r CLOUDFRONT_ID;

# local.env script template
cat <<EOF
# The name of the S3 bucket that is hosting our static website
# So "bucket" not "s3://bucket"
BUCKET="${BUCKET}"

# The Cloudfront distribution ID that fronts our S3 bucket
# and to which our domain is routed.
CLOUDFRONT_ID="${CLOUDFRONT_ID}"
EOF
