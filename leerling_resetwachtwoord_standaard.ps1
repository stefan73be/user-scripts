# script om wachtwoord van leerling opnieuw in te stellen (op S-test01)

$gebruikersnaam = read-host "Geef de gebruikersnaam (zonder @mosa-rt.be)"

Set-ADAccountPassword -Identity $gebruikersnaam -NewPassword (ConvertTo-SecureString -AsPlainText "S-test01" -Force)

write-host "wachtwoord is ingesteld op S-test01"