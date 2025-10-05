#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DEFAULT_DB_WAIT_TIMEOUT=60
DEFAULT_DB_WAIT_INTERVAL=2

DB_WAIT_TIMEOUT=$DEFAULT_DB_WAIT_TIMEOUT
DB_WAIT_INTERVAL=$DEFAULT_DB_WAIT_INTERVAL

SKIP_BUILD=0
SKIP_START=0
SKIP_DB_WAIT=0
SKIP_HOST_PERMISSIONS=0
SKIP_PERMISSIONS=0
SKIP_APP_KEY=0
SKIP_ARTISAN=0
BUILD_ONLY=0
RUN_PULL=0
BUILD_COMPLETED=0

COMPOSE_CMD=()
COMPOSE_GLOBAL_ARGS=()
COMPOSE_UP_FLAGS=(--remove-orphans)
COMPOSE_BUILD_FLAGS=()
CONTAINERS_STARTED=0

COMPOSE_PROFILES=""
COMPOSE_PROJECT_NAME=""

ENABLE_REDIS_EXTENSION=1
REDIS_EXTENSION_VERSION=""
INSTALL_COMPOSER_DEPENDENCIES=1
INSTALL_NODE_DEPENDENCIES=1

usage() {
    cat <<'EOF'
Usage: docker-scripts/linux/setup.sh [options]

Options:
  -h, --help                   Show this help message and exit
  --pull                       Run docker compose pull before building
  --skip-build                 Skip docker image build step
  --skip-start                 Skip starting containers
  --skip-db-wait               Skip waiting for the database to become ready
  --skip-host-permissions      Do not adjust host storage/cache permissions
  --skip-permissions           Do not fix permissions inside the app container
  --skip-app-key               Skip APP_KEY generation check
  --skip-artisan               Skip Laravel post-setup artisan tasks
  --build-only                 Only build images (implies skip-start, skip-db-wait, skip-permissions, skip-app-key, skip-artisan)
  --with-node                  Enable the development profile (starts node watcher)
  --profiles LIST              Comma-separated list of docker compose profiles to enable
  --project-name NAME          Override docker compose project name
  --build-arg KEY=VALUE        Forward an additional build argument to docker compose build
  --no-remove-orphans          Do not pass --remove-orphans to docker compose up
  --compose-up-flag FLAG       Append a custom flag to docker compose up (may be repeated)
  --db-timeout SECONDS         Override database wait timeout (default: 60)
  --db-interval SECONDS        Wait interval between database checks (default: 2)
  --redis-version VERSION      Override Redis PECL extension version used during build
  --disable-redis-extension    Skip installing the Redis extension in the PHP image
  --enable-redis-extension     Force Redis extension installation (default behaviour)
  --skip-composer-install      Skip composer install inside the image
  --composer-install           Force composer install inside the image (default)
  --skip-node-install          Skip npm install/build inside the image
  --node-install               Force npm install/build inside the image (default)
EOF
}

add_profile() {
    local profile=$1
    if [[ -z "$COMPOSE_PROFILES" ]]; then
        COMPOSE_PROFILES="$profile"
    elif [[ ",$COMPOSE_PROFILES," != *",$profile,"* ]]; then
        COMPOSE_PROFILES+=",$profile"
    fi
}

