#!/usr/bin/env bash
# Monitoring continu orienté 504 (Cloudflare / proxy / Moodle)
# - Logge en continu: état conteneurs, docker stats, checks HTTP (proxy et intra-conteneur)
# - Sur anomalie (>=500, timeout), capture automatiquement des snapshots de logs
#
# Usage:
#   ./scripts/monitor-504-continuous.sh
#   MOODLE_HOST=ecole-en-ligne.ceredis.net INTERVAL_SECONDS=10 ./scripts/monitor-504-continuous.sh
#   LOG_DIR=/var/log/moodle-504-monitor ./scripts/monitor-504-continuous.sh
#
# Stop: Ctrl+C

set -u

MOODLE_HOST="${MOODLE_HOST:-ecole-en-ligne.ceredis.net}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-10}"
LOG_DIR="${LOG_DIR:-/tmp/moodle-504-monitor}"
PROXY_CONTAINER="${PROXY_CONTAINER:-coolify-proxy}"

mkdir -p "$LOG_DIR"
MAIN_LOG="$LOG_DIR/monitor.log"

now_iso() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

resolve_container() {
  local kind="$1";

  # Overrides explicites.
  case "$kind" in
    moodle)
      if [ -n "${MOODLE_CONTAINER:-}" ]; then echo "$MOODLE_CONTAINER"; return 0; fi
      ;;
    db)
      if [ -n "${DB_CONTAINER:-}" ]; then echo "$DB_CONTAINER"; return 0; fi
      ;;
    redis)
      if [ -n "${REDIS_CONTAINER:-}" ]; then echo "$REDIS_CONTAINER"; return 0; fi
      ;;
  esac

  # Détection Coolify (préfixes moodle-/db-/redis-).
  local name
  case "$kind" in
    moodle) name="$(docker ps --format '{{.Names}}' | grep -E '^moodle-' | head -n 1 || true)" ;;
    db)    name="$(docker ps --format '{{.Names}}' | grep -E '^db-' | head -n 1 || true)" ;;
    redis) name="$(docker ps --format '{{.Names}}' | grep -E '^redis-' | head -n 1 || true)" ;;
    *)     name="" ;;
  esac

  # Fallback stack locale.
  if [ -z "$name" ]; then
    case "$kind" in
      moodle) name="$(docker ps --format '{{.Names}}' | grep -E '^moodle_app$' | head -n 1 || true)" ;;
      db)    name="$(docker ps --format '{{.Names}}' | grep -E '^moodle_db$' | head -n 1 || true)" ;;
      redis) name="$(docker ps --format '{{.Names}}' | grep -E '^moodle_redis$' | head -n 1 || true)" ;;
    esac
  fi

  if [ -n "$name" ]; then
    echo "$name"
    return 0
  fi

  return 1
}

log_line() {
  echo "$(now_iso) $*" | tee -a "$MAIN_LOG" >/dev/null
}

docker_health_line() {
  local c="$1"
  docker inspect "$c" --format '{{.State.Status}}|{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}|{{.RestartCount}}' 2>/dev/null || echo "unknown|unknown|?"
}

# Check HTTP via proxy local (Traefik) avec Host header.
proxy_check() {
  local path="$1"
  curl -sS -o /dev/null -m 15 -w "%{http_code} %{time_total}" \
    "http://127.0.0.1${path}" -H "Host: ${MOODLE_HOST}" 2>/dev/null || echo "000 15.000"
}

# Check HTTP depuis l'intérieur du conteneur Moodle (bypass proxy) sans curl.
in_container_check() {
  local moodle_container="$1"
  local url="$2"

  docker exec "$moodle_container" php -r '
    $url = getenv("CHECK_URL");
    $t0 = microtime(true);
    $h = @get_headers($url, 0);
    $dt = microtime(true) - $t0;
    if (!$h || !isset($h[0])) {
      echo "000 ";
      printf("%.3f", $dt);
      echo "\n";
      exit(1);
    }
    if (preg_match("#\\s(\\d{3})\\s#", $h[0], $m)) {
      echo $m[1] . " ";
    } else {
      echo "000 ";
    }
    printf("%.3f", $dt);
    echo "\n";
  ' 2>/dev/null
}

snapshot() {
  local reason="$1"
  local stamp
  stamp="$(date -u +%Y%m%d_%H%M%S)"
  local dir="$LOG_DIR/snapshot_${stamp}"
  mkdir -p "$dir"

  {
    echo "timestamp=$(now_iso)"
    echo "reason=$reason"
    echo "moodle_host=$MOODLE_HOST"
    echo "--- docker ps (filtered) ---"
    docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' | egrep -i '(^moodle-|^db-|^redis-|coolify-proxy|traefik|mariadb|redis)' || true
    echo "--- docker stats (no-stream) ---"
    docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}' || true
  } > "$dir/state.txt" 2>&1

  if docker ps --format '{{.Names}}' | grep -qx "$PROXY_CONTAINER"; then
    docker logs "$PROXY_CONTAINER" --since 10m > "$dir/proxy.log" 2>&1 || true
  fi

  local moodle_container
  moodle_container="$(resolve_container moodle 2>/dev/null || true)"
  if [ -n "$moodle_container" ]; then
    docker logs "$moodle_container" --since 10m > "$dir/moodle.log" 2>&1 || true
  fi

  log_line "SNAPSHOT reason=\"$reason\" path=$dir"
}

log_line "START host=$MOODLE_HOST interval=${INTERVAL_SECONDS}s logdir=$LOG_DIR"

while true; do
  moodle_container="$(resolve_container moodle 2>/dev/null || true)"
  db_container="$(resolve_container db 2>/dev/null || true)"
  redis_container="$(resolve_container redis 2>/dev/null || true)"

  moodle_state="-"; db_state="-"; redis_state="-"
  if [ -n "$moodle_container" ]; then moodle_state="$(docker_health_line "$moodle_container")"; fi
  if [ -n "$db_container" ]; then db_state="$(docker_health_line "$db_container")"; fi
  if [ -n "$redis_container" ]; then redis_state="$(docker_health_line "$redis_container")"; fi

  proxy_root="$(proxy_check /)"
  proxy_login="$(proxy_check /login/index.php)"

  in_login="-"
  if [ -n "$moodle_container" ]; then
    in_login="$(CHECK_URL='http://127.0.0.1/login/index.php' in_container_check "$moodle_container" 'http://127.0.0.1/login/index.php' | tr -d '\r' || echo '000 0.000')"
  fi

  log_line "STATUS moodle=${moodle_container:-none} moodle_state=$moodle_state db=${db_container:-none} db_state=$db_state redis=${redis_container:-none} redis_state=$redis_state proxy_root=\"$proxy_root\" proxy_login=\"$proxy_login\" in_login=\"$in_login\""

  # Déclencheur snapshot si proxy renvoie 5xx/000, ou si le check in-container échoue.
  proxy_root_code="${proxy_root%% *}"
  proxy_login_code="${proxy_login%% *}"
  in_login_code="${in_login%% *}"

  if [[ "$proxy_root_code" =~ ^5 ]] || [[ "$proxy_login_code" =~ ^5 ]] || [[ "$proxy_root_code" == "000" ]] || [[ "$proxy_login_code" == "000" ]]; then
    snapshot "proxy_error root=$proxy_root login=$proxy_login"
  elif [[ "$in_login_code" =~ ^5 ]] || [[ "$in_login_code" == "000" ]]; then
    snapshot "moodle_internal_error in_login=$in_login"
  fi

  sleep "$INTERVAL_SECONDS"
done
