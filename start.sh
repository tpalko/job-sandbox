#!/bin/bash 

# this file is the entrypoint for the local test runner container 
# it transparently wraps the entire session in a shell 
# whose stdin/stderr is tee'd with START_LOG

trap cleanup 1 2 3 6 14 15 exit

function cleanup() {
    echo "Goodbye from the cleanup function!"   
}

echo "********************************************************************************************************"
echo "**"
echo "**                entering $0"
echo "**"

CMD="$@"

START_LOG=start_$(date +%Y%m%d_%H%M%S).log

echo "Command provided: \"${CMD}\""
echo "Logging to ${START_LOG}"

echo "Capture shell entries and bookend command output with 'wrap COMMAND'"
echo "Add sourcing and other shell setup in init.sh"
echo "Manually source anything else from ../pipeline-yaml/"
echo "Any cleanup to be done goes in start.sh cleanup()"

pushd /opt/repo > /dev/null

if [[ ! -f ../init.sh ]]; then  
    touch ../init.sh \
        && echo "Created ../init.sh - add common sourcing here"
else 
    echo "Found ../init.sh"
fi 

/bin/bash --init-file ../init.sh ${CMD} | tee -a ${START_LOG} 2>&1
