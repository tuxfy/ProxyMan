#!/bin/bash
# plugin to set "dnf" proxy settings for ProxyMan
# privileges has to be set by the process which starts this script

CONF_FILE="/home/${USER}/.config/Code/User/settings.json"


restart_vscode() {
    if [ ! -e "$CONF_FILE" ]; then
        return
    fi

    echo "restarting vscode"
    killall -e code
    code </dev/null &>/dev/null &
    echo "done"    
}


list_proxy() {
    if [ ! -e "$CONF_FILE" ]; then
        return
    fi

    echo
    echo -e "${bold}vscode proxy settings: ${normal}"
    lines="$(cat $CONF_FILE | grep proxy -i | wc -l)"
    if [ "$lines" -gt 0 ]; then
        cat $CONF_FILE | grep proxy -i
    else
        echo -e "${red}None${normal}"
    fi
}

unset_proxy() {    
    if [ ! -e "$CONF_FILE" ]; then
        return
    fi
    
    LINESTART=$(grep -n "proxy" ${CONF_FILE} | grep -Eo '^[^:]+')
    if [ -z "$LINESTART" ]; then
        return
    fi

    for PROTOTYPE in "proxyStrictSSL" "proxy"; do
        sed -i "/${PROTOTYPE}/Id" "$CONF_FILE"
    done
}

set_proxy() {
    if [ ! -e "$CONF_FILE" ]; then
        return
    fi

    local stmt=""
    if [ "$use_auth" = "y" ]; then
        stmt="${username}:${password}@"
    fi

    sed -i '$ i\"http.proxyStrictSSL":false,' $CONF_FILE
    sed -i '$ i\"http.proxy":"http://'${stmt}${https_host}':'${https_port}'"' $CONF_FILE  
    return
}


what_to_do=$1
case $what_to_do in
    set) set_proxy
         restart_vscode
         ;;
    unset) unset_proxy
           restart_vscode
           ;;
    list) list_proxy
          ;;
    *)
          ;;
esac
