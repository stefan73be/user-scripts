# dit script maakt één leerkracht aan in de AD, maakt zijn mappen (homedir en profiel) aan met de nodige rechten en geeft de mogelijkheid
# een mail te versturen als de account aangemaakt is.

# aanmaken van de Office365 account gebeurt hier niet mee, daar zorgt Azure AD Sync voor.

<# gewenste uitbreidingen: 
    - afhandeling als account al bestaat (rechten aanpassen op mappen)
    - foutafhandeling
    - uitlezen uit database (delta verwerken ipv manuele input)
    - integratie in webinterface
    - aanmaken smartschool account voor leerkracht
#>

#input van de gebruiker
$voornaam = read-host "Geef de voornaam van de leerkracht (zonder accenten)"
$achternaam = read-host "Geef de achternaam van de leerkracht (zonder accenten)"
$gebruikersnaam = read-host "Geef de gebruikersnaam van de leerkracht (zonder accenten, in de vorm voornaam.achternaam)"
$wachtwoord = read-host "Geef een wachtwoord voor de leerkracht"
$server = read-host "Geef de server voor de homedir en profiel"
$mailprive = read-host "Geef het prive mailadres van de leerkracht (om mail te versturen)"

$SecurePassword=ConvertTo-SecureString $wachtwoord –asplaintext –force

# gebruiker aanmaken in de AD
if (Get-ADUser -F {SamAccountName -eq $gebruikersnaam})
	{
		 #geef een waarschuwing als de gebruiker al bestaat
		 Write "De gebruiker $gebruikersnaam bestaat al in de Active Directory, er wordt niets gewijzigd."
	}
	else
        {
        New-ADUser -Name $gebruikersnaam -AccountPassword $securepassword -ChangePasswordAtLogon 0 -Department Leerkracht `
            -DisplayName "$voornaam $achternaam" -EmailAddress $gebruikersnaam@maildomein.be -Enabled 1 -GivenName $voornaam `
            -HomeDirectory \\$server\homedirs\$gebruikersnaam -HomeDrive U: -PasswordNeverExpires 1 `
            -Path "OU=OULeerkrachten,OU=OUAzureAD,DC=domein,DC=lok" -ProfilePath \\$server\profiel\$gebruikersnaam `
            -SamAccountName $gebruikersnaam -Surname $achternaam -UserPrincipalName $gebruikersnaam@maildomein.be

        # gebruiker toevoegen aan de groep "Leerkrachten"
        Add-ADGroupMember -Identity Leerkrachten -Members $gebruikersnaam
        
        # homedir maken
        if (!(test-path -path "\\$server\homedirs\$gebruikersnaam"))
            {
            New-Item \\$server\homedirs\$gebruikersnaam -type directory
            # rechten op homedir instellen
            $acl = get-acl \\$server\homedirs\$gebruikersnaam
            $accessrule = new-object system.Security.AccessControl.FileSystemAccessRule("domein\$gebruikersnaam","Modify","ContainerInherit, ObjectInherit","None","Allow")
            $acl.SetAccessRule($AccessRule)
            $acl | set-acl \\$server\homedirs\$gebruikersnaam\
            }
            else {write-warning "De homedir voor $gebruikersnaam op server $server bestaat al"}

        # profielmap maken
        if (!(test-path -path "\\$server\profiel\$gebruikersnaam.V6"))
            {
            New-Item \\$server\profiel\$gebruikersnaam.V6 -type directory
            # rechten op profielmap instellen
            $acl = get-acl \\$server\profiel\$gebruikersnaam.V6
            $accessrule = new-object system.Security.AccessControl.FileSystemAccessRule("domein\$gebruikersnaam","FullControl","ContainerInherit, ObjectInherit","None","Allow")
            $acl.SetAccessRule($AccessRule)
            $acl | set-acl \\$server\profiel\$gebruikersnaam.V6\
            }
            else {write-warning "De profielmap voor $gebruikersnaam op server $server bestaat al"}

        write-host "De nieuwe gebruiker is aangemaakt"
        write-host "---------------------------------"
        write-host "Gebruikersnaam computer: $gebruikersnaam"
        write-host "Gebruikersnaam mailbox : $gebruikersnaam@maildomein.be"
        write-host "Wachtwoord voor computer en mailbox: $wachtwoord"
        write-host "Mailbox is binnen een uur actief via http://URLMailbox"
        write-host " "
        write-host "Denk eraan dat de licentie voor office nog moet toegewezen worden zodra de mailbox klaar is (duurt ongeveer een uur)"
        
        write-host " "
        $antwoord = Read-host "Wil je de gegevens per mail naar de leerkracht sturen? (j/n)"
        write-host " "

        if ($antwoord -eq "j")
        {
        send-mailmessage -smtpserver SMTPserver `
                         -from "afzender@maildomein.be" `
                         -to "$mailprive" `
                         -cc "afzender@maildomein.be","ictco@maildomein.be" `
                         -subject "$voornaam $achternaam - login-gegevens voor mailbox en computers campus" `
                         -body "Dag $voornaam<br><br> Hieronder vind je de gegevens om in te loggen`
                                <br><br>Gebruikersnaam: $gebruikersnaam`
                                <br>Wachtwoord: $wachtwoord`
                                <br>Mailadres: $gebruikersnaam@maildomein.be met hetzelfde wachtwoord`
                                <br><br>Je mailbox zou binnen het uur actief moeten zijn en is bereikbaar via http://URLmailbox`
                                <br><br>Veel succes met je opdracht`
                                <br><br>Met vriendelijke groeten`
                                <br>ICT-dienst" `
                          -BodyAsHtml `
                          -DeliveryNotificationOption OnSuccess,OnFailure
        }
        else {write-host "Oké, de mail wordt niet verstuurd"}
}