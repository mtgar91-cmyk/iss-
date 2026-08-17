#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

: "${TELEGRAM_BOT_TOKEN:?TELEGRAM_BOT_TOKEN is required}"

mkdir -p runtime/redis

if ! redis-cli -h 127.0.0.1 -p 6379 ping >/dev/null 2>&1; then
  redis-server \
    --bind 127.0.0.1 \
    --port 6379 \
    --dir "$PWD/runtime/redis" \
    --dbfilename dump.rdb \
    --save "" \
    --appendonly no \
    --daemonize yes
fi

export PATH="${HOST_PATH:-$PATH}:$PATH"
GCC_LIB_DIR="$(dirname "$(gcc -print-file-name=libstdc++.so.6)")"
export LD_LIBRARY_PATH="$PWD/runtime/lib:$GCC_LIB_DIR${REPLIT_LD_LIBRARY_PATH:+:$REPLIT_LD_LIBRARY_PATH}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

LUA53_LUASEC_ROOT=""
LUA53_LUASOCKET_ROOT=""
for root in ${buildInputs:-}; do
  case "$root" in
    *lua5.3-luasec-*) LUA53_LUASEC_ROOT="$root" ;;
    *lua5.3-luasocket-*) LUA53_LUASOCKET_ROOT="$root" ;;
  esac
done

export LUA_PATH="./?.lua;./?/init.lua${LUA53_LUASEC_ROOT:+;$LUA53_LUASEC_ROOT/share/lua/5.3/?.lua}${LUA53_LUASOCKET_ROOT:+;$LUA53_LUASOCKET_ROOT/share/lua/5.3/?.lua};;"
export LUA_CPATH="./?.so${LUA53_LUASEC_ROOT:+;$LUA53_LUASEC_ROOT/lib/lua/5.3/?.so}${LUA53_LUASOCKET_ROOT:+;$LUA53_LUASOCKET_ROOT/lib/lua/5.3/?.so};;"

exec lua Mero.lua