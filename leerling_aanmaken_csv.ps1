<# script om leerlingaccounts in de AD aan te maken, in bulk. 
Account met instellingen, home-drive en profielmap worden aangemaakt. Ook de gebruikersnaam wordt aangemaakt (met verwijdering van speciale tekens)
Leerlingen worden in de juiste klasgroep gezet en in de juiste OU
Leerlingen.csv moet 
    - komma-gescheiden zijn
    - volgende velden (en koppen) bevatten: voornaam, 
                                            achternaam, 
                                            geboortedatum (in formaat DD-MM-JJJJ), 
                                            wachtwoord, 
                                            opslagserver en 
                                            klas (met belangstellingsgebied)
#>
<#
Gewenste uitbreidingen:
    - uitlezen uit een database (Smartschool, Informat) en enkel de nieuwe leerlingen en wijzigingen verwerken
    - webinterface 
    - spaties verwijderen uit namen
    - foutafhandeling bij ontbrekende gegevens (geboortedatum bijvoorbeeld)
#>

#verwijderen van diakritische tekens uit de naam en voornaam
function VerwijderAccenten
{
    PARAM ([string]$String)
    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($String))
}

# verbinding maken met Office365 om de mailbox aan te maken (gebeurt via Azure AD Sync, dus niet nodig in de bovenbouw)
# connect-msolservice

$csv = read-host "Geef de bestandsnaam met de leerlingen (inclusief de .csv extensie)"
$ADgebruikers = Import-csv $csv -encoding UTF7

foreach ($gebruiker in $ADgebruikers) {

#gebruikers lijn per lijn uitlezen uit de csv
#$gebruikersnaam = $gebruiker.gebruikersnaam
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

# wachtwoord versleutelen
$SecurePassword=ConvertTo-SecureString $gebruiker.wachtwoord –asplaintext –force

<# Azure account en mailbox aanmaken voor de gebruiker
New-Msoluser –userprincipalname "$gebruikersnaam@leerling.mosa-rt.be" `             -displayname "$voornaamzuiver $achternaamzuiver Leerling" `             -password $wachtwoord `
             –firstname $voornaamzuiver `
             -lastname $achternaamzuiver `
             -passwordneverexpires 1 `
             -forcechangepassword 0 `             -LicenseAssignment kasomk:STANDARDWOFFPACK_IW_STUDENT `
             -usagelocation be `
             -PreferredLanguage nl
#>

if (Get-ADUser -F {SamAccountName -eq $gebruikersnaam})
	{
		 #geef een waarschuwing als de gebruiker al bestaat
		 Write "De gebruiker $gebruikersnaam bestaat al in de Active Directory, er wordt niets gewijzigd."
	}
	else
        {
        if (Get-ADGroup -F {Name -eq $klas})
	    {
            Write "De klasgroep $klas bestaat al, gebruiker wordt eraan toegevoegd."
        }
        else{
		     #geef een waarschuwing als de klas niet bestaat
		     Write-Warning "De klasgroep $klas bestaat nog niet in de Active Directory, ze wordt nu toegevoegd."
             New-ADGroup -Name $klas -GroupCategory Security -GroupScope Global -Path "OU=OUGroepen,OU=OUAzureAD,DC=kaso,DC=lok"
   	    }
	    if (Get-ADOrganizationalUnit -F {Name -eq $klas})
	    {
            Write "De OU $klas bestaat al, gebruiker wordt eraan toegevoegd."
        }
        else{
		     #geef een waarschuwing als de OU niet bestaat
		     Write-Warning "De OU $klas bestaat nog niet in de Active Directory, ze wordt nu toegevoegd."
             New-ADOrganizationalUnit -Name $klas -Path "OU=$klasjaarwoord,OU=OULeerlingen,OU=OUAzureAD,DC=kaso,DC=lok"
	    }


        
        
        # gebruiker aanmaken in de AD
        New-ADUser -Name $gebruikersnaam -AccountPassword $securepassword -ChangePasswordAtLogon 0 -Department $klas `
            -DisplayName "$voornaamzuiver $achternaamzuiver" -EmailAddress $gebruikersnaam@leerling.mosa-rt.be -Enabled 1 -GivenName $voornaamzuiver `
            -HomeDirectory \\$server\homedirs\$klas\$gebruikersnaam -HomeDrive U: -PasswordNeverExpires 1 `
            -Path "OU=$klas,OU=$klasjaarwoord,OU=OULeerlingen,OU=OUAzureAD,DC=kaso,DC=lok" -ProfilePath \\$server\profiel\$klas\$gebruikersnaam `
            -SamAccountName $gebruikersnaam -Surname $achternaamzuiver -UserPrincipalName $gebruikersnaam@leerling.mosa-rt.be

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
        if (!(test-path -path "\\$server\profielen$\$klas\$gebruikersnaam.V6"))
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
}
