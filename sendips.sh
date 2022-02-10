#!/bin/bash
# " /bin/sh /Shared/nginx/shtail.sh & " needs to be added to /startapp.sh as the second line
# for ipv6 and ipv4 grep -E -o "(([0-9]{1,3}[\.]){3}[0-9]{1,3}|([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))" file.txt
# for ipv6 and ipv4 exluding homeips grep -E -o "(([0-9]{1,3}[\.]){3}[0-9]{1,3}|([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))" | grep -v "192.168.0.*\| 69.0.0.* \| 5.0.0.*" file.txt 
# for domains grep -E -o "[a-z0-9]*\.[a-z0-9]*\.(de|net|org|com)" file.txt #working for domains

# Check if jq is installed and executable, if not install it and set as executable.  This allows us to parse the json logs
if [[ -x "/usr/bin/jq" ]]
then
    echo "jq available"
else
    echo "jq is not executable or found, installing"
    curl -L -o /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
    chmod +x /usr/bin/jq
fi

# Tail the custom log location to allow json parsing of the custom logs
tail -f /logs/*-json.log | while read line;

do
  #get requested domain from json log and remove the leading and trailing quotes
  domain=`echo $line | jq '.http_host'  | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
  #get requesting IP from json log and remove the leading and trailing quotes
  ipaddressnumber= `echo $line | jq '.remote_addr'  | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
  #get actual time the request was made from json log and remove the leading and trailing quotes
  reqtime=`echo $line | jq '.time_iso8601' | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
  
  #Print on screen captured values
  echo $reqtime
  echo $ipaddressnumber
  echo $domain
  
  #Get public IP4 and IP6 addresses, so we can avoid sending IPs from our own connection
  myhomeIP4=$(wget -qO- https://ipv4.icanhazip.com/)
  myhomeIP6=$(wget -qO- https://ipv6.icanhazip.com/)
  
   if [[ "$ipaddressnumber" == "$myhomeIP4" ]]
  then
    echo "Home IP4"
  elif [[ "$ipaddressnumber" == "$myhomeIP6" ]]
  then
    echo "Home IP6"
  #LanIP is used to not send your home network ips to keep the number of sends down, edit this to represent your subnet BUT DO NOT REMOVE THE "^" at the start as this represents "starts with" in the regex  
  elif [[ "$ipaddressnumber" =~ ^192.168.0.* ]]
  then
    echo "LAN IP"
  elif [[ -z "$ipaddressnumber" ]]
  then
    echo "IP null"
  else
    python /root/.config/NPMGRAF/Getipinfo.py "$ipaddressnumber" "$domain" "$reqtime"
  fi
done
reboot