require_positive_integer() {
    local value=$1
    local name=$2
    if ! [[ "$value" =~ ^[0-9]+$ ]] || (( value <= 0 )); then
        abort "$name must be a positive integer"
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            --pull)
                RUN_PULL=1
                ;;
            --skip-build)
                SKIP_BUILD=1
                ;;
            --skip-start)
                SKIP_START=1
                ;;
            --skip-db-wait)
                SKIP_DB_WAIT=1
                ;;
            --skip-host-permissions)
                SKIP_HOST_PERMISSIONS=1
                ;;
            --skip-permissions)
                SKIP_PERMISSIONS=1
                ;;
            --skip-app-key)
                SKIP_APP_KEY=1
                ;;
            --skip-artisan)
                SKIP_ARTISAN=1
                ;;
            --build-only)
                BUILD_ONLY=1
                SKIP_START=1
                SKIP_DB_WAIT=1
                SKIP_PERMISSIONS=1
                SKIP_APP_KEY=1
                SKIP_ARTISAN=1
                ;;
            --with-node)
                add_profile development
                ;;
            --profiles)
                [[ $# -lt 2 ]] && abort "--profiles requires a value"
                COMPOSE_PROFILES="$2"
                shift
                ;;
            --project-name)
                [[ $# -lt 2 ]] && abort "--project-name requires a value"
                COMPOSE_PROJECT_NAME="$2"
                shift
                ;;
            --build-arg)
                [[ $# -lt 2 ]] && abort "--build-arg requires a KEY=VALUE pair"
                COMPOSE_BUILD_FLAGS+=(--build-arg "$2")
                shift
                ;;
            --no-remove-orphans)
                COMPOSE_UP_FLAGS=()
                ;;
            --compose-up-flag)
                [[ $# -lt 2 ]] && abort "--compose-up-flag requires a value"
                COMPOSE_UP_FLAGS+=("$2")
                shift
                ;;
            --db-timeout)
                [[ $# -lt 2 ]] && abort "--db-timeout requires a value"
                require_positive_integer "$2" "--db-timeout"
                DB_WAIT_TIMEOUT=$2
                shift
                ;;
            --db-interval)
                [[ $# -lt 2 ]] && abort "--db-interval requires a value"
                require_positive_integer "$2" "--db-interval"
                DB_WAIT_INTERVAL=$2
                shift
                ;;
            --redis-version)
                [[ $# -lt 2 ]] && abort "--redis-version requires a value"
                REDIS_EXTENSION_VERSION="$2"
                shift
                ;;
            --disable-redis-extension)
                ENABLE_REDIS_EXTENSION=0
                ;;
            --enable-redis-extension)
                ENABLE_REDIS_EXTENSION=1
                ;;
            --skip-composer-install)
                INSTALL_COMPOSER_DEPENDENCIES=0
                ;;
            --composer-install)
                INSTALL_COMPOSER_DEPENDENCIES=1
                ;;
            --skip-node-install)
                INSTALL_NODE_DEPENDENCIES=0
                ;;
            --node-install)
                INSTALL_NODE_DEPENDENCIES=1
                ;;
            --)
                shift
                break
                ;;
            *)
                abort "Unknown option: $1"
                ;;
        esac
        shift
    done
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

abort() {
    log_error "$1"
    exit 1
}

require_command() {
    local cmd=$1
    command -v "$cmd" >/dev/null 2>&1 || abort "Missing required dependency: $cmd"
}

ensure_docker_access() {
    if ! output=$(docker info 2>&1); then
        if grep -iq "permission denied" <<< "$output"; then
            abort "Docker daemon is running but the current user lacks permission to access it. Add your user to the docker group or re-run via sudo."
        fi
        abort "Unable to communicate with the Docker daemon. Ensure it is running and reachable."
    fi
}

ENV_FILE="$PROJECT_ROOT/.env"
ENV_TEMPLATE="$PROJECT_ROOT/docker/env.example"

ensure_env_file() {
    if [[ ! -f "$ENV_TEMPLATE" ]]; then
        abort "Environment template not found at docker/env.example"
    fi

    if [[ ! -f "$ENV_FILE" ]]; then
        log_info "Creating .env from docker/env.example"
        cp "$ENV_TEMPLATE" "$ENV_FILE"
        log_warn "Review .env and update secrets (APP_KEY, DB_PASSWORD, REDIS_PASSWORD) before production use."
    fi
}

ensure_env_app_key_placeholder() {
    if ! grep -q '^APP_KEY=' "$ENV_FILE"; then
        log_warn "APP_KEY entry missing in .env; adding placeholder."
        printf '\nAPP_KEY=\n' >> "$ENV_FILE"
    fi
}

get_env_value() {
    local key=$1
    local default=${2:-}
    local value
    value=$(grep -E "^${key}=" "$ENV_FILE" | tail -n1 | cut -d '=' -f2-)
    value=${value:-$default}
    value="${value%$'\r'}"
    value="${value#\"}"
    value="${value%\"}"
    echo "$value"
}

ensure_directories() {
    log_info "Ensuring local storage directories exist"
    mkdir -p storage/logs storage/app/public bootstrap/cache docker/postgres/backup
}

set_host_permissions() {
    log_info "Fixing host permissions for storage and cache"
    chmod -R ug+rwX storage bootstrap/cache || log_warn "Failed to adjust host permissions; continuing."
}

resolve_compose_command() {
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_CMD=(docker-compose)
    else
        COMPOSE_CMD=(docker compose)
    fi
}

