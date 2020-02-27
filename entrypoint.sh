#!/bin/sh

set -e

# load up the default database (unconditionally for now)
# rake db:create
# rake db:schema:load
# rake db:load[force]

# Remove a potentially pre-existing server.pid for Rails.
rm -f /myapp/tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
