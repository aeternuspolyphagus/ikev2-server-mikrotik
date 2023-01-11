# jan/10/2023 15:44:31 by RouterOS 7.7rc4
# software id = 7J1Y-V6AK
#
/system script
add comment="IKEv2 setup scripts" dont-require-permissions=no name=\
    Setup-server owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    local DNSaddress\r\
    \n:local IPaddress\r\
    \n:local answer\r\
    \n:put \"You have Domain name\?\\r\\nIf have you have press y.\\r\\nElse p\
    ress any key.\"\r\
    \n:local read do={:return}\r\
    \n:set \$answer [\$read]\r\
    \n\r\
    \n:do {\r\
    \n\r\
    \n    :if (\$answer = \"y\") do {\r\
    \n\r\
    \n        :put \"Enter your Domain name.\"\r\
    \n        :local read do={:return}\r\
    \n        :set \$DNSaddress [\$read]\r\
    \n        :put \$DNSaddress\r\
    \n\r\
    \n    } else {\r\
    \n\r\
    \n        :if ([/ip cloud get value-name=ddns-enabled] = \"\") do {\r\
    \n\r\
    \n            /ip cloud set ddns-enabled=yes\r\
    \n            :delay 10s\r\
    \n            :set \$DNSaddress [/ip cloud get value-name=dns-name]\r\
    \n\r\
    \n        } else {\r\
    \n\r\
    \n            :set \$DNSaddress [/ip cloud get value-name=dns-name]\r\
    \n\r\
    \n        }\r\
    \n\r\
    \n    }\r\
    \n    \r\
    \n    :local IP\r\
    \n    :put \"Enter your real ip.\\r\\nFor auto-ident press 0.\"\r\
    \n    :local read do={:return}\r\
    \n    :set \$IP [\$read]\r\
    \n\r\
    \n    :if (\$IP = 0) do {\r\
    \n\r\
    \n        /tool fetch url=\"https://v4.ident.me/\" dst-path=myIPv4.txt\r\
    \n        :delay 1s\r\
    \n        :set \$IPaddress [/file get myIPv4.txt contents]\r\
    \n        :put \"\$IPaddress It's your address\?\"\r\
    \n        /file remove myIPv4.txt\r\
    \n\r\
    \n    } else {\r\
    \n\r\
    \n        :set \$IPaddress [\$IP]\r\
    \n        :put \"\$IPaddress It's your address\?\"\r\
    \n\r\
    \n    }\r\
    \n\r\
    \n    :put \$DNSaddress\r\
    \n    :put \$IPaddress\r\
    \n\r\
    \n    :put \"Do you want create certificate bundle\? Like CA, Server certi\
    ficate and temp client certificate\?\\r\\nPress y if you want or press any\
    \_key.\"\r\
    \n\r\
    \n    :local read do={:return}\r\
    \n    :set \$answer [\$read]\r\
    \n    \r\
    \n    :if (\$answer = \"y\") do {\r\
    \n\r\
    \n        :put \"Enter country:\"\r\
    \n        :local read do={:return}\r\
    \n        :set \$country [\$read]\r\
    \n        :put \"Enter state:\"\r\
    \n        :local read do={:return}\r\
    \n        :set \$state [\$read]\r\
    \n        :put \"Enter city:\"\r\
    \n        :local read do={:return}\r\
    \n        :set \$city [\$read]\r\
    \n        :put \"Generate CA-certificate.\"\r\
    \n        /certificate add name=\"ca.\$DNSaddress\" country=\"\$country\" \
    state=\"\$state\" locality=\"\$city\" organization=\"\$DNSaddress\" common\
    -name=\"ca.\$DNSaddress\"  subject-alt-name=\"DNS:ca.\$DNSaddress\" key-si\
    ze=4096 days-valid=3650 trusted=yes key-usage=digital-signature,key-enciph\
    erment,data-encipherment,key-cert-sign,crl-sign\r\
    \n        /certificate sign \"ca.\$DNSaddress\"\r\
    \n        :put \"Generate IKE2-Server certificate.\"\r\
    \n        /certificate add name=\"\$DNSaddress\" country=\"\$country\" sta\
    te=\"\$state\" locality=\"\$city\" organization=\"\$DNSaddress\" common-na\
    me=\"\$DNSaddress\" subject-alt-name=\"DNS:\$DNSaddress\" key-size=2048 da\
    ys-valid=1095 trusted=yes key-usage=tls-server\r\
    \n        /certificate sign \"\$DNSaddress\" ca=\"ca.\$DNSaddress\"\r\
    \n        :put \"Generate Client-template.\"\r\
    \n        /certificate add name=\"~client-template@\$DNSaddress\" country=\
    \"\$country\" state=\"\$state\" locality=\"\$city\" organization=\"\$DNSad\
    dress\" common-name=\"~client-template@\$DNSaddress\"    subject-alt-name=\
    \"email:~client-template@\$DNSaddress\" key-size=2048 days-valid=365 trust\
    ed=yes key-usage=tls-client\r\
    \n\r\
    \n    }\r\
    \n\r\
    \n\r\
    \n        :put \"Create LoopBack-bridge.\"\r\
    \n        /interface bridge add name=\"LoopBack\" comment=\$DNSaddress\r\
    \n        :put \"Enter ip address for bridge.\"\r\
    \n        :local IPBR\r\
    \n        :local read do={:return}\r\
    \n        :set \$IPBR [\$read]\r\
    \n        /ip address add address=([\$IPBR]. \"/24\") interface=LoopBack c\
    omment=\$DNSaddress\r\
    \n        :local dstlen [len [ /ip address get value-name=network [ find where interface=LoopBack ] ]]\r\
    \n        :local dirtypool [:pick [ /ip address get value-name=network [ find where interface=LoopBack ] ] 0 (\$dstlen -1) ] \r\
    \n        :put \"Enter start fourth octet for ip-pool for Ipsec-client. Like 10/100/200 and etc\"\r\
    \n        :local poolstart\r\
    \n        :local read do=[:return]\r\
    \n        :set poolstart [\$read]\r\
    \n        :put \"Enter count of ips for pool.\"\r\
    \n        :local poolcount\r\
    \n        :local read do=[:return]\r\
    \n        :set poolcount [\$read]\r\
    \n        :local pool [\"\$dirtypool\" . \"\$poolstart\" . \"-\" . \"\$dirtypool\" . (\$poolstart + \$poolcount)]\r\
    \n        /ip pool add name=\"pool \$DNSaddress\" ranges=\$pool comment=\$DNSaddress\r\
    \n        :put \"You want route for specified network or any\? Enter speci\
    fied networks like x.x.x.x/x,y.y.y.y/y or press 0.\"\r\
    \n        :local split\r\
    \n        :local read do=[:return]\r\
    \n        :set \$split [\$read]\r\
    \n\r\
    \n        :if (\$split != 0) do {\r\
    \n\r\
    \n            :put \"Generate IpSec configurations.\"\r\
    \n            /ip ipsec mode-config add address-pool=\"pool \$DNSaddress\"\
    \_address-prefix-length=32 name=\"\$DNSaddress\" split-include=\$split sta\
    tic-dns=\$IPBR system-dns=no            \r\
    \n\r\
    \n        } else {\r\
    \n\r\
    \n            :put \"Generate IpSec configurations.\"\r\
    \n            /ip ipsec mode-config add address-pool=\"pool \$DNSaddress\"\
    \_address-prefix-length=32 name=\"\$DNSaddress\" split-include=0.0.0.0/0 s\
    tatic-dns=\$IPBR system-dns=no\r\
    \n\r\
    \n        }\r\
    \n\r\
    \n        /ip ipsec profile add dh-group=modp2048,modp1536,modp1024 enc-al\
    gorithm=aes-256,aes-192,aes-128 hash-algorithm=sha256 name=\"\$DNSaddress\
    \" nat-traversal=yes  proposal-check=obey \r\
    \n        /ip ipsec peer add exchange-mode=ike2 address=0.0.0.0/0 local-ad\
    dress=\"\$IPaddress\" name=\"peer \$IPaddress\" passive=yes send-initial-c\
    ontact=yes profile=\"\$DNSaddress\" comment=\$DNSaddress\r\
    \n        /ip ipsec proposal add auth-algorithms=sha512,sha256,sha1 enc-al\
    gorithms=aes-256-cbc,aes-256-ctr,aes-256-gcm,aes-192-ctr,aes-192-gcm,aes-1\
    28-cbc,aes-128-ctr,aes-128-gcm lifetime=8h name=\"\$DNSaddress\" pfs-group\
    =none\r\
    \n        /ip ipsec policy group add name=\"\$DNSaddress\"\r\
    \n        :local dst [ /ip address get value-name=network [ find where int\
    erface=LoopBack ] ]\r\
    \n        /ip ipsec policy add dst-address=(\$dst . \"/24\") group=\"\$DNS\
    address\" proposal=\"\$DNSaddress\" src-address=0.0.0.0/0 template=yes com\
    ment=\$DNSaddress\r\
    \n\r\
    \n    :put \"Do you want generate firewall rules\? Enter y or press any ke\
    y\"\r\
    \n    :local read do=[:return]\r\
    \n    :set \$answer [\$read]\r\
    \n    \r\
    \n    :if (\$answer = \"y\") do {\r\
    \n\r\
    \n        :put \"Generate firewall rules.\"\r\
    \n        \r\
    \n        :if ([/ip firewall mangle find ipsec-policy=\"out,ipsec\"] = \"\
    \") do {\r\
    \n            \r\
    \n            /ip firewall mangle add action=mark-connection chain=output \
    comment=\"mark ipsec connections\" ipsec-policy=out,ipsec new-connection-m\
    ark=ipsec passthrough=yes\r\
    \n        \r\
    \n        }\r\
    \n        \r\
    \n        :if ([/ip firewall mangle find ipsec-policy=\"in,ipsec\"] = \"\"\
    ) do {\r\
    \n        \r\
    \n            /ip firewall mangle add action=mark-connection chain=input c\
    omment=\"mark ipsec connections\" ipsec-policy=in,ipsec new-connection-mar\
    k=ipsec passthrough=yes\r\
    \n        \r\
    \n        }\r\
    \n        \r\
    \n        :if ([/ip firewall mangle find new-mss=\"1360\"] = \"\") do {\r\
    \n        \r\
    \n            /ip firewall mangle add action=change-mss chain=forward ipse\
    c-policy=in,ipsec new-mss=1360 passthrough=yes protocol=tcp src-address=(\
    \$dst . \"/24\") tcp-flags=syn tcp-mss=!0-1360\r\
    \n            /ip firewall mangle add action=change-mss chain=forward dst-\
    address=(\$dst . \"/24\") ipsec-policy=out,ipsec new-mss=1360 passthrough=\
    yes protocol=tcp tcp-flags=syn tcp-mss=!0-1360\r\
    \n        \r\
    \n        }\r\
    \n        \r\
    \n        :if ([/ip firewall nat find src-address=(\$dst . \"/24\")] = \"\
    \") do {\r\
    \n        \r\
    \n            /ip firewall nat add action=src-nat chain=srcnat ipsec-polic\
    y=out,none src-address=(\$dst . \"/24\") to-addresses=\$IPaddress\r\
    \n        \r\
    \n        }\r\
    \n        \r\
    \n        :if ([/ip firewall filter find port=\"4500\"] = \"\") do {\r\
    \n        \r\
    \n            :if ([/ip firewall filter find port=\"500\"] = \"\") do {\r\
    \n        \r\
    \n                :if ([/ip firewall filter find port=\"500,4500\"] = \"\"\
    ) do {\r\
    \n        \r\
    \n                    /ip firewall filter add action=accept chain=input ds\
    t-address=\$IPaddress port=500,4500 protocol=udp \r\
    \n                    :put \"Firewall filter rules for ports 500,4500 crea\
    ted.\"\r\
    \n        \r\
    \n                } else {\r\
    \n        \r\
    \n                    :put \"Firewall filter rules for ports 500, 4500 exi\
    st. Skip\"\r\
    \n        \r\
    \n                }\r\
    \n        \r\
    \n            } else {\r\
    \n        \r\
    \n                /ip firewall filter add action=accept chain=input dst-ad\
    dress=\$IPaddress port=4500 protocol=udp \r\
    \n                :put \"Firewall filter rules for port 500 exist, but for\
    \_port 4500 not. Created\"\r\
    \n        \r\
    \n            }\r\
    \n        \r\
    \n        } else {\r\
    \n        \r\
    \n            :if ([/ip firewall filter find port=\"500\"] = \"\") do {\r\
    \n        \r\
    \n                /ip firewall filter add action=accept chain=input dst-ad\
    dress=\$IPaddress port=500 protocol=udp \r\
    \n                :put \"Firewall filter rules for port 4500 exist, but fo\
    r port 500 not. Created\"\r\
    \n        \r\
    \n            } else {\r\
    \n        \r\
    \n                :put \"Firewall filter rules for ports 500, 4500 exist. \
    Skip\"\r\
    \n        \r\
    \n            }\r\
    \n        \r\
    \n        }\r\
    \n        \r\
    \n        :if ([/ip firewall filter find where protocol=\"ipsec-esp\"] = \
    \"\") do {\r\
    \n        \r\
    \n            /ip firewall filter add action=accept chain=input dst-addres\
    s=\$IPaddress protocol=ipsec-esp \r\
    \n            :put \"Firewall filter rule for protocol IPSec-ESP created.\
    \"\r\
    \n        \r\
    \n        } else {\r\
    \n        \r\
    \n            :put \"Firewall filter rule for protocol IPSec-ESP exist. Sk\
    ip.\"\r\
    \n        \r\
    \n        }\r\
    \n        \r\
    \n        :if ([/ip firewall filter find ipsec-policy=\"in,ipsec\" src-add\
    ress=(\$dst . \"/24\") chain=input] = \"\") do {\r\
    \n        \r\
    \n            /ip firewall filter add action=accept chain=input ipsec-poli\
    cy=in,ipsec src-address=(\$dst . \"/24\") \r\
    \n            :put \"Firewall filter rule for allow access from IKE2 clien\
    ts to router created.\"\r\
    \n        \r\
    \n        } else {\r\
    \n        \r\
    \n            :put \"Firewall filter rule for allow access from IKE2 clien\
    ts to router exist. Skip.\"\r\
    \n        \r\
    \n        }\r\
    \n        \r\
    \n        :if ([/ip firewall filter find ipsec-policy=\"in,ipsec\" chain=f\
    orward] = \"\") do {\r\
    \n            /ip firewall filter add action=accept chain=forward ipsec-po\
    licy=in,ipsec \r\
    \n            :put \"Firewall filter rule forward from IKE2 clients create\
    d.\"\r\
    \n        \r\
    \n        } else {\r\
    \n        \r\
    \n            :put \"Firewall filter rule forward from IKE2 clients exist.\
    \_Skip\"\r\
    \n        \r\
    \n        }\r\
    \n        \r\
    \n        :if ([/ip firewall filter find ipsec-policy=\"in,ipsec\" src-add\
    ress=(\$dst . \"/24\") dst-address=\"0.0.0.0/0\" chain=forward] = \"\") do\
    \_{\r\
    \n        \r\
    \n            /ip firewall filter add action=accept chain=forward dst-addr\
    ess=0.0.0.0/0 ipsec-policy=in,ipsec src-address=(\$dst . \"/24\") \r\
    \n            :put \"Firewall filter rule forward from IKE2 clients create\
    d to any.\"\r\
    \n        \r\
    \n        } else {\r\
    \n        \r\
    \n            :put \"Firewall filter rule forward from IKE2 clients exist \
    to any. Skip\"\r\
    \n        \r\
    \n        }\r\
    \n        \r\
    \n        :if ([/ip firewall filter find ipsec-policy=\"out,ipsec\" chain=\
    forward] = \"\") do {\r\
    \n        \r\
    \n            /ip firewall filter add action=accept chain=forward ipsec-po\
    licy=out,ipsec \r\
    \n            :put \"Firewall filter rule forward out IKE2 clients created\
    .\"\r\
    \n        \r\
    \n        } else {\r\
    \n        \r\
    \n            :put \"Firewall filter rule forward out IKE2 clients exist. \
    Skip\"\r\
    \n        \r\
    \n        }\r\
    \n        \r\
    \n        :if ([/ip firewall filter find action=fasttrack-connection chain\
    =forward connection-state=\"established,related\"] = \"\") do {\r\
    \n        \r\
    \n            /ip firewall filter add action=fasttrack-connection chain=fo\
    rward connection-mark=!ipsec connection-state=established,related \r\
    \n            :put \"Firewall filter rule for fasttrack created.\"\r\
    \n        \r\
    \n            :if ([/ip firewall filter find chain=forward connection-stat\
    e=\"established,related,untracked\"] = \"\") do {\r\
    \n        \r\
    \n                /ip firewall filter add action=accept chain=forward conn\
    ection-state=established,related,untracked \r\
    \n                :put \"Firewall filter rule for established, related, un\
    tracked connection created. \"\r\
    \n        \r\
    \n            } else {\r\
    \n        \r\
    \n                :put \"Firewall filter rule for established, related, un\
    tracked connection exist. Skip.\"\r\
    \n        \r\
    \n            }\r\
    \n        \r\
    \n        } else {\r\
    \n        \r\
    \n            :if ([/ip firewall filter find action=fasttrack-connection c\
    hain=forward connection-state=\"established,related\" connection-mark=\"!i\
    psec\"] = \"\") do {\r\
    \n        \r\
    \n                /ip firewall filter set [find action=fasttrack-connectio\
    n] connection-mark=!ipsec\r\
    \n                :put \"Modificate fasttrack filter rule for correct work\
    \_with ipsec.\"\r\
    \n        \r\
    \n                :if ([/ip firewall filter find chain=forward connection-\
    state=\"established,related,untracked\"] = \"\") do {\r\
    \n        \r\
    \n                    /ip firewall filter add action=accept chain=forward \
    connection-state=established,related,untracked \r\
    \n                    :put \"Firewall filter rule for established, related\
    , untracked connection created. \"\r\
    \n        \r\
    \n                } else {\r\
    \n        \r\
    \n                :put \"Firewall filter rule for established, related, un\
    tracked connection exist. Skip.\"\r\
    \n        \r\
    \n                }\r\
    \n        \r\
    \n            } else {\r\
    \n        \r\
    \n                :put \"Correct fasttrack filter rule for correct work wi\
    th ipsec exist. Skip.\"\r\
    \n        \r\
    \n                :if ([/ip firewall filter find chain=forward connection-\
    state=\"established,related,untracked\"] = \"\") do {\r\
    \n        \r\
    \n                    /ip firewall filter add action=accept chain=forward \
    connection-state=established,related,untracked \r\
    \n                    :put \"Firewall filter rule for established, related\
    , untracked connection created. \"\r\
    \n        \r\
    \n                } else {\r\
    \n        \r\
    \n                :put \"Firewall filter rule for established, related, un\
    tracked connection exist. Skip.\"\r\
    \n        \r\
    \n                }\r\
    \n            }\r\
    \n        }\r\
    \n    }\r\
    \n}"
add comment="IKEv2 setup scripts" dont-require-permissions=no name=\
    ikev2-setup owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    local WhatYouWant\r\
    \n\r\
    \n:put \"What you want\?\"\r\
    \n:put \"1: Create server\"\r\
    \n:put \"2: Remove server\"\r\
    \n:put \"3: Create client\"\r\
    \n:put \"4: Remove client\"\r\
    \n\r\
    \n:local read do={:return}\r\
    \n:set WhatYouWant [\$read]\r\
    \n:put \$WhatYouWant\r\
    \n\r\
    \ndo {\r\
    \n    :if (\$WhatYouWant = 1) do {\r\
    \n\r\
    \n        system script run Setup-server\r\
    \n    \r\
    \n    }\r\
    \n    \r\
    \n    :if (\$WhatYouWant = 2) do {\r\
    \n\r\
    \n        system script run Remove-server\r\
    \n\r\
    \n    }\r\
    \n    \r\
    \n    :if (\$WhatYouWant = 3) do {\r\
    \n        \r\
    \n        system script run Setup-client\r\
    \n\r\
    \n    }\r\
    \n    \r\
    \n    :if (\$WhatYouWant = 4) do {\r\
    \n\r\
    \n        system script run Remove-client\r\
    \n        \r\
    \n    }\r\
    \n}"
