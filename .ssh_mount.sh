sshmount() {

    diskName=$1
    diskDir="${HOME}/sshfsVolumes/${diskName}"

    unameOut="$(uname -s)"
    if [ $(uname -s) == "Darwin" ]; then
        umount_cmd="diskutil umount force"
        dst_options="-o auto_cache,reconnect,defer_permissions,noappledouble"
        tunnel_options="-o allow_other,defer_permissions,IdentityFile=~/.ssh/id_rsa"
    elif [ $(uname -s) == "Linux" ]; then
        umount_cmd="fusermount3 -u"
        dst_options=""
        tunnel_options="-o IdentityFile=${HOME}/.ssh/id_rsa"
    else
        echo "unknown system"
    fi

    cd "$HOME" || exit
    if [[ ! -e ${diskDir} ]]; then
        mkdir -p "$diskDir"
    else
        eval "${umount_cmd} ${diskDir}"
    fi

    if [ "$diskName" == "ela" ]; then
        command="sshfs ela:/users/jcanton/ ${diskDir} ${dst_options}"

    elif [ "$diskName" == "daint" ]; then
        command="sshfs daint:/users/jcanton/ ${diskDir} ${dst_options}"

    elif [ "$diskName" == "daintScratch" ]; then
        command="sshfs daint:/scratch/snx3000/jcanton/ ${diskDir} ${dst_options}"

    elif [ "$diskName" == "pr133" ]; then
        command="sshfs daint:/project/pr133/jcanton/ ${diskDir} ${dst_options}"

    elif [ "$diskName" == "g142" ]; then
        command="sshfs daint:/store/g142/jcanton/ ${diskDir} ${dst_options}"

    elif [ "$diskName" == "d121" ]; then
        command="sshfs daint:/project/d121/jcanton/ ${diskDir} ${dst_options}"

    elif [ "$diskName" == "tsa" ]; then
        command="sshfs tsa:/scratch/jcanton/ ${diskDir} ${dst_options}"

    elif [ "$diskName" == "balfrin" ]; then
        command="sshfs balfrin:/scratch/mch/jcanton/ ${diskDir} ${dst_options}"

    elif [ "$diskName" == "squirrel" ]; then
        command="sshfs ${tunnel_options} squirrel:/home/l_jcanton ${diskDir} ${dst_options}"

    elif [ "$diskName" == "squirrelS" ]; then
        command="sshfs ${tunnel_options} squirrel:/scratch/l_jcanton ${diskDir} ${dst_options}"

    elif [ "$diskName" == "co2" ]; then
        command="sshfs ${tunnel_options} fog:/net/co2/exclaim/jcanton ${diskDir} ${dst_options}"

    elif [ "$diskName" == "pi" ]; then
        command="sshfs pi:/home/pi ${diskDir} ${dst_options}"

    elif [ "$diskName" == "ciccia" ]; then
        command="sshfs ciccia:/var/services/homes/jacopo ${diskDir} ${dst_options}"

    else
        echo "Unknown host name"
    fi

    eval $command
    cd "$diskDir" || exit
}
