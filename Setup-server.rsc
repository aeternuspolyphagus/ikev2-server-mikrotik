:local DNSaddress
:local IPaddress
:local answer
:put "You have Domain name?\r\nIf have you have press y.\r\nElse press any key."
:local read do={:return}
:set $answer [$read]

:do {

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
    
    :local IP
    :put "Enter your real ip.\r\nFor auto-ident press 0."
    :local read do={:return}
    :set $IP [$read]

    :if ($IP = 0) do {

        /tool fetch url="https://v4.ident.me/" dst-path=myIPv4.txt
        :delay 1s
        :set $IPaddress [/file get myIPv4.txt contents]
        :put "$IPaddress It's your address?"
        /file remove myIPv4.txt

    } else {

        :set $IPaddress [$IP]
        :put "$IPaddress It's your address?"

    }

    :put $DNSaddress
    :put $IPaddress

    :put "Do you want create certificate bundle? Like CA, Server certificate and temp client certificate?\r\nPress y if you want or press any key."

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


        :put "Create LoopBack-bridge."
        /interface bridge add name="LoopBack" comment=$DNSaddress
        :put "Enter ip address for bridge."
        :local IPBR
        :local read do={:return}
        :set $IPBR [$read]
        /ip address add address=([$IPBR]. "/24") interface=LoopBack comment=$DNSaddress
        :put "Enter ip-pool for Ipsec-client. Like x.x.x.100-x.x.x.200."
        :local pool
        :local read do=[:return]
        :set pool [$read]
        /ip pool add name="pool $DNSaddress" ranges=$pool comment=$DNSaddress
        :put "You want route for specified network or any? Enter specified networks like x.x.x.x/x,y.y.y.y/y or press 0."
        :local split
        :local read do=[:return]
        :set $split [$read]

        :if ($split != 0) do {

            :put "Generate IpSec configurations."
            /ip ipsec mode-config add address-pool="pool $DNSaddress" address-prefix-length=32 name="$DNSaddress" split-include=$split static-dns=$IPBR system-dns=no            

        } else {

            :put "Generate IpSec configurations."
            /ip ipsec mode-config add address-pool="pool $DNSaddress" address-prefix-length=32 name=" $DNSaddress" split-include=0.0.0.0/0 static-dns=$IPBR system-dns=no

        }

        /ip ipsec profile add dh-group=modp2048,modp1536,modp1024 enc-algorithm=aes-256,aes-192,aes-128 hash-algorithm=sha256 name="$DNSaddress" nat-traversal=yes  proposal-check=obey 
        /ip ipsec peer add exchange-mode=ike2 address=0.0.0.0/0 local-address="$IPaddress" name="peer $IPaddress" passive=yes send-initial-contact=yes profile="$DNSaddress" comment=$DNSaddress
        /ip ipsec proposal add auth-algorithms=sha512,sha256,sha1 enc-algorithms=aes-256-cbc,aes-256-ctr,aes-256-gcm,aes-192-ctr,aes-192-gcm,aes-128-cbc,aes-128-ctr,aes-128-gcm lifetime=8h name="$DNSaddress" pfs-group=none
        /ip ipsec policy group add name="$DNSaddress"
        :local dst [ /ip address get value-name=network [ find where interface=LoopBack ] ]
        /ip ipsec policy add dst-address=($dst . "/24") group="$DNSaddress" proposal="$DNSaddress" src-address=0.0.0.0/0 template=yes comment=$DNSaddress

    :put "Do you want generate firewall rules? Enter y or press any key"
    :local read do=[:return]
    :set $answer [$read]
    
    :if ($answer = "y") do {

        :put "Generate firewall rules."
        
        :if ([/ip firewall mangle find ipsec-policy="out,ipsec"] = "") do {
            
            /ip firewall mangle add action=mark-connection chain=output comment="mark ipsec connections" ipsec-policy=out,ipsec new-connection-mark=ipsec passthrough=yes
        
        }
        
        :if ([/ip firewall mangle find ipsec-policy="in,ipsec"] = "") do {
        
            /ip firewall mangle add action=mark-connection chain=input comment="mark ipsec connections" ipsec-policy=in,ipsec new-connection-mark=ipsec passthrough=yes
        
        }
        
        :if ([/ip firewall mangle find new-mss="1360"] = "") do {
        
            /ip firewall mangle add action=change-mss chain=forward ipsec-policy=in,ipsec new-mss=1360 passthrough=yes protocol=tcp src-address=($dst . "/24") tcp-flags=syn tcp-mss=!0-1360
            /ip firewall mangle add action=change-mss chain=forward dst-address=($dst . "/24") ipsec-policy=out,ipsec new-mss=1360 passthrough=yes protocol=tcp tcp-flags=syn tcp-mss=!0-1360
        
        }
        
        :if ([/ip firewall nat find src-address=($dst . "/24")] = "") do {
        
            /ip firewall nat add action=src-nat chain=srcnat ipsec-policy=out,none src-address=($dst . "/24") to-addresses=$IPaddress
        
        }
        
        :if ([/ip firewall filter find port="4500"] = "") do {
        
            :if ([/ip firewall filter find port="500"] = "") do {
        
                :if ([/ip firewall filter find port="500,4500"] = "") do {
        
                    /ip firewall filter add action=accept chain=input dst-address=$IPaddress port=500,4500 protocol=udp 
                    :put "Firewall filter rules for ports 500,4500 created."
        
                } else {
        
                    :put "Firewall filter rules for ports 500, 4500 exist. Skip"
        
                }
        
            } else {
        
                /ip firewall filter add action=accept chain=input dst-address=$IPaddress port=4500 protocol=udp 
                :put "Firewall filter rules for port 500 exist, but for port 4500 not. Created"
        
            }
        
        } else {
        
            :if ([/ip firewall filter find port="500"] = "") do {
        
                /ip firewall filter add action=accept chain=input dst-address=$IPaddress port=500 protocol=udp 
                :put "Firewall filter rules for port 4500 exist, but for port 500 not. Created"
        
            } else {
        
                :put "Firewall filter rules for ports 500, 4500 exist. Skip"
        
            }
        
        }
        
        :if ([/ip firewall filter find where protocol="ipsec-esp"] = "") do {
        
            /ip firewall filter add action=accept chain=input dst-address=$IPaddress protocol=ipsec-esp 
            :put "Firewall filter rule for protocol IPSec-ESP created."
        
        } else {
        
            :put "Firewall filter rule for protocol IPSec-ESP exist. Skip."
        
        }
        
        :if ([/ip firewall filter find ipsec-policy="in,ipsec" src-address=($dst . "/24") chain=input] = "") do {
        
            /ip firewall filter add action=accept chain=input ipsec-policy=in,ipsec src-address=($dst . "/24") 
            :put "Firewall filter rule for allow access from IKE2 clients to router created."
        
        } else {
        
            :put "Firewall filter rule for allow access from IKE2 clients to router exist. Skip."
        
        }
        
        :if ([/ip firewall filter find ipsec-policy="in,ipsec" chain=forward] = "") do {
            /ip firewall filter add action=accept chain=forward ipsec-policy=in,ipsec 
            :put "Firewall filter rule forward from IKE2 clients created."
        
        } else {
        
            :put "Firewall filter rule forward from IKE2 clients exist. Skip"
        
        }
        
        :if ([/ip firewall filter find ipsec-policy="in,ipsec" src-address=($dst . "/24") dst-address="0.0.0.0/0" chain=forward] = "") do {
        
            /ip firewall filter add action=accept chain=forward dst-address=0.0.0.0/0 ipsec-policy=in,ipsec src-address=($dst . "/24") 
            :put "Firewall filter rule forward from IKE2 clients created to any."
        
        } else {
        
            :put "Firewall filter rule forward from IKE2 clients exist to any. Skip"
        
        }
        
        :if ([/ip firewall filter find ipsec-policy="out,ipsec" chain=forward] = "") do {
        
            /ip firewall filter add action=accept chain=forward ipsec-policy=out,ipsec 
            :put "Firewall filter rule forward out IKE2 clients created."
        
        } else {
        
            :put "Firewall filter rule forward out IKE2 clients exist. Skip"
        
        }
        
        :if ([/ip firewall filter find action=fasttrack-connection chain=forward connection-state="established,related"] = "") do {
        
            /ip firewall filter add action=fasttrack-connection chain=forward connection-mark=!ipsec connection-state=established,related 
            :put "Firewall filter rule for fasttrack created."
        
            :if ([/ip firewall filter find chain=forward connection-state="established,related,untracked"] = "") do {
        
                /ip firewall filter add action=accept chain=forward connection-state=established,related,untracked 
                :put "Firewall filter rule for established, related, untracked connection created. "
        
            } else {
        
                :put "Firewall filter rule for established, related, untracked connection exist. Skip."
        
            }
        
        } else {
        
            :if ([/ip firewall filter find action=fasttrack-connection chain=forward connection-state="established,related" connection-mark="!ipsec"] = "") do {
        
                /ip firewall filter set [find action=fasttrack-connection] connection-mark=!ipsec
                :put "Modificate fasttrack filter rule for correct work with ipsec."
        
                :if ([/ip firewall filter find chain=forward connection-state="established,related,untracked"] = "") do {
        
                    /ip firewall filter add action=accept chain=forward connection-state=established,related,untracked 
                    :put "Firewall filter rule for established, related, untracked connection created. "
        
                } else {
        
                :put "Firewall filter rule for established, related, untracked connection exist. Skip."
        
                }
        
            } else {
        
                :put "Correct fasttrack filter rule for correct work with ipsec exist. Skip."
        
                :if ([/ip firewall filter find chain=forward connection-state="established,related,untracked"] = "") do {
        
                    /ip firewall filter add action=accept chain=forward connection-state=established,related,untracked 
                    :put "Firewall filter rule for established, related, untracked connection created. "
        
                } else {
        
                :put "Firewall filter rule for established, related, untracked connection exist. Skip."
        
                }
            }
        }
    }
}