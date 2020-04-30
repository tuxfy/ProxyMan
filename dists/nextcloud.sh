#!/bin/bash
# plugin to set "dnf" proxy settings for ProxyMan
# privileges has to be set by the process which starts this script

CONF_FILE="/home/${USER}/.config/Nextcloud/nextcloud.cfg"


restart_nextcloud() {
    if [ ! -e "$CONF_FILE" ]; then
        return
    fi

    echo "restarting nextcloud"
    killall nextcloud
    nextcloud </dev/null &>/dev/null &
    echo "done"    
}


list_proxy() {
    if [ ! -e "$CONF_FILE" ]; then
        return
    fi

    echo
    echo -e "${bold}nextcloud proxy settings: ${normal}"
    
    while read line; do 
    if [[ $line =~ ^"["(.+)"]"$ ]]; then 
        arrname=${BASH_REMATCH[1]}
        declare -A $arrname
    elif [[ $line =~ ^([_[:alpha:]][_[:alnum:]]*)"="(.*) ]]; then 
        declare ${arrname}[${BASH_REMATCH[1]}]="${BASH_REMATCH[2]}"
    fi
    done < ${CONF_FILE}

    echo "proxy=${Proxy[host]}"
    echo "port=${Proxy[post]}"
    echo "type=${Proxy[type]}"
}

unset_proxy() {    
    if [ ! -e "$CONF_FILE" ]; then
        return
    fi
    
    LINESTART=$(grep -n "Proxy" ${CONF_FILE} | grep -Eo '^[^:]+')
    if [ -z "$LINESTART" ]; then
        return
    fi

    LINESTART=$((LINESTART - 1))
    LINEEND=$((LINESTART + 8))
    sed -i "${LINESTART},${LINEEND}d" ${CONF_FILE}
    sed -i '/^$/d' ${CONF_FILE}
}

set_proxy() {
    if [ ! -e "$CONF_FILE" ]; then
        return
    fi

    echo -e "${bold}setting nextcloud proxy ${normal}"
    unset_proxy
    echo ''\
        >> $CONF_FILE
    echo ''\
        >> $CONF_FILE
    echo '[Proxy]'\
        >> $CONF_FILE
    echo 'host='${http_host}''\
        >> $CONF_FILE
    echo 'port='${http_port}''\
        >> $CONF_FILE
    echo 'type=3'\
        >> $CONF_FILE
    return
}


what_to_do=$1
case $what_to_do in
    set) set_proxy
         restart_nextcloud
         ;;
    unset) unset_proxy
           restart_nextcloud
           ;;
    list) list_proxy
          ;;
    *)
          ;;
esac
