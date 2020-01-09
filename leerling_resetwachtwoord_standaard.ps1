# script om wachtwoord van leerling opnieuw in te stellen (op standaardwachtwoord)

$gebruikersnaam = read-host "Geef de gebruikersnaam (zonder @maildomein.be)"

Set-ADAccountPassword -Identity $gebruikersnaam -NewPassword (ConvertTo-SecureString -AsPlainText "standaardwachtwoord" -Force)

write-host "wachtwoord is ingesteld op standaardwachtwoord"