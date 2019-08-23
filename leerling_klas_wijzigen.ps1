<# Met dit script kan je een leerling van klas wijzigen
   Wijzigingen:
            Department veld wijzigen in AD
            Lidmaatschap van klasgroep
            Lokatie OU in AD
            Homedirectory wijzigen in AD
            Profielmap wijzigen in AD
            Homedirectory verplaatsen naar andere lokatie
            Profielmap verplaatsen naar andere lokatie

Parameters nodig: scriptnaam.ps1 gebruikersnaam oudeklas nieuweklas

#>

$gebruikersnaam = read-host "Geef de gebruikersnaam van de leerling (zonder domain)"
$oudeklas = read-host "Geef de oude klasnaam van de leerling (inclusief het belangstellingsgebied)"
$nieuweklas = read-host "Geef de nieuwe klasnaam van de leerling (inclusief het belangstellingsgebied)"
$server = read-host "Geef de oude servernaam"
$servernieuw = read-host "Geef de nieuwe servernaam"

# hieronder halen we het jaar uit de klasnaam, als het geen cijfer is wordt het "zevende"
$nieuweklasjaar = $nieuweklas.substring(2,1) # neem het derde karakter van de klasnaam
# write $nieuweklas
# write $nieuweklasjaar
$jaararray = "eerste","tweede","derde","vierde","vijfde","zesde","zevende"
if ($nieuweklasjaar -match '^[0-9]+$') # als het een cijfer is
    {
    $nieuweklasjaarwoord = $jaararray[$nieuweklasjaar-1]
    # write $nieuweklasjaarwoord
    }
    else{
    $nieuweklasjaarwoord = $jaararray[6] #als het geen cijfer is neem je "zevende"
    # write $nieuweklasjaarwoord
    }

#hieronder halen we het jaar uit de klasnaam, als het geen cijfer is wordt het "zevende"
$oudeklasjaar = $oudeklas.substring(2,1) # neem het derde karakter van de klasnaam
$jaararray = "eerste","tweede","derde","vierde","vijfde","zesde","zevende"
if ($oudeklasjaar -match '^[0-9]+$') # als het een cijfer is
    {
    $oudeklasjaarwoord = $jaararray[$oudeklasjaar-1]
    # write $klasjaarwoord
    }
    else{
    $oudeklasjaarwoord = $jaararray[6] #als het geen cijfer is neem je "zevende"
    # write $klasjaarwoord
    }


# als de nieuwe OU niet bestaat, breek het script af
if (!(Get-ADOrganizationalUnit -F {Name -eq $nieuweklas}))
	{
        Write-warning "De OU $nieuweklas bestaat niet, controleer de naam `n en maak eventueel de OU manueel aan."
        Exit
    }

# als de nieuwe klasgroep niet bestaat, breek het script af
if (!(Get-ADGroup -F {Name -eq $nieuweklas}))
	{
        Write-warning "De klasgroep $nieuweklas bestaat niet, controleer de naam `n en maak eventueel de klasgroep manueel aan."
        exit
    }

# weergeven van de huidige gegevens
Write "`nHuidige gegevens van de gebruiker"
Write "---------------------------------"
Get-ADUser -Identity $gebruikersnaam -Properties Department,HomeDirectory,Profilepath | select Department,HomeDirectory,Profilepath
#$oudeklas = Get-ADUser -Identity $gebruikersnaam -Properties Department | select Department
write "Huidige klas is     $oudeklas"
$gebruiker = Get-ADUser -Identity $gebruikersnaam -Properties CanonicalName
$oudeOU = ($gebruiker.DistinguishedName -split ",",2)[1]
write "Huidige OU is       $oudeOU"

#pas de gegevens in AD aan
    # algemene aanpassingen
    Set-ADUser  -identity $gebruikersnaam -Department $nieuweklas `
                -HomeDirectory \\$servernieuw\homedirs\$nieuweklas\$gebruikersnaam `
                -ProfilePath \\$servernieuw\profiel\$nieuweklas\$gebruikersnaam `
                    
    # aanpassen van de OU
    $nieuweOU = "OU=$nieuweklas,OU=$nieuweklasjaarwoord,OU=OULeerlingen,OU=OUAzureAD,DC=kaso,DC=lok"
    # write "$nieuweOU"
    Move-ADObject  -Identity $gebruiker.DistinguishedName -TargetPath $nieuweOU    

    # aanpassen van de klasgroep (lidmaatschap)
    Add-ADGroupMember -Identity $nieuweklas -Members $gebruikersnaam
    Remove-ADGroupMember -Identity $oudeklas -Members $gebruikersnaam -Confirm:$false
    # write $oudeklas $nieuweklas $gebruikersnaam

    #weergeven van de nieuwe gegevens
    Write "`n`nNieuwe gegevens van de gebruiker" 
    Write "--------------------------------"
    Get-ADUser -Identity $gebruikersnaam -Properties Department,HomeDirectory,Profilepath | select Department,HomeDirectory,Profilepath
    write "Nieuwe klas is     $nieuweklas"
    write "Nieuwe OU is       $nieuweOU"

#verplaats homedirectory
    Move-Item -Path \\$server\homedirs\$oudeklas\$gebruikersnaam -Destination \\$servernieuw\homedirs\$nieuweklas\$gebruikersnaam

#verplaats profielmap
    move-item -path \\$server\profiel\$oudeklas\$gebruikersnaam.V6 -Destination \\$servernieuw\profiel\$nieuweklas\$gebruikersnaam.V6