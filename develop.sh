#!/bin/sh

set -eu

# This image runs Medusa v2, whose migration command is `medusa db:migrate`.
# For a Medusa v1 image, replace it with `medusa migrations run`.
migrate_database() {
  echo "Running Medusa database migrations..."
  pnpm exec medusa db:migrate
}

create_default_admin() {
  admin_email="${MEDUSA_ADMIN_EMAIL:-admin@medusa-test.com}"
  admin_password="${MEDUSA_ADMIN_PASSWORD:-Medusa_Admin#2026-ChangeMe!}"
  admin_log="$(mktemp)"

  # The v2 CLI uses `medusa user --email ... --password ...`. Medusa v1 uses
  # the same user command, although older releases commonly use `-e` and `-p`.
  if pnpm exec medusa user \
    --email "$admin_email" \
    --password "$admin_password" >"$admin_log" 2>&1; then
    cat "$admin_log"
    rm -f "$admin_log"
    echo "Default Medusa admin created."
    return
  else
    admin_status=$?
  fi

  # Creating the user is the atomic existence check: PostgreSQL/Medusa rejects
  # a duplicate email. Only that expected conflict is safe to ignore; all other
  # failures remain fatal so a broken deployment cannot appear healthy.
  if grep -Eiq \
    'already exists|duplicate key|duplicate_error|unique constraint|23505' \
    "$admin_log"; then
    rm -f "$admin_log"
    echo "A Medusa admin with email $admin_email already exists; skipping creation."
    return
  fi

  echo "Failed to create the default Medusa admin." >&2
  cat "$admin_log" >&2
  rm -f "$admin_log"
  return "$admin_status"
}

start_server() {
  echo "Starting Medusa..."
  # Production uses `medusa start`. Use `medusa develop` only in a development
  # image where live reload and development dependencies are available.
  exec pnpm exec medusa start
}

migrate_database
create_default_admin
start_server
