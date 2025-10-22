#!/bin/sh
set -e

# Resolve port with default
PORT_TO_USE="${PORT:-8080}"

exec gunicorn app:app \
  --bind "0.0.0.0:${PORT_TO_USE}" \
  --workers 2 \
  --timeout 120 \
  --log-level info

