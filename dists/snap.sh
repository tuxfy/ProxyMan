#!/bin/bash
# plugin to set "dnf" proxy settings for ProxyMan
# privileges has to be set by the process which starts this script

CONF_FILE="/etc/systemd/system/snap.service.d/snap_proxy.conf"


reload_snap_service() {
    echo "reloading snap"
    systemctl daemon-reload
    systemctl restart snapd.service
    echo "done"
}


list_proxy() {
    # inefficient way as the file is read twice.. think of some better way
    echo
    echo -e "${bold}snap proxy settings: ${normal}"

    echo -e "snap system proxy.http(s):"
    echo "$(sudo snap get core proxy)"
    echo -e ""
    echo -e "$CONF_FILE"

    if [ ! -e "$CONF_FILE" ]; then
        echo -e "${red}None${normal}"
        return
    else
        lines="$(cat $CONF_FILE | grep proxy -i | wc -l)"
        if [ "$lines" -gt 0 ]; then
            cat $CONF_FILE | grep proxy -i | sed -e "s/Environment=//g" -e "s/\_/\ /g"
        else
            echo -e "${red}None${normal}"
        fi
    fi
}

unset_proxy() {
    snap unset system proxy.http
    snap unset system proxy.https

    if [ ! -e "$CONF_FILE" ]; then
        return
    fi
    for PROTOTYPE in "HTTP" "HTTPS" "FTP" "RSYNC" "NO"; do
        sed -i "/${PROTOTYPE}_PROXY\=/d" "$CONF_FILE"
    done
}

set_proxy() {
    unset_proxy

    local stmt=""
    if [ "$use_auth" = "y" ]; then
        stmt="${username}:${password}@"
    fi

    snap set system proxy.http="http://${stmt}${http_host}:${http_port}"
    if [ "$USE_HTTP_PROXY_FOR_HTTPS" = "true" ]; then
        snap set system proxy.https="http://${stmt}${http_host}:${http_port}"
    else
        snap set system proxy.https="https://${stmt}${https_host}:${http_port}"
    fi 

    mkdir -p /etc/systemd/system/snap.service.d
    if [ ! -e "$CONF_FILE" ]; then
        touch "$CONF_FILE"
        echo "[Service]" >> $CONF_FILE
    fi
    

    echo 'Environment="HTTP_PROXY=http://'${stmt}${http_host}:${http_port}'/"'\
        >> $CONF_FILE
    if [ "$USE_HTTP_PROXY_FOR_HTTPS" = "true" ]; then
        echo 'Environment="HTTPS_PROXY=http://'${stmt}${https_host}:${https_port}'/"'\
            >> $CONF_FILE
    else
        echo 'Environment="HTTPS_PROXY=https://'${stmt}${https_host}:${https_port}'/"'\
            >> $CONF_FILE
    fi
    echo 'Environment="NO_PROXY='${no_proxy}'"'\
        >> $CONF_FILE

    return
}


which snap &> /dev/null
if [ "$?" != 0 ]; then
    exit
fi

if [ "$#" = 0 ]; then
    exit
fi

what_to_do=$1
case $what_to_do in
    set) set_proxy
         reload_snap_service
         ;;
    unset) unset_proxy
           reload_snap_service
           ;;
    list) list_proxy
          ;;
    *)
          ;;
esac
