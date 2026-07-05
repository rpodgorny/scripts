#!/usr/bin/env bash
#
# homeassistant_podman.sh — launch/upgrade Home Assistant in rootful Podman
# with the host's Bluetooth (BlueZ, via the D-Bus system socket) passed through.
#
# Re-run this script any time to UPGRADE: it pulls the configured image tag and
# recreates the container. Everything in /config persists across upgrades, so a
# bump is safe (but still snapshot the config dir before big version jumps).
#
# Verified on this host: HA sets up the BlueZ adapter and discovers BTHome
# sensors. Bluetooth is shared via the D-Bus socket — no raw device / --privileged.
#
set -euo pipefail

# ------------------------------ configuration -------------------------------
# Override any of these via the environment, e.g.:
#   HA_IMAGE_TAG=2026.7.1 ~/scripts/homeassistant_podman.sh
CONTAINER_NAME="${HA_CONTAINER_NAME:-homeassistant}"
IMAGE_REPO="${HA_IMAGE_REPO:-ghcr.io/home-assistant/home-assistant}"
IMAGE_TAG="${HA_IMAGE_TAG:-stable}"        # stable | beta | rc | 2026.7 | 2026.7.1 ...
TZ_VALUE="${HA_TZ:-Europe/Prague}"

# Persistent HA config lives here (survives upgrades). Resolves the invoking
# user's real home even when the script is run through sudo.
REAL_USER="${SUDO_USER:-${USER:-root}}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
CONFIG_DIR="${HA_CONFIG_DIR:-${REAL_HOME}/homeassistant}"

DBUS_SOCK="/run/dbus/system_bus_socket"
# ----------------------------------------------------------------------------

IMAGE="${IMAGE_REPO}:${IMAGE_TAG}"

# Rootful Podman is required (container runs as root so D-Bus EXTERNAL auth
# matches, and HA's s6 init stays happy). Run podman directly if already root,
# otherwise wrap each call in sudo.
if [[ "$(id -u)" -eq 0 ]]; then
  PODMAN=(podman)
else
  PODMAN=(sudo podman)
fi

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# -------------------------------- preflight ---------------------------------
command -v podman >/dev/null 2>&1 || die "podman not found in PATH."

systemctl is-active --quiet bluetooth \
  || die "host bluetoothd is not active — run: sudo systemctl enable --now bluetooth"

[[ -S "$DBUS_SOCK" ]] || die "D-Bus system socket not found at $DBUS_SOCK"

mkdir -p "$CONFIG_DIR"

# ---------------------------- pull + (re)create -----------------------------
log "Pulling ${IMAGE} ..."
"${PODMAN[@]}" pull "$IMAGE"

log "Launching '${CONTAINER_NAME}'  (config: ${CONFIG_DIR}) ..."
"${PODMAN[@]}" run \
  --name "$CONTAINER_NAME" \
  --replace \
  --restart=unless-stopped \
  --net=host \
  --label "io.containers.autoupdate=registry" \
  -e "TZ=${TZ_VALUE}" \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -v "${DBUS_SOCK}:${DBUS_SOCK}" \
  -v "${CONFIG_DIR}:/config" \
  "$IMAGE"

log "Home Assistant is starting (first boot can take 1-2 min)."
cat <<EOF

  UI:      http://localhost:8123
  Logs:    ${PODMAN[*]} logs -f ${CONTAINER_NAME}
  Status:  ${PODMAN[*]} ps --filter name=${CONTAINER_NAME}
  Upgrade: re-run this script (pulls '${IMAGE_TAG}', recreates, keeps /config)

  Start on boot: enable Podman's restart service once:
      sudo systemctl enable podman-restart.service
EOF
