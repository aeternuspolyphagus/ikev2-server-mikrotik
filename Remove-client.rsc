:do {/ip ipsec peer print detail value-list}
/ip ipsec peer print where exchange-mode=ike2
:put "I found next ipsec peer. Enter his number for remove client configuration."
:local read do={:return}
:set $foundpeer [$read]
:local peername [/ip ipsec peer get value-name=name number=$foundpeer]
:do {/ip ipsec identity print value-list}
/ip ipsec identity print where peer=$peername
:put "Choose client number."
:local read do={:return}
:local clientid [$read]
:put "Do you want to remove the client or disable it? Choose 1 for disable or 2 for delete."
:local read do={:return}
:local answer [$read]

:if ($answer = 1) do {

    /ip ipsec identity disable numbers=$clientid

}

:if ($answer = 2) do {

    /ip ipsec identity remove numbers=$clientid
    
}