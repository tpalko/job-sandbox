# -- from the start.sh entrypoint, since user-entered comamnds in the shell don't qualify as stdin/stdout
# -- the wrap function provides a way to advertise them
# -- and we might as well bookend the output with labels and timestamps because why not
function wrap() {
    
    fn=$1

    echo "************************************************************************************************************"
    echo "*********"
    echo "*********             BEGIN $1 -- $(date)"
    echo "*********"

    eval $1
    archive_builder_log $1

    echo "*********"
    echo "*********             END $1 -- $(date)"
    echo "*********"
    echo "************************************************************************************************************"
}

function archive_builder_log() {
    EXTRA=$1
    [[ -n ${EXTRA} ]] && EXTRA=_${EXTRA}
    [[ -f /opt/repo/builder.log ]] && mv -nv /opt/repo/builder.log /opt/repo/builder${EXTRA}_$(date +%Y%m%d_%H%M%S).log || echo "No builder.log to archive"
}

archive_builder_log old 