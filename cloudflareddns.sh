#!/bin/bash
set -e;

ipv4Regex="((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])"

proxy="false"

# DSM Config
username="$1"
password="$2"
hostname="$3"
ipAddr="$4"

if [[ $ipAddr =~ $ipv4Regex ]]; then
    recordType="A";
else
    recordType="AAAA";
fi

listDnsApi="https://api.cloudflare.com/client/v4/zones/${username}/dns_records?type=${recordType}&name=${hostname}"
createDnsApi="https://api.cloudflare.com/client/v4/zones/${username}/dns_records"

res=$(curl -s -X GET "$listDnsApi" -H "Authorization: Bearer $password" -H "Content-Type:application/json")
resSuccess=$(echo "$res" | jq -r ".success")

if [[ $resSuccess != "true" ]]; then
    echo "badauth";
    exit 1;
fi

recordId=$(echo "$res" | jq -r ".result[0].id")
recordIp=$(echo "$res" | jq -r ".result[0].content")

if [[ $recordIp = "$ipAddr" ]]; then
    echo "nochg";
    exit 0;
fi

if [[ $recordId = "null" ]]; then
    # Record not exists
    res=$(curl -s -X POST "$createDnsApi" -H "Authorization: Bearer $password" -H "Content-Type:application/json" --data "{\"type\":\"$recordType\",\"name\":\"$hostname\",\"content\":\"$ipAddr\",\"proxied\":$proxy}")
else
    # Record exists
    updateDnsApi="https://api.cloudflare.com/client/v4/zones/${username}/dns_records/${recordId}";
    res=$(curl -s -X PUT "$updateDnsApi" -H "Authorization: Bearer $password" -H "Content-Type:application/json" --data "{\"type\":\"$recordType\",\"name\":\"$hostname\",\"content\":\"$ipAddr\",\"proxied\":$proxy}")
fi

# Record for wildcard
listDnsApiWild="https://api.cloudflare.com/client/v4/zones/${username}/dns_records?type=${recordType}&name=*.${hostname}"
createDnsApiWild="https://api.cloudflare.com/client/v4/zones/${username}/dns_records"
 
resWild=$(curl -s -X GET "$listDnsApiWild" -H "Authorization: Bearer $password" -H "Content-Type:application/json")
resSuccessWild=$(echo "$resWild" | jq -r ".success")
 
if [[ $resSuccessWild != "true" ]]; then
    echo "badauth";
    exit 1;
fi
recordIdWild=$(echo "$resWild" | jq -r ".result[0].id")
recordIpWild=$(echo "$resWild" | jq -r ".result[0].content")
if [[ $recordIpWild = "$ipAddr" ]]; then
    echo "Wildcard nochg";
    exit 0;
fi
 
if [[ $recordIdWild = "null" && $recordIpWild != "$ipAddr" ]]; then
    # Record not exists
    resWild=$(curl -s -X POST "$createDnsApiWild" -H "Authorization: Bearer $password" -H "Content-Type:application/json" --data "{\"type\":\"$recordType\",\"name\":\"*.$hostname\",\"content\":\"$ipAddr\",\"proxied\":$proxy}")
else
    # Record exists
    updateDnsApiWild="https://api.cloudflare.com/client/v4/zones/${username}/dns_records/${recordIdWild}";
    resWild=$(curl -s -X PUT "$updateDnsApiWild" -H "Authorization: Bearer $password" -H "Content-Type:application/json" --data "{\"type\":\"$recordType\",\"name\":\"*.$hostname\",\"content\":\"$ipAddr\",\"proxied\":$proxy}")
fi
 
# echo "recordIdWild: "$recordIdWild
# echo "recordIpWild: "$recordIpWild
#echo "updateDnsApiWild: "$updateDnsApiWild
 
resSuccess=$(echo "$res" | jq -r ".success")
resWildSuccess=$(echo "$resWild" | jq -r ".success")
 
if [[ $resSuccess = "true" && $resWildSuccess = "true" ]]; then
    echo "good";
else
    echo "badauth";
fi
 