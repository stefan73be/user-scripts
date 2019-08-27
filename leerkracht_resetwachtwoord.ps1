# script om wachtwoord van leerkracht opnieuw in te stellen (vraagt wachtwoord)

$gebruikersnaam = read-host "Geef de gebruikersnaam (zonder @maildomein.be)"
$wachtwoord = read-host "Geef het nieuwe wachtwoord"

Set-ADAccountPassword -Identity $gebruikersnaam -NewPassword (ConvertTo-SecureString -AsPlainText $wachtwoord -Force)

write-host "Wachtwoord is ingesteld op $wachtwoord"