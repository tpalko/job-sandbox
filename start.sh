#!/bin/bash 

# this file is the entrypoint for the local test runner container 
# it transparently wraps the entire session in a shell 
# whose stdin/stderr is tee'd with START_LOG

trap cleanup 1 2 3 6 14 15 exit

echo "********************************************************************************************************"
echo "**"
echo "**                entering $0"
echo "**"

# . common.sh 

CMD="$@"

START_LOG=start_$(date +%Y%m%d_%H%M%S).log

echo "Command provided: \"${CMD}\""
echo "Logging to ${START_LOG}"
echo "Source ../pipeline-yaml/util.sh for 'wrap', e.g."
echo ". ../pipeline-yaml/util.sh"
echo "Source anything else in ../pipeline-yaml for your custom operations"

pushd /opt/repo > /dev/null
$@ | tee -a ${START_LOG} 2>&1
