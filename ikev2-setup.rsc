:local WhatYouWant

:put "What you want?"
:put "1: Create server"
:put "2: Remove server"
:put "3: Create client"
:put "4: Remove client"

:local read do={:return}
:set WhatYouWant [$read]
:put $WhatYouWant

do {
    :if ($WhatYouWant = 1) do {

        system script run Setup-server
    
    }
    
    :if ($WhatYouWant = 2) do {

        system script run Remove-server

    }
    
    :if ($WhatYouWant = 3) do {
        
        system script run Setup-client

    }
    
    :if ($WhatYouWant = 4) do {

        system script run Remove-client
        
    }
}