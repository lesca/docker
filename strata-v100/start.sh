#!/bin/sh
cd "/opt/strata"
exec "/opt/strata/.venv/bin/python" "/opt/strata/serve/server.py" "--engine" "strata" "--config" "/opt/strata/strata-swift-iq2_xs.json" "--port" "8080" "--open"