configure_compose_environment() {
    COMPOSE_GLOBAL_ARGS=()

    if [[ -n "$COMPOSE_PROJECT_NAME" ]]; then
        COMPOSE_GLOBAL_ARGS+=(-p "$COMPOSE_PROJECT_NAME")
    fi

    if [[ -n "$COMPOSE_PROFILES" ]]; then
        export COMPOSE_PROFILES="$COMPOSE_PROFILES"
    fi

    if (( ENABLE_REDIS_EXTENSION != 0 )); then
        export ENABLE_REDIS_EXTENSION=1
    else
        export ENABLE_REDIS_EXTENSION=0
    fi

    if [[ -n "$REDIS_EXTENSION_VERSION" ]]; then
        export REDIS_EXT_VERSION="$REDIS_EXTENSION_VERSION"
    else
        unset REDIS_EXT_VERSION 2>/dev/null || true
    fi

    if (( INSTALL_COMPOSER_DEPENDENCIES != 0 )); then
        export INSTALL_COMPOSER_DEPENDENCIES=1
    else
        export INSTALL_COMPOSER_DEPENDENCIES=0
    fi

    if (( INSTALL_NODE_DEPENDENCIES != 0 )); then
        export INSTALL_NODE_DEPENDENCIES=1
    else
        export INSTALL_NODE_DEPENDENCIES=0
    fi

    # BuildKit bails out with "lease does not exist" when bake runs several
    # heavyweight targets concurrently. Limit docker compose parallelism to keep
    # queue/app builds sequential unless the caller explicitly overrides it.
    if [[ -z "${COMPOSE_PARALLEL_LIMIT:-}" ]]; then
        export COMPOSE_PARALLEL_LIMIT=1
    fi
}

compose() {
    "${COMPOSE_CMD[@]}" "${COMPOSE_GLOBAL_ARGS[@]}" "$@"
}

service_exists() {
    local service=$1
    if compose config --services | grep -Fxq "$service"; then
        return 0
    fi
    return 1
}

