#!/bin/bash 

CONFIG_FOLDER="$(dirname $(readlink $0))"
IMAGE_NAME=job-sandbox

function menu() {
    local CHOICE_FILE="$1"
    local STORE_VAR="$2"
    local MENU_ITEM_INDEX=0
    local LINES=()
    local CHOICE
    while read LINE; do 
        echo "${MENU_ITEM_INDEX}: ${LINE}"
        MENU_ITEM_INDEX=$(( ${MENU_ITEM_INDEX} + 1 ))
        LINES+=(${LINE})
    done < <(sed -E "s/^.*=(.*)$/\1/g" $CHOICE_FILE)
    if [[ -n ${!STORE_VAR} ]]; then 
        echo "default: ${!STORE_VAR}"
    fi 
    echo -n "? "
    read CHOICE
    if [[ -n $CHOICE ]]; then 
        eval "$STORE_VAR=${LINES[$CHOICE]}"
    else 
        echo "Accepting default"
    fi 
}

export FROM 
menu ${CONFIG_FOLDER}/options/images.txt FROM
echo "You chose ${FROM}"

export IMGUSER
menu ${CONFIG_FOLDER}/options/users.txt IMGUSER
echo "You chose ${IMGUSER}"

export RUNPRIV
echo -n "Run privileged? y/N "
read RUNPRIV

export RUNROOT
echo -n "Run as root? y/N "
read RUNROOT

export PLATFORM=linux/$(uname -m)
menu ${CONFIG_FOLDER}/options/platforms.txt PLATFORM 
echo "You chose ${PLATFORM}"

function build() {

    pushd ${CONFIG_FOLDER}

    BUILDCMD="docker buildx build --no-cache --platform $PLATFORM --build-arg FROM=${FROM} --build-arg IMGUSER=${IMGUSER} -t $IMAGE_NAME ."
    echo ${BUILDCMD}

    ${BUILDCMD}

    popd 
}

function run() {

    PRIVS= 
    if [[ $RUNPRIV = y ]]; then 
        PRIVS="${PRIVS} --privileged"
    fi 
    if [[ $RUNROOT = y ]]; then 
        PRIVS="${PRIVS} -u 0"
    fi 

    RUNCMD="docker run --rm -it ${PRIVS} --env-file ${CONFIG_FOLDER}/env/gitlab_vars.env -v ${PWD}:/opt/repo $IMAGE_NAME $CMD"
    echo ${RUNCMD}

    ${RUNCMD}
}

if [[ ! -f ${CONFIG_FOLDER}/env/gitlab_vars.env ]]; then 
    echo "Please populate ${CONFIG_FOLDER}/env/gitlab_vars.env"
    exit 1
fi 

export CMD="/bin/bash"

if [[ $# -gt 0 ]]; then 
    CMD=$1
fi 

build && run
