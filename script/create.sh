#!/usr/bin/env bash

set -o pipefail

env_file=".env"

required=(
    "OUTPUT"
    "APP_NAME"
    "APP_ID"
)

while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^([^#]+)=([^#]+) ]]; then
        name="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        value="${value//$'\r'/}"
        value="${value%"${value##*[![:space:]]}"}"
        export "$name=${value}"
    fi
done < "$env_file"

for name in "${required[@]}"; do
    value="${!name}"

    if [[ -z "${value//[[:space:]]/}" ]]; then
        echo "ERROR: $name not defined" >&2
        exit 1
    fi
done

if [[ ! $APP_ID =~ ^com\.[a-z][a-z0-9]*\.[a-z][a-z0-9]*$ ]]; then
    echo "ERROR: APP_ID ${APP_ID} has an incorrect format."
    exit 1
fi

echo "OUTPUT           ---> $OUTPUT"
echo "APP_NAME         ---> $APP_NAME"
echo "APP_ID           ---> $APP_ID"

if [[ -n "$MIN_SDK" ]]; then
    echo "MIN_SDK          ---> $MIN_SDK"
fi

if [[ -n "$TEMPLATE" ]]; then
    echo "TEMPLATE   ---> $TEMPLATE"
fi

arguments=(
    "create"
    "--name=$APP_NAME"
    "--output=$OUTPUT"
)

if [[ -n "$MIN_SDK" ]]; then
    arguments+=("--minSdk=$MIN_SDK")
fi

if [[ -n "$TEMPLATE" ]]; then
    arguments+=("$TEMPLATE")
fi

while IFS= read -r line; do
    if [[ "$line" == ERROR:* ]]; then
        echo "$line" >&2
        exit 1
    fi

    echo "$line"
done < <(android "${arguments[@]}" 2>&1)

FILES_GRADLE="build.gradle.kts"

PATH_APP="app"
PATH_SRC="src"
PATH_MAIN="main"
PATH_ANDROID_TEST="androidTest"
PATH_TEST="test"
PATH_EXAMPLE="example"

error() {
  echo
  echo "Error: $1" >&2
  exit 1
}

exists() {
  [[ -e "$1" ]] || error "Not found: $1"
}

refactor_gradle_file() {
  local file="$1"
  local id="$2"

  sed -i.bak \
    -e "s/namespace[[:space:]]*=[[:space:]]*\"[^\"]*\"/namespace = \"$id\"/" \
    -e "s/applicationId[[:space:]]*=[[:space:]]*\"[^\"]*\"/applicationId = \"$id\"/" \
    "$file"

  rm -f "${file}.bak"
}

traverse_directory() {
  local dir="$1"
  local project="$2"
  local id="$3"

  [[ -d "$dir" ]] || return 0

  find "$dir" -type f \( -name "*.kt" -o -name "*.java" \) -print0 |
    while IFS= read -r -d '' file; do
      sed -i.bak "s|com\.example\.${project}|${id}|g" "$file"
      rm -f "${file}.bak"
    done
}

rename_folder() {
  local dir="$1"
  local from="$2"
  local to="$3"

  [[ -d "$dir" ]] || return 0

  find "$dir" -type d -name "$from" -print0 |
    while IFS= read -r -d '' folder; do
      mv "$folder" "$(dirname "$folder")/$to"
    done
}

IFS='.' read -r _ COMPANY PROJECT <<< "$APP_ID"

FULL_PATH_ROOT="$(realpath "$OUTPUT")"

echo "FULL_PATH_ROOT   ---> $FULL_PATH_ROOT"

# build.gradle.kts
FULL_PATH_GRADLE="$FULL_PATH_ROOT/$PATH_APP/$FILES_GRADLE"

echo "FULL_PATH_GRADLE ---> $FULL_PATH_GRADLE"

# Kotlin/Java folders
FULL_PATH_MAIN="$FULL_PATH_ROOT/$PATH_APP/$PATH_SRC/$PATH_MAIN"
FULL_PATH_ANDROID_TEST="$FULL_PATH_ROOT/$PATH_APP/$PATH_SRC/$PATH_ANDROID_TEST"
FULL_PATH_TEST="$FULL_PATH_ROOT/$PATH_APP/$PATH_SRC/$PATH_TEST"

SOURCE_DIRS=(
  "$FULL_PATH_MAIN"
  "$FULL_PATH_ANDROID_TEST"
  "$FULL_PATH_TEST"
)

echo "SOURCE_DIRS      --->"

for dir in "${SOURCE_DIRS[@]}"; do
  echo "  - $dir"
done

exists "$FULL_PATH_ROOT"

exists "$FULL_PATH_GRADLE"
exists "$FULL_PATH_MAIN"
exists "$FULL_PATH_ANDROID_TEST"
exists "$FULL_PATH_TEST"

refactor_gradle_file "$FULL_PATH_GRADLE" "$APP_ID"

for dir in "${SOURCE_DIRS[@]}"; do
  traverse_directory "$dir" "$PROJECT" "$APP_ID"
done

for dir in "${SOURCE_DIRS[@]}"; do
  rename_folder "$dir" "$PATH_EXAMPLE" "$COMPANY"
done

echo "✓ Done"
