# aanmaken van een individuele leerling

$voornaam = read-host "Geef de voornaam van de leerling (zonder accenten)"
$achternaam = read-host "Geef de achternaam van de leerling (zonder accenten)"
$gebruikersnaam = read-host "Geef de gebruikersnaam van de leerling (zonder accenten)"
$wachtwoord = read-host "Geef een wachtwoord voor de leerling"
$server = read-host "Geef de server voor de homedir en profiel"
$klas = read-host "Geef de klas voor de leerling (inclusief interessegebied)"

$SecurePassword=ConvertTo-SecureString $wachtwoord –asplaintext –force

# hieronder halen we het jaar uit de klasnaam, als het geen cijfer is wordt het "zevende"
$klasjaar = $klas.substring(2,1) # neem het derde karakter van de klasnaam
$jaararray = "eerste","tweede","derde","vierde","vijfde","zesde","zevende"
if ($klasjaar -match '^[0-9]+$') # als het een cijfer is
    {
    $klasjaarwoord = $jaararray[$klasjaar-1]
    # write $klasjaarwoord
    }
    else{
    $klasjaarwoord = $jaararray[6] #als het geen cijfer is neem je "zevende"
    # write $klasjaarwoord
    }
# ---------------------------------------------------------------------------------------

if (Get-ADUser -F {SamAccountName -eq $gebruikersnaam})
	{
		 #geef een waarschuwing als de gebruiker al bestaat
		 Write "De gebruiker $gebruikersnaam bestaat al in de Active Directory, er wordt niets gewijzigd."
	}
	else
        {
        if (Get-ADGroup -F {Name -eq $klas})
	    {
            Write "De klasgroep $klas bestaat al, gebruikers wordt eraan toegevoegd."
        }
        else{
		     #geef een waarschuwing als de klas niet bestaat
		     Write-Warning "De klasgroep $klas bestaat nog niet in de Active Directory, ze wordt nu toegevoegd."
             New-ADGroup -Name $klas -GroupCategory Security -GroupScope Global -Path "OU=OUGroepen,OU=OUAzureAD,DC=kaso,DC=lok"
   	    }
	    if (Get-ADOrganizationalUnit -F {Name -eq $klas})
	    {
            Write "De OU $klas bestaat al, gebruikers wordt eraan toegevoegd."
        }
        else{
		     #geef een waarschuwing als de OU niet bestaat
		     Write-Warning "De OU $klas bestaat nog niet in de Active Directory, ze wordt nu toegevoegd."
             New-ADOrganizationalUnit -Name $klas -Path "OU=$klasjaarwoord,OU=OULeerlingen,OU=OUAzureAD,DC=kaso,DC=lok"
	    }


        
        
        # gebruiker aanmaken in de AD
        New-ADUser -Name $gebruikersnaam -AccountPassword $securepassword -ChangePasswordAtLogon 0 -Department $klas `
            -DisplayName "$voornaam $achternaam" -EmailAddress $gebruikersnaam@leerling.mosa-rt.be -Enabled 1 -GivenName $voornaamzuiver `
            -HomeDirectory \\$server\homedirs\$klas\$gebruikersnaam -HomeDrive U: -PasswordNeverExpires 1 `
            -Path "OU=$klas,OU=$klasjaarwoord,OU=OULeerlingen,OU=OUAzureAD,DC=kaso,DC=lok" -ProfilePath \\$server\profiel\$klas\$gebruikersnaam `
            -SamAccountName $gebruikersnaam -Surname $achternaam -UserPrincipalName $gebruikersnaam@leerling.mosa-rt.be

        # gebruiker toevoegen aan klasgroep en de groep "Leerlingen"
        Add-ADGroupMember -Identity $klas -Members $gebruikersnaam
        Add-ADGroupMember -Identity Leerlingen -Members $gebruikersnaam
        
        # homedir maken
        if (!(test-path -path "\\$server\homedirs\$klas\$gebruikersnaam"))
            {
            New-Item \\$server\homedirs\$klas\$gebruikersnaam -type directory
            # rechten op homedir instellen
            $acl = get-acl \\$server\homedirs\$klas\$gebruikersnaam
            $accessrule = new-object system.Security.AccessControl.FileSystemAccessRule("kaso\$gebruikersnaam","Modify","ContainerInherit, ObjectInherit","None","Allow")
            $acl.SetAccessRule($AccessRule)
            $acl | set-acl \\$server\homedirs\$klas\$gebruikersnaam\
            }
            else {write-warning "De homedir voor $gebruikersnaam bestaat al"}

        # profielmap maken
        if (!(test-path -path "\\$server\profiel\$klas\$gebruikersnaam.V6"))
            {
            New-Item \\$server\profiel\$klas\$gebruikersnaam.V6 -type directory
            # rechten op profielmap instellen
            $acl = get-acl \\$server\profiel\$klas\$gebruikersnaam.V6
            $accessrule = new-object system.Security.AccessControl.FileSystemAccessRule("kaso\$gebruikersnaam","FullControl","ContainerInherit, ObjectInherit","None","Allow")
            $acl.SetAccessRule($AccessRule)
            $acl | set-acl \\$server\profiel\$klas\$gebruikersnaam.V6\
            }
            else {write-warning "De profielmap voor $gebruikersnaam bestaat al"}
        }



        write-host "De nieuwe gebruiker is aangemaakt"
        write-host "---------------------------------"
        write-host "Gebruikersnaam computer: $gebruikersnaam"
        write-host "Gebruikersnaam mailbox : $gebruikersnaam@leerling.mosa-rt.be"
        write-host "Wachtwoord voor computer en mailbox: $wachtwoord"
        write-host "<br>Mailbox is binnen een uur actief en bereikbaar via http://mail.mosa-rt.be"
        write-host 
        write-host "<br>Denk eraan dat de licentie voor office nog moet toegewezen worden zodra de mailbox klaar is (ongeveer een uur)"
        