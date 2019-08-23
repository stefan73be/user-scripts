# script om licenties aan Azure users toe te wijzen, op basis van CSV
# ook worden land en taal voor Azure juist gezet (en onedrive geinitialiseerd)

function VerwijderAccenten
{
    PARAM ([string]$String)
    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))
}

# verbinding maken met Office365 om de mailbox aan te maken
connect-msolservice

$ADgebruikers = Import-csv leerlingen.csv -encoding UTF7

foreach ($gebruiker in $ADgebruikers) {

    $wachtwoord = $gebruiker.wachtwoord
    $server = $gebruiker.server
    $klas = $gebruiker.klas
    $voornaam = $gebruiker.voornaam
    $achternaam = $gebruiker.achternaam
    $gebdatum = $gebruiker.geboortedatum   

    # diakritische tekens verwijderen en gebruikersnaam samenstellen
    $voornaamzuiver = VerwijderAccenten($voornaam)
    $achternaamzuiver = VerwijderAccenten($achternaam)
    # geboordatum in 6 cijfers samenstellen
    $gebdatum6=$gebdatum.substring(0,2)+$gebdatum.substring(3,2)+$gebdatum.substring(8,2)
    $gebruikersnaam = $achternaamzuiver.substring(0,2)+$voornaamzuiver.substring(0,2)+$gebdatum6

    # $SecurePassword=ConvertTo-SecureString $gebruiker.wachtwoord –asplaintext –force

    Set-Msoluser `             –userprincipalname "$gebruikersnaam@leerling.mosa-rt.be" `             -passwordneverexpires 1 `             -usagelocation be `

    Set-MsolUserLicense -UserPrincipalName "$gebruikersnaam@leerling.mosa-rt.be" -AddLicenses kasomk:STANDARDWOFFPACK_IW_STUDENT

}