#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${SITES_ENV_READY:-}" != "1" ]]; then
  exec "${script_dir}/sites-env.sh" -- "$0" "$@"
fi

command -v timeout || {
  echo "build-verified.sh requires GNU timeout." >&2
  exit 69
}

astro="${SITES_PROJECT_ROOT}/node_modules/.bin/astro"
if [[ ! -x "${astro}" ]]; then
  echo "Astro is unavailable. Run npm run install:ci and wait for it to finish before building." >&2
  exit 69
fi

echo "Running bounded Astro build..."
export ASTRO_TELEMETRY_DISABLED=1
timeout \
  --signal=TERM \
  --kill-after="${SITES_BUILD_KILL_AFTER:-10s}" \
  "${SITES_BUILD_TIMEOUT:-3m}" \
  "${astro}" build

mkdir -p "${SITES_PROJECT_ROOT}/dist/server" "${SITES_PROJECT_ROOT}/dist/.openai"
printf '%s\n' 'export default { fetch(request, env, ctx) { return import("./entry.mjs").then((worker) => worker.default.fetch(request, env, ctx)); } };' > "${SITES_PROJECT_ROOT}/dist/server/index.js"
cp "${SITES_PROJECT_ROOT}/.openai/hosting.json" "${SITES_PROJECT_ROOT}/dist/.openai/hosting.json"

"${script_dir}/validate-artifact.sh"
