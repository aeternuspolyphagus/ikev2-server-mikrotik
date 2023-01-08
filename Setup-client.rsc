:local newClient
:local Password

:local DNSaddress
:local IPaddress


:put "Insert username"
:local readuser do={:return}
:set $newClient [$readuser]
:put $newClient

:put "Insert password"
:local readpass do={:return}
:set $Password [$readpass]
:put $Password

:log warn " ============== Starting script ============== "
:log info " ======== Creating client certificate from template ======== "
:do {
/certificate 
add copy-from="~client-template@$DNSaddress" name="$newClient@$DNSaddress" common-name="$newClient@$DNSaddress" subject-alt-name="email:$newClient@$DNSaddress";

:log info " ======== Signing first client certificate with ca.$DNSaddress ======== ";
/certificate sign "$newClient@$DNSaddress" ca="ca.$DNSaddress";

:log info " ======== Exporting first client certificate + private key into file .p12 ======== ";
/certificate export-certificate "$newClient@$DNSaddress" type=pkcs12 export-passphrase=$Password;

#:log info " ======== Sozdaem ostal'nye klientskie podpisi iz shablona(po analogii) ======== ";
}  on-error={:log error "!!! cannot create client certificate $newClient@$DNSaddress";}

/ip ipsec identity
add auth-method=digital-signature certificate="$DNSaddress" remote-certificate="$newClient@$DNSaddress" generate-policy=port-strict \
match-by=certificate mode-config="modeconf $DNSaddress" peer="peer $IPaddress" policy-template-group="group $DNSaddress" remote-id="user-fqdn:$newClient@$DNSaddress" comment=$DNSaddress

:log warn " ============== Script finished ============== "