build_containers() {
    log_info "Building Docker images"
    local services=()
    local build_args=()
    local service_built=0

    if ((${#COMPOSE_BUILD_FLAGS[@]})); then
        build_args=("${COMPOSE_BUILD_FLAGS[@]}")
    fi

    if mapfile -t services < <(
        compose config --format json \
            | python3 -c 'import json, sys
try:
    payload = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(1)
for name, svc in payload.get("services", {}).items():
    if isinstance(svc, dict) and svc.get("build"):
        print(name)'
    ); then
        if ((${#services[@]} == 0)); then
            log_warn "No services with build definitions found; skipping"
            return
        fi

        for svc in "${services[@]}"; do
            log_info "Building docker image for service '$svc'"
            if ((${#build_args[@]})); then
                compose build "${build_args[@]}" "$svc"
            else
                compose build "$svc"
            fi
            service_built=1
        done
        if (( service_built )); then
            BUILD_COMPLETED=1
        fi
        return
    fi

    log_warn "Falling back to docker compose build (parallel)"
    if ((${#build_args[@]})); then
        compose build "${build_args[@]}"
    else
        compose build
    fi
    BUILD_COMPLETED=1
}

maybe_install_dependencies() {
    if (( ! BUILD_COMPLETED )); then
        return
    fi

    if [[ -n "${CI:-}" || ! -t 0 ]]; then
        log_info "Skipping dependency prompts (non-interactive shell)"
        return
    fi

    echo
    log_info "Host bind mounts override image vendor/node_modules; optionally install them now."

    local answer
    read -rp "Run composer install inside the app container? [y/N] " answer || answer=""
    answer=${answer,,}
    if [[ $answer == y* ]]; then
        log_info "Installing PHP dependencies via composer"
        if compose run --rm app composer install --no-interaction --prefer-dist --no-ansi; then
            log_info "Composer install completed"
        else
            log_warn "composer install failed; rerun manually if needed"
        fi
    else
        log_info "Skipping composer install"
    fi

    read -rp "Run npm ci (and build assets) inside the app container? [y/N] " answer || answer=""
    answer=${answer,,}
    if [[ $answer == y* ]]; then
        log_info "Installing Node dependencies and building assets"
        if compose run --rm app sh -lc 'command -v npm >/dev/null'; then
            if compose run --rm app sh -lc 'npm ci && npm run build'; then
                log_info "npm ci/npm run build completed"
            else
                log_warn "npm ci/npm run build failed; rerun manually if needed"
            fi
        elif service_exists node; then
            log_info "npm is unavailable in the app container; using the node service instead"
            if compose run --rm node sh -lc 'npm ci && npm run build'; then
                log_info "npm ci/npm run build completed via node service"
            else
                log_warn "npm ci/npm run build via node service failed; rerun manually if needed"
            fi
        else
            log_warn "npm is not available in the app container and no node service is defined; skipping"
        fi
    else
        log_info "Skipping npm dependency install"
    fi
}

start_containers() {
    log_info "Starting containers"
    if ((${#COMPOSE_UP_FLAGS[@]})); then
        compose up -d "${COMPOSE_UP_FLAGS[@]}"
    else
        compose up -d
    fi
    CONTAINERS_STARTED=1
}

wait_for_postgres() {
    local db_user db_password db_name
    db_user=$(get_env_value DB_USERNAME internlink)
    db_password=$(get_env_value DB_PASSWORD password)
    db_name=$(get_env_value DB_DATABASE internlink)

    local interval=$DB_WAIT_INTERVAL
    local timeout=$DB_WAIT_TIMEOUT
    local max_attempts=$(((timeout + interval - 1) / interval))

    log_info "Waiting for postgres to become ready (timeout: ${timeout}s, interval: ${interval}s)"
    for ((i = 1; i <= max_attempts; i++)); do
        if compose exec -T postgres env PGPASSWORD="$db_password" pg_isready -d "$db_name" -U "$db_user" >/dev/null 2>&1; then
            return
        fi
        sleep "$interval"
    done

    abort "postgres did not become ready after ${timeout} seconds"
}

run_in_app() {
    compose exec -T app sh -lc "$1"
}

run_artisan() {
    compose exec -T app php artisan "$@"
}

ensure_app_permissions() {
    log_info "Fixing permissions inside application container"
    run_in_app 'chown -R www-data:www-data storage bootstrap/cache && chmod -R 775 storage bootstrap/cache'
}

ensure_app_key() {
    local app_key
    app_key=$(get_env_value APP_KEY)

    if [[ -z "$app_key" || "$app_key" == "null" || "$app_key" == "base64:" ]]; then
        log_info "Generating APP_KEY via artisan"
        run_artisan key:generate --force >/dev/null
    fi
}

laravel_post_setup() {
    log_info "Running Laravel post-setup tasks"
    run_artisan config:clear
    run_artisan cache:clear
    run_artisan migrate --force
    run_artisan db:seed --force
    run_artisan storage:link --force
}

print_summary() {
    if (( ! CONTAINERS_STARTED )); then
        log_info "Setup steps completed"
        log_warn "Containers were not started by this script; run ${COMPOSE_CMD[*]} up -d when ready."
        return
    fi

    log_info "Docker environment is ready to use!"
    echo "  Application   : http://localhost:8000"
    echo "  PostgreSQL    : localhost:5433"
    echo "  Redis         : localhost:6379"
    echo
    log_info "Common commands"
    echo "  ${COMPOSE_CMD[*]} up -d                # Start services"
    echo "  ${COMPOSE_CMD[*]} down                  # Stop services"
    echo "  ${COMPOSE_CMD[*]} logs -f app           # Tail application logs"
    echo "  ${COMPOSE_CMD[*]} exec app sh           # Shell into the app container"
}

main() {
    parse_args "$@"

    log_info "Setting up InternLink Docker environment"

    require_command docker
    ensure_docker_access

    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        abort "Docker Compose is required but not installed."
    fi

    resolve_compose_command
    configure_compose_environment

    ensure_env_file
    ensure_env_app_key_placeholder
    ensure_directories

    if (( SKIP_HOST_PERMISSIONS )); then
        log_info "Skipping host permission adjustments"
    else
        set_host_permissions
    fi

    if (( RUN_PULL )); then
        log_info "Pulling latest images"
        compose pull
    fi

    if (( SKIP_BUILD )); then
        log_info "Skipping Docker image build"
    else
        build_containers
        maybe_install_dependencies
    fi

    if (( BUILD_ONLY )); then
        log_info "Build-only mode complete"
        return
    fi

    if (( SKIP_START )); then
        log_info "Skipping container startup (ensure required services are already running)"
    else
        start_containers
    fi

    if (( SKIP_DB_WAIT )); then
        log_info "Skipping postgres readiness wait"
    else
        wait_for_postgres
    fi

    if (( SKIP_PERMISSIONS )); then
        log_info "Skipping in-container permission adjustments"
    else
        ensure_app_permissions
    fi

    if (( SKIP_APP_KEY )); then
        log_info "Skipping APP_KEY generation check"
    else
        ensure_app_key
    fi

    if (( SKIP_ARTISAN )); then
        log_info "Skipping Laravel post-setup tasks"
    else
        laravel_post_setup
    fi

    print_summary
}

main "$@"
