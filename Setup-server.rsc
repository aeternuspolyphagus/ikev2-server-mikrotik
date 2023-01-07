:local read

:local DNSaddress
:put "You have Domain name?\r\nIf have you have press 1.\r\n Else press any key."
:local read do={:return}
:set $answer [$read]
:put $answer
:if ($answer = 1) do {
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

:put "Enter your real ip.\r\nFor auto press 0."
:local read do={:return}
:set $answer [$read]
:put $answer

:if ($answer = 0) do {
    /tool fetch url="https://v4.ident.me/" dst-path=myIPv4.txt
    :delay 1s
    :local IPaddress [/file get myIPv4.txt contents]
    :put "$IPaddress It's your address?"
    /file remove myIPv4.txt
} else {
    :local IPaddress
    :set $IPaddress [$answer]
    :put "$IPaddress It's your address?"
}