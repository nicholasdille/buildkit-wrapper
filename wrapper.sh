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
            echo "Usage: docker login|build|logout"
            return 1
            ;;
    esac
}

docker_build() {
    if [[ "$#" -lt 1 ]]; then
        echo "Usage: docker build <context>"
    fi

    DOCKER_BUILD_FILE=./Dockerfile
    declare -a DOCKER_BUILD_ARG
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --file|-f)
                shift
                DOCKER_BUILD_FILE=$1
                ;;
            --build-arg)
                shift
                DOCKER_BUILD_ARG+=($1)
                ;;
            --tag|-t)
                shift
                DOCKER_BUILD_TAG=$1
                ;;
            --)
                break
                ;;
            --*|-*)
                echo "Error: Unknown parameter $1"
                return 1
                ;;
            *)
                DOCKER_BUILD_CONTEXT=$1
                ;;
        esac
        shift
    done

    #echo DOCKER_BUILD_FILE=${DOCKER_BUILD_FILE}
    #echo DOCKER_BUILD_CONTEXT=${DOCKER_BUILD_CONTEXT}
    #echo DOCKER_BUILD_TAG=${DOCKER_BUILD_TAG}
    #echo DOCKER_BUILD_ARG=${DOCKER_BUILD_ARG[*]}

    DOCKER_BUILD_ARGS=""
    for INDEX in ${!DOCKER_BUILD_ARG[@]}; do
        DOCKER_BUILD_ARGS="${DOCKER_BUILD_ARGS} --opt build-arg:${DOCKER_BUILD_ARG[$INDEX]}"
    done

    DOCKER_BUILD_NAME=""
    if [[ -n "${DOCKER_BUILD_TAG}" ]]; then
        DOCKER_BUILD_NAME="--output type=image,name=${DOCKER_BUILD_TAG},push=true"
    fi

    buildctl build \
        --frontend=dockerfile.v0 \
        --local context=${DOCKER_BUILD_CONTEXT} \
        --local dockerfile=${DOCKER_BUILD_FILE} \
        $DOCKER_BUILD_ARGS \
        --export-cache type=inline \
        $DOCKER_BUILD_NAME
}

docker_login() {
    : "${DOCKER_CONFIG:=${HOME}/.docker}"
    mkdir -p "${DOCKER_CONFIG}"
    if [[ -f "${DOCKER_CONFIG}/config.json" ]]; then
        CONFIG=$(cat "${DOCKER_CONFIG}/config.json")
    else
        CONFIG="{'auths':{}}"
    fi

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

    echo REGISTRY=${REGISTRY}
    echo USERNAME=${USERNAME}
    echo PASSWORD=${PASSWORD}

    echo "${CONFIG}" | \
        jq \
            --arg registry ${REGISTRY} \
            --arg auth $(echo -n "${USERNAME}:${PASSWORD}" | base64) \
            '.auths += {($registry): {'auth': $auth}}' \
    >"${DOCKER_CONFIG}/config.json"
}

docker_logout() {
    : "${DOCKER_CONFIG:=${HOME}/.docker}"
    mkdir -p "${DOCKER_CONFIG}"
    if [[ -f "${DOCKER_CONFIG}/config.json" ]]; then
        CONFIG=$(cat "${DOCKER_CONFIG}/config.json")
    fi

    if [[ -n "$1" ]]; then
        REGISTRY=$1
    else
        REGISTRY=https://index.docker.io/v1/
    fi

    : "${REGISTRY:=index.docker.io}"
    echo "${CONFIG}" | \
        jq \
            --arg registry ${REGISTRY} \
            'delpaths([["auths", ($registry)]])' \
    >"${DOCKER_CONFIG}/config.json"
}