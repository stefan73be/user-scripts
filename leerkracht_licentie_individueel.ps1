﻿write-host "Dit script doet de landinstellingen voor een mailbox en wijst een licentie van Office toe"

    Set-MsolUserLicense -UserPrincipalName "$gebruikersnaam@mosa-rt.be" -AddLicenses kasomk:STANDARDWOFFPACK_IW_FACULTY

write-host "De Office-licentie Office 365 Pro Plus voor leerkrachten is toegewezen"