docker_usage() {
    cat <<EOF

Usage: docker [COMMAND]

This is the convenience wrapper for buildctl to mimic the behaviour
of docker CLI. Note that not all subcommands and parameters are
supported.

Commands:
  build       Build an image from a Dockerfile
  login       Log in to a Docker registry
  logout      Log out from a Docker registry

Run 'docker COMMAND --help' for more information on a command.
EOF
}

docker_build_usage() {
    cat <<EOF

Usage: docker build [OPTIONS] PATH | URL

This is the convenience wrapper for buildctl to mimic the behaviour
of docker CLI. Note that not all subcommands and parameters are
supported.

Build an image from a Dockerfile

Options:
      --build-arg list   Set build-time variables
      --cache-from       Images to consider as cache sources
  -f, --file string      Name of the Dockerfile (Default is 'PATH/Dockerfile')
  -t, --tag list         Name and optionally a tag in the 'name:tag' format
      --target string    Set the target build stage to build.
EOF
}

docker_login_usage() {
    cat <<EOF

Usage:  docker login [OPTIONS] [SERVER]

This is the convenience wrapper for buildctl to mimic the behaviour
of docker CLI. Note that not all subcommands and parameters are
supported.

Log in to a Docker registry.
If no server is specified, the default is defined by the daemon.

Options:
  -p, --password string   Password
      --password-stdin    Take the password from stdin
  -u, --username string   Username
EOF
}

docker_logout_usage() {
    cat <<EOF

Usage:  docker logout [SERVER]

Log out from a Docker registry.
If no server is specified, the default is defined by the daemon.
EOF
}

docker() {
    case "$1" in
        build)
            shift
            docker_build "$@"
            ;;
        login)
            shift
            docker_login "$@"
            ;;
        logout)
            shift
            docker_logout "$@"
            ;;
        *)
            docker_usage
            return 1
            ;;
    esac
}

docker_build() {
    if [[ "$#" -eq 0 ]]; then
        docker_build_usage
        return
    fi

    DOCKER_BUILD_FILE=./Dockerfile
    declare -a DOCKER_BUILD_ARG
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --file|-f)
                shift
                DOCKER_BUILD_FILE=$(dirname $1)
                ;;
            --build-arg)
                shift
                DOCKER_BUILD_ARG+=($1)
                ;;
            --tag|-t)
                shift
                DOCKER_BUILD_TAG=$1
                ;;
            --target)
                shift
                DOCKER_BUILD_TARGET=$1
                ;;
            --)
                break
                ;;
            --help)
                docker_build_usage
                return
                ;;
            --*|-*)
                echo "unknown flag: $1"
                echo "See 'docker build --help'."
                return 1
                ;;
            *)
                DOCKER_BUILD_CONTEXT=$1
                ;;
        esac
        shift
    done

    DOCKER_BUILD_ARGS=""
    for INDEX in ${!DOCKER_BUILD_ARG[@]}; do
        DOCKER_BUILD_ARGS="${DOCKER_BUILD_ARGS} --opt build-arg:${DOCKER_BUILD_ARG[$INDEX]}"
    done

    DOCKER_BUILD_TARGET_PARAM=""
    if [[ -n "${DOCKER_BUILD_TARGET}" ]]; then
        DOCKER_BUILD_TARGET_PARAM="-opt target:${DOCKER_BUILD_TARGET}"
    fi

    DOCKER_BUILD_NAME=""
    if [[ -n "${DOCKER_BUILD_TAG}" ]]; then
        DOCKER_BUILD_NAME="--output type=image,name=${DOCKER_BUILD_TAG},push=true"
    fi

    buildctl build \
        --frontend=dockerfile.v0 \
        --local context=${DOCKER_BUILD_CONTEXT} \
        --local dockerfile=${DOCKER_BUILD_FILE} \
        $DOCKER_BUILD_ARGS \
        ${DOCKER_BUILD_TARGET_PARAM} \
        --export-cache type=inline \
        $DOCKER_BUILD_NAME
}

docker_login() {
    USERNAME=""
    PASSWORD=""
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -u|--username)
                shift
                USERNAME=$1
                ;;
            -p|--password)
                shift
                PASSWORD=$1
                ;;
            --password-stdin)
                PASSWORD=$(cat)
                ;;
            --)
                break
                ;;
            *)
                REGISTRY=$1
                ;;
        esac

        shift
    done
    : "${REGISTRY:=https://index.docker.io/v1/}"

    if [[ -z "${USERNAME}" ]]; then
        read -p "Username: " USERNAME
    fi
    if [[ -z "${PASSWORD}" ]]; then
        read -s -p "Password: " PASSWORD
        echo
    fi

    : "${DOCKER_CONFIG:=${HOME}/.docker}"
    mkdir -p "${DOCKER_CONFIG}"
    if [[ -f "${DOCKER_CONFIG}/config.json" ]]; then
        CONFIG=$(cat "${DOCKER_CONFIG}/config.json")
    else
        CONFIG='{"auths":{}}'
    fi

    echo "${CONFIG}" | \
        jq \
            --arg registry ${REGISTRY} \
            'delpaths([["auths", ($registry)]])' |
        jq \
            --arg registry ${REGISTRY} \
            --arg auth $(echo -n "${USERNAME}:${PASSWORD}" | base64) \
            '.auths += {($registry): {'auth': $auth}}' \
    >"${DOCKER_CONFIG}/config.json"
}

docker_logout() {
    case "$1" in
        --help)
            docker_logout_usage
            return
            ;;
        *)
            REGISTRY=$1
            ;;
    esac
    : "${REGISTRY:="https://index.docker.io/v1/"}"

    : "${DOCKER_CONFIG:=${HOME}/.docker}"
    mkdir -p "${DOCKER_CONFIG}"
    if [[ -f "${DOCKER_CONFIG}/config.json" ]]; then
        CONFIG=$(cat "${DOCKER_CONFIG}/config.json")
    fi

    echo "${CONFIG}" | \
        jq \
            --arg registry ${REGISTRY} \
            'delpaths([["auths", ($registry)]])' \
    >"${DOCKER_CONFIG}/config.json"
}