#!/bin/sh
IMAGE="ghcr.io/validator/validator"
CMD="/vnu-runtime-image/bin/vnu"
CWD=$(pwd)
filepath="$1"
relativeFilepath=$(realpath --relative-to="${CWD}" "${filepath}")
case "${relativeFilepath}" in
# If the operation to make the filepath relative to the current working directory
# starts with the '..' parent directory then our filename is not in the current working
# directory
..*)
  echo "'${filepath}' not in directory '${CWD}'.  Cannot validate." >&2
  return 1
  ;;
esac
dockerFilePath="/d/${relativeFilepath}"
out=$(docker run -it --mount type=bind,src=.,dst=/d "${IMAGE}" "${CMD}" --html "${dockerFilePath}")
if [ $? ]; then
  echo "Validated ${filepath}"
else
  echo "$out" | grep -v "Picked up JAVA_TOOL_OPTIONS:"
fi
