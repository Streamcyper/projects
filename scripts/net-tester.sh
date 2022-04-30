#! /bin/bash
TRY=0
APIKEYFILE=/opt/scripts/api.key
LOGFILE=/opt/scripts/net-tester.log

logmessage(){
    message=$1
    echo [ `date "+%y-%m-%d - %H:%M"` ] "$message" >> $LOGFILE
    tail -288 $LOGFILE | sponge $LOGFILE
}

have_connection(){
    ping -c 1 dns.cloudflare.com
    return $?
}

restart_vpnservice(){
    systemctl restart openvpn@norway.service
}

restart_radarr(){
    apikey=`cat $APIKEYFILE`
    curl -X POST "http://localhost:7878/api/v3/indexer/testall" -H  "accept: */*" -H  "X-Api-Key: $apikey" -d ""
}

if have_connection 
then
    logmessage "Everythings seems alright"
    exit 0
else
    logmessage "It's fucked, trying to fix it... Hold on"
    while ! have_connection && (( $TRY < 5 ))
    do
        TRY=$((TRY++))
        logmessage "Trying $TRY"
        restart_vpnservice
        sleeptime=$(( TRY * 10 ))
        sleep $sleeptime
    done
    if have_connection 
    then
        logmessage "Got it working!"
    elif [ $TRY -eq 5 ]
    then
        logmessage "It's not working trying to restart"
        shutdown -r now
        sleep 90
        exit 3
    fi
    restart_radarr
    exit 2
fi
