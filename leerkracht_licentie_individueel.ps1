write-host "Dit script doet de landinstellingen voor een mailbox en wijst een licentie van Office toe"$gebruikersnaam = read-host "Geef de gebruikersnaam van de leerkracht (zonder accenten)"#verbinding maken met Office 365 als administratorconnect-msolserviceSet-Msoluser `             –userprincipalname "$gebruikersnaam@mosa-rt.be" `             -passwordneverexpires 1 `             -usagelocation be `

    Set-MsolUserLicense -UserPrincipalName "$gebruikersnaam@mosa-rt.be" -AddLicenses kasomk:STANDARDWOFFPACK_IW_FACULTY

write-host "De Office-licentie Office 365 Pro Plus voor leerkrachten is toegewezen"