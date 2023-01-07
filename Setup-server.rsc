:global DNSaddress
:global IPaddress
:put "You have Domain name?\r\nIf have you have press y.\r\n Else press any key."
:local read do={:return}
:set $answer [$read]
:put $answer

:if ($answer = "y") do {

    :put "Enter your Domain name."
    :local read do={:return}
    :set DNSaddress [$read]
    :put $DNSaddress

} else {

    :if ([/ip cloud get value-name=ddns-enabled] = "") do {

        /ip cloud set ddns-enabled=yes
        :delay 10s
        :set DNSaddress [/ip cloud get value-name=dns-name]

    } else {

        :set DNSaddress [/ip cloud get value-name=dns-name]

    }

}

:put "Enter your real ip.\r\nFor auto-ident press 0."
:local read do={:return}
:set $answer [$read]
:put $answer

:if ($answer = 0) do {

    /tool fetch url="https://v4.ident.me/" dst-path=myIPv4.txt
    :delay 1s
    :set IPaddress [/file get myIPv4.txt contents]
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
:put $answer

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
    :put "Export CA-certificate into local storage."

}