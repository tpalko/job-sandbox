#!/bin/bash 

set -e 

CONFIG_FOLDER="$(dirname $(readlink $0))"
IMAGE_NAME=job-sandbox

function file_as_menu() {
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

    echo "default: -->${!STORE_VAR}"
    echo -n "? "
    
    if [[ $INTERACTIVE = 1 ]]; then 
        read CHOICE
    fi 

    if [[ $INTERACTIVE = 0 || -z $CHOICE ]]; then 
        echo "Accepting default"
    fi 

    if [[ -n $CHOICE ]]; then   
        eval "$STORE_VAR=${LINES[$CHOICE]}"
    elif [[ ${!STORE_VAR} != \"\" && -n ${!STORE_VAR} ]]; then 
        echo "Setting ${STORE_VAR} = LINES choice of ${!STORE_VAR} which is ${LINES[${!STORE_VAR}]}"
        eval "$STORE_VAR=${LINES[${!STORE_VAR}]}"
    fi 
}

function var_as_menu() {
    local QUESTION="$1"
    local STORE_VAR="$2"
    local CHOICE
    echo "${QUESTION}? "
    
    echo "default: -->${!STORE_VAR}"
    echo -n "? "

    if [[ $INTERACTIVE = 1 ]]; then 
        read CHOICE
    fi 
    if [[ $INTERACTIVE = 0 || -z $CHOICE ]]; then 
        echo "Accepting default"
    fi 

    if [[ -n $CHOICE ]]; then   
        eval "$STORE_VAR=${CHOICE}"
    fi 
}

function collect() {
    
    export FROM=${CHOICES[0]}
    file_as_menu ${CONFIG_FOLDER}/options/images.txt FROM
    echo "You chose ${FROM}"

    export IMGUSER=${CHOICES[1]}
    file_as_menu ${CONFIG_FOLDER}/options/users.txt IMGUSER
    echo "You chose ${IMGUSER}"

    export RUNPRIV=${CHOICES[2]}
    var_as_menu "Run privileged? y/N " RUNPRIV
    echo "You chose ${RUNPRIV}"

    export RUNROOT=${CHOICES[3]}
    var_as_menu "Run as root? y/N " RUNROOT
    echo "You chose ${RUNROOT}"

    export PLATFORM=linux/$(uname -m)
    file_as_menu ${CONFIG_FOLDER}/options/platforms.txt PLATFORM 
    echo "You chose ${PLATFORM}"
}

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

    RUNCMD="docker run --rm -it ${PRIVS} -e CI_PROJECT_DIR=/opt/repo --env-file ${CONFIG_FOLDER}/env/gitlab_vars.env -v ${PWD}:/opt/repo $IMAGE_NAME $CMD"
    echo ${RUNCMD}

    ${RUNCMD}
}

if [[ ! -f ${CONFIG_FOLDER}/env/gitlab_vars.env ]]; then 
    echo "Please populate ${CONFIG_FOLDER}/env/gitlab_vars.env"
    exit 1
fi 

export CMD= #"/bin/bash"
export INTERACTIVE=1

CHOICES=()
while [[ $# -gt 0 ]]; do 
  #echo "Parsing outside parameter -->$1"
  case $1 in 
    -p) shift
        while [[ $# -gt 0 ]]; do 
            #echo "Parsing pipeline parameter -->$1"
            ([[ "$1" = "-y" ]] || [[ "$1" = "-c" ]]) && break 
            echo "Adding $1 to CHOICES"
            CHOICES+=($1)
            shift 
        done 
        ;;
    -y) INTERACTIVE=0
        shift 
        ;;
    -c) CMD=$2
        shift; shift 
        ;;
    *)  echo "ignoring $1"
        shift 
        ;;
  esac
done 

if [[ ${INTERACTIVE} = 0 && -f ${CONFIG_FOLDER}/pipelines.sh && ${#CHOICES[@]} -eq 0 ]]; then 
    echo "Found ${CONFIG_FOLDER}/pipelines.sh"
    while read -e PIPELINE_JOB; do 
        echo "Executing ${PIPELINE_JOB}"
        ${PIPELINE_JOB} 
    done < <(cat ${CONFIG_FOLDER}/pipelines.sh | grep -vE "^#|^$")
    exit 0
else 
    echo "Not attempting to execute on a possible ${CONFIG_FOLDER}/pipelines.sh"
fi 

echo "Collecting parameters with ${#CHOICES[@]} preselected"
for CHOICE in "${CHOICES[@]}"; do 
    echo ${CHOICE}
done  

collect

build && run
