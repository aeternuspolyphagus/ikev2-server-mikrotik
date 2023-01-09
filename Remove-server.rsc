:local peerconf [/ip ipsec peer find where exchange-mode=ike2]

:if ($peerconf = "") do {

    :put "I can't found any ipsec configuration. Before run this script you must run script Setup-server."

} else {

    :do {/ip ipsec peer print detail value-list}
    /ip ipsec peer print where exchange-mode=ike2
    :put "I found next ipsec peer. Enter his number for remove configuration."
    :local read do={:return}
    :set $foundpeer [$read]
    :local DNSaddress [/ip ipsec peer get value-name=comment number=$foundpeer]
    :local IPaddress [/ip ipsec peer get value-name=local-address  number=$foundpeer]
    :put $IPaddress
    :put $DNSaddress

}

:put "Remove client-identity"

/ip ipsec identity remove [find where comment=$DNSaddress]

:put "Remove IPSec peer"

/ip ipsec peer remove [find where comment=$DNSaddress]

:put "Remove modeconf"

/ip ipsec modeconf remove [find where name=$DNSaddress]

:put "Remove IPSec policy"

/ip ipsec policy remove [find where comment=$DNSaddress]

:put "Remove IPSec profile"

/ip ipsec profile remove [find where name=$DNSaddress]

:put "Remove proposal"

/ip ipsec proposal remove [find where name=$DNSaddress]

:put "Remove group"

/ip ipsec group remove [find where name=$DNSaddress]

:put "Remove bridge address"

/ip address remove [find where comment=$DNSaddress]

:put "Remove LoopBack bridge"

/interface bridge remove [find where comment=$DNSaddress]

:put "Remove IP-pool"

/ip pool remove [find where comment=$DNSaddress]