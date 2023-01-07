:local DNSaddress
:local IPaddress
:put "You have Domain name?\r\nIf have you have press y.\r\n Else press any key."
:local read do={:return}
:set $answer [$read]
:put $answer

do {

    :if ($answer = "y") do {

        :put "Enter your Domain name."
        :local read do={:return}
        :set $DNSaddress [$read]
        :put $DNSaddress

    } else {

        :if ([/ip cloud get value-name=ddns-enabled] = "") do {

            /ip cloud set ddns-enabled=yes
            :delay 10s
            :set $DNSaddress [/ip cloud get value-name=dns-name]

        } else {

            :set $DNSaddress [/ip cloud get value-name=dns-name]

        }

    }

    :put "Enter your real ip.\r\nFor auto-ident press 0."
    :local read do={:return}
    :set $answer [$read]
    :put $answer

    :if ($answer = 0) do {

        /tool fetch url="https://v4.ident.me/" dst-path=myIPv4.txt
        :delay 1s
        :set $IPaddress [/file get myIPv4.txt contents]
        :put "$IPaddress It's your address?"
        /file remove myIPv4.txt

    } else {

        :set $IPaddress [$answer]
        :put "$IPaddress It's your address?"

    }

    :put "Do you want create certificate bundle? Like CA, Server certificate and temp client certificate?\r\nPress y if you want or press any key."

    :put $DNSaddress
    :put $IPaddress

    :local read do={:return}
    :set $answer [$read]
    
    :if ($answer = "y") do {

        :put "Enter country:"
        :local read do={:return}
        :set $country [$read]
        :put "Enter state:"
        :local read do={:return}
        :set $state [$read]
        :put "Enter city:"
        :local read do={:return}
        :set $city [$read]
        :put "Generate CA-certificate."
        /certificate add name="ca.$DNSaddress" country="$country" state="$state" locality="$city" organization="$DNSaddress" common-name="ca.$DNSaddress"  subject-alt-name="DNS:ca.$DNSaddress" key-size=4096 days-valid=3650 trusted=yes key-usage=digital-signature,key-encipherment,data-encipherment,key-cert-sign,crl-sign
        /certificate sign "ca.$DNSaddress"
        :put "Generate IKE2-Server certificate."
        /certificate add name="$DNSaddress" country="$country" state="$state" locality="$city" organization="$DNSaddress" common-name="$DNSaddress" subject-alt-name="DNS:$DNSaddress" key-size=2048 days-valid=1095 trusted=yes key-usage=tls-server
        /certificate sign "$DNSaddress" ca="ca.$DNSaddress"
        :put "Generate Client-template."
        /certificate add name="~client-template@$DNSaddress" country="$country" state="$state" locality="$city" organization="$DNSaddress" common-name="~client-template@$DNSaddress"    subject-alt-name="email:~client-template@$DNSaddress" key-size=2048 days-valid=365 trusted=yes key-usage=tls-client

    }

    :put "Do you want to create LoopBack-Bridge? Press y for yes or any key to no."
    :local read do={:return}
    :set $answer [$read]

    :if ($answer = "y") do {

        :put "Create LoopBack-bridge."
        /interface bridge add name="LoopBack"
        :put "Enter ip address for bridge."
        :local read do={:return}
        :set $answer [$read]
        :put "Enter mask for bridge like 24, 16, 30 and etc."
        :local read do={:return}
        :local mask
        :set $mask [$read]
        /ip address add address=([$answer]. "/" . $mask) interface=LoopBack
        :put "Enter ip-pool for Ipsec-client. Like x.x.x.100-x.x.x.200."
        :local pool
        :local read do=[:return]
        :set pool [$read]
        /ip pool add name="pool $DNSaddress" ranges=$pool
        :put "You want route for specified network or any? Enter specified networks like x.x.x.x/x,y.y.y.y/y or press 0."
        :local split
        :local read do=[:return]
        :set $split [$read]
        :if ($split != 0) do {

            :put "Generate IpSec configurations."
            /ip ipsec mode-config add address-pool="pool $DNSaddress" address-prefix-length=32 name="modeconf $DNSaddress" split-include=$split static-dns=$answer system-dns=no            

        } else {

            :put "Generate IpSec configurations."
            /ip ipsec mode-config add address-pool="pool $DNSaddress" address-prefix-length=32 name="modeconf $DNSaddress" split-include=0.0.0.0/0 static-dns=$answer system-dns=no

        }

        /ip ipsec profile add dh-group=modp2048,modp1536,modp1024 enc-algorithm=aes-256,aes-192,aes-128 hash-algorithm=sha256 name="profile $DNSaddress" nat-traversal=yes  proposal-check=obey 
        /ip ipsec peer add exchange-mode=ike2 address=0.0.0.0/0 local-address="$IPaddress" name="peer $IPaddress" passive=yes send-initial-contact=yes profile="profile $DNSaddress"
        /ip ipsec proposal add auth-algorithms=sha512,sha256,sha1 enc-algorithms=aes-256-cbc,aes-256-ctr,aes-256-gcm,aes-192-ctr,aes-192-gcm,aes-128-cbc,aes-128-ctr,aes-128-gcm lifetime=8h name="proposal $DNSaddress" pfs-group=none
        /ip ipsec policy group add name="group $DNSaddress"
        :local dst [ /ip address get value-name=network [ find where interface=LoopBack ] ]
        /ip ipsec policy add dst-address=($dst . "/" . $mask) group="group $DNSaddress" proposal="proposal $DNSaddress" src-address=0.0.0.0/0 template=yes

    }

    :put "Do you want "

}