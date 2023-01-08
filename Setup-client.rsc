:local newClient
:local Password

:local peerconf [/ip ipsec peer find where exchange-mode=ike2]

:if ($peerconf = "") do {

    :put "I can't found any ipsec configuration. Before run this script you must run script Setup-server."

} else {

    :do {/ip ipsec peer print detail value-list}
    /ip ipsec peer print where exchange-mode=ike2
    :put "I found next ipsec peer. Enter his number for create client configuration."
    :local read do={:return}
    :set $foundpeer [$read]
    :local peerconf [:toarray [ip ipsec peer find where exchange-mode=ike2]]
    :local foundpeerconf [:pick $peerconf $foundpeer]
    :local DNSaddress [/ip ipsec peer get value-name=comment number=[:pick $peerconf $foundpeer]]
    :local IPaddress [/ip ipsec peer get value-name=local-address  number=[:pick $peerconf $foundpeer]]
    :put $IPaddress
    :put $DNSaddress
    :put "Insert username"
    :local readuser do={:return}
    :set $newClient [$readuser]
    :put $newClient
    :put "Insert password"
    :local readpass do={:return}
    :set $Password [$readpass]
    :put $Password
    :put " ============== Starting script ============== "
    :put " ======== Creating client certificate from template ======== "
        
    :do {
            
        /certificate 
        add copy-from="~client-template@$DNSaddress" name="$newClient@$DNSaddress" common-name="$newClient@$DNSaddress" subject-alt-name="email:$newClient@$DNSaddress";

    :put " ======== Signing first client certificate with ca.$DNSaddress ======== ";
        /certificate sign "$newClient@$DNSaddress" ca="ca.$DNSaddress";

        :put " ======== Exporting first client certificate + private key into file .p12 ======== ";
        /certificate export-certificate "$newClient@$DNSaddress" type=pkcs12 export-passphrase=$Password;

    }  on-error={:put "!!! cannot create client certificate $newClient@$DNSaddress";}

    /ip ipsec identity add auth-method=digital-signature certificate="$DNSaddress" remote-certificate="$newClient@$DNSaddress" generate-policy=port-strict match-by=certificate mode-config="modeconf $DNSaddress" peer="peer $IPaddress" policy-template-group="group $DNSaddress" remote-id="user-fqdn:$newClient@$DNSaddress" comment=$DNSaddress

    :put " ============== Script finished ============== "

}