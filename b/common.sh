YELLOW='\033[1;33m'
RESET='\033[0m'

PS4="${YELLOW}+ ${RESET}"

cleanup() {
  trap - INT TERM   # disable trap immediately
  set +x   # stop the spam
  echo "Interrupted exiting"
  kill 0
  exit 130
}

trap cleanup INT TERM

set -euo pipefail

export bd="build-release"
export n="Arabic-Lexicons"
export ver=$(
    grep '^version:' pubspec.yaml \
    | head -n1 \
    | cut -d' ' -f2 \
    | cut -d'+' -f1
)

# ver=$(grep 'version' pubspec.yaml | sed 's/version: //')
export gc=$(git rev-parse HEAD)
# export gcm=$(git log -1 --pretty='%B' | tr '\n' ' ' | sed 's/^ *//; s/ *$//')

if [ -z "$ver" ]; then
  echo "version cannot be empty!!"
  exit 130
fi

export pre="$bd/${n}_v$ver"
