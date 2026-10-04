#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
tooling_dir="$(dirname "$project_dir")/.tooling"
if [[ -d "$tooling_dir/jdk21/jdk-21.0.12.1.jdk/Contents/Home" ]]; then
  export JAVA_HOME="$tooling_dir/jdk21/jdk-21.0.12.1.jdk/Contents/Home"
fi
maven_cmd="${MAVEN_CMD:-mvn}"
if [[ -x "$tooling_dir/apache-maven-3.9.11/bin/mvn" ]]; then
  maven_cmd="$tooling_dir/apache-maven-3.9.11/bin/mvn"
fi
mkdir -p "$project_dir/.local"
cd "$project_dir/backend"
"$maven_cmd" -Dmaven.repo.local="$tooling_dir/m2" -q spring-boot:run > "$project_dir/.local/backend.log" 2>&1 &
backend_pid=$!
cleanup(){ kill "$backend_pid" "${web_pid:-$backend_pid}" 2>/dev/null || true; }
trap cleanup EXIT INT TERM
cd "$project_dir/web"
[[ -d node_modules ]] || npm ci
npm run dev > "$project_dir/.local/web.log" 2>&1 &
web_pid=$!
printf 'Web: http://127.0.0.1:3001\nJava: http://127.0.0.1:8080\nLogs: %s/.local/\nPress Ctrl+C to stop.\n' "$project_dir"
wait "$backend_pid" "$web_pid"