add comment="IKEv2 setup scripts" dont-require-permissions=no name=\
    Remove-server owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    local peerconf [/ip ipsec peer find where exchange-mode=ike2]\r\
    \n:local IPaddress\r\
    \n:local DNSaddress\r\
    \n\r\
    \n:if (\$peerconf = \"\") do {\r\
    \n\r\
    \n    :put \"I can't found any ipsec configuration. Before run this script\
    \_you must run script Setup-server.\"\r\
    \n\r\
    \n} else {\r\
    \n\r\
    \n    :do {/ip ipsec peer print detail value-list}\r\
    \n    /ip ipsec peer print where exchange-mode=ike2\r\
    \n    :put \"I found next ipsec peer. Enter his number for remove configur\
    ation.\"\r\
    \n    :local read do={:return}\r\
    \n    :set \$foundpeer [\$read]\r\
    \n    :set \$DNSaddress [/ip ipsec peer get value-name=comment number=\$fo\
    undpeer]\r\
    \n    :set \$IPaddress [/ip ipsec peer get value-name=local-address  numbe\
    r=\$foundpeer]\r\
    \n    :put \$IPaddress\r\
    \n    :put \$DNSaddress\r\
    \n\r\
    \n}\r\
    \n\r\
    \n:put \"Remove client-identity\"\r\
    \n\r\
    \n/ip ipsec identity remove [find where comment=\"\$DNSaddress\"]\r\
    \n\r\
    \n:put \"Remove IPSec peer\"\r\
    \n\r\
    \n/ip ipsec peer remove [find where comment=\"\$DNSaddress\"]\r\
    \n\r\
    \n:put \"Remove modeconf\"\r\
    \n\r\
    \n/ip ipsec mode-config remove [find where name=\"\$DNSaddress\"]\r\
    \n\r\
    \n:put \"Remove IPSec policy\"\r\
    \n\r\
    \n/ip ipsec policy remove [find where comment=\"\$DNSaddress\"]\r\
    \n\r\
    \n:put \"Remove IPSec profile\"\r\
    \n\r\
    \n/ip ipsec profile remove [find where name=\"\$DNSaddress\"]\r\
    \n\r\
    \n:put \"Remove proposal\"\r\
    \n\r\
    \n/ip ipsec proposal remove [find where name=\"\$DNSaddress\"]\r\
    \n\r\
    \n:put \"Remove group\"\r\
    \n\r\
    \n/ip ipsec policy group remove [find where name=\"\$DNSaddress\"]\r\
    \n\r\
    \n:put \"Remove bridge address\"\r\
    \n\r\
    \n/ip address remove [find where comment=\"\$DNSaddress\"]\r\
    \n\r\
    \n:put \"Remove LoopBack bridge\"\r\
    \n\r\
    \n/interface bridge remove [find where comment=\"\$DNSaddress\"]\r\
    \n\r\
    \n:put \"Remove IP-pool\"\r\
    \n\r\
    \n/ip pool remove [find where comment=\"\$DNSaddress\"]"
add comment="IKEv2 setup scripts" dont-require-permissions=no name=\
    Remove-client owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    do {/ip ipsec peer print detail value-list}\r\
    \n/ip ipsec peer print where exchange-mode=ike2\r\
    \n:put \"I found next ipsec peer. Enter his number for remove client confi\
    guration.\"\r\
    \n:local read do={:return}\r\
    \n:set \$foundpeer [\$read]\r\
    \n:local peername [/ip ipsec peer get value-name=name number=\$foundpeer]\
    \r\
    \n:do {/ip ipsec identity print value-list}\r\
    \n/ip ipsec identity print where peer=\$peername\r\
    \n:put \"Choose client number.\"\r\
    \n:local read do={:return}\r\
    \n:local clientid [\$read]\r\
    \n:put \"Do you want to remove the client or disable it\? Choose 1 for dis\
    able or 2 for delete.\"\r\
    \n:local read do={:return}\r\
    \n:local answer [\$read]\r\
    \n\r\
    \n:if (\$answer = 1) do {\r\
    \n\r\
    \n    /ip ipsec identity disable numbers=\$clientid\r\
    \n\r\
    \n}\r\
    \n\r\
    \n:if (\$answer = 2) do {\r\
    \n\r\
    \n    /ip ipsec identity remove numbers=\$clientid\r\
    \n    \r\
    \n}"
add comment="IKEv2 setup scripts" dont-require-permissions=no name=\
    Setup-client owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":\
    local newClient\r\
    \n:local Password\r\
    \n\r\
    \n:local peerconf [/ip ipsec peer find where exchange-mode=ike2]\r\
    \n\r\
    \n:if (\$peerconf = \"\") do {\r\
    \n\r\
    \n    :put \"I can't found any ipsec configuration. Before run this script\
    \_you must run script Setup-server.\"\r\
    \n\r\
    \n} else {\r\
    \n\r\
    \n    :do {/ip ipsec peer print detail value-list}\r\
    \n    /ip ipsec peer print where exchange-mode=ike2\r\
    \n    :put \"I found next ipsec peer. Enter his number for create client c\
    onfiguration.\"\r\
    \n    :local read do={:return}\r\
    \n    :set \$foundpeer [\$read]\r\
    \n    :local DNSaddress [/ip ipsec peer get value-name=comment number=\$fo\
    undpeer]\r\
    \n    :local IPaddress [/ip ipsec peer get value-name=local-address number\
    =\$foundpeer]\r\
    \n    :put \$IPaddress\r\
    \n    :put \$DNSaddress\r\
    \n    :put \"Insert username\"\r\
    \n    :local readuser do={:return}\r\
    \n    :set \$newClient [\$readuser]\r\
    \n    :put \$newClient\r\
    \n    :put \"Insert password\"\r\
    \n    :local readpass do={:return}\r\
    \n    :set \$Password [\$readpass]\r\
    \n    :put \$Password\r\
    \n    :put \" ============== Starting script ============== \"\r\
    \n    :put \" ======== Creating client certificate from template ======== \
    \"\r\
    \n        \r\
    \n    :do {\r\
    \n            \r\
    \n        /certificate \r\
    \n        add copy-from=\"~client-template@\$DNSaddress\" name=\"\$newClie\
    nt@\$DNSaddress\" common-name=\"\$newClient@\$DNSaddress\" subject-alt-nam\
    e=\"email:\$newClient@\$DNSaddress\";\r\
    \n\r\
    \n    :put \" ======== Signing first client certificate with ca.\$DNSaddre\
    ss ======== \";\r\
    \n        /certificate sign \"\$newClient@\$DNSaddress\" ca=\"ca.\$DNSaddr\
    ess\";\r\
    \n\r\
    \n        :put \" ======== Exporting first client certificate + private ke\
    y into file .p12 ======== \";\r\
    \n        /certificate export-certificate \"\$newClient@\$DNSaddress\" typ\
    e=pkcs12 export-passphrase=\$Password;\r\
    \n\r\
    \n    }  on-error={:put \"!!! cannot create client certificate \$newClient\
    @\$DNSaddress\";}\r\
    \n\r\
    \n    /ip ipsec identity add auth-method=digital-signature certificate=\"\
    \$DNSaddress\" remote-certificate=(\"\$newClient\" . \"@\" .\"\$DNSaddress\
    \") generate-policy=port-strict match-by=certificate mode-config=\"\$DNSad\
    dress\" peer=\"peer \$IPaddress\" policy-template-group=\"\$DNSaddress\" r\
    emote-id=\"user-fqdn:\$newClient@\$DNSaddress\" comment=\$DNSaddress\r\
    \n\r\
    \n    :put \" ============== Script finished ============== \"\r\
    \n\r\
    \n}"
