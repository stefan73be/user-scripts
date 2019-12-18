function Get-KlasJaar {
    # deze functie haalt het klasjaarwoord uit een klasnaam
    # aanroepen met $resultaat = Get-KlasJaar -klas $klas
    param (
        $klas
    )
    $klasjaar = $klas.substring(2, 1) # neem het derde karakter van de klasnaam
    $jaararray = "eerste", "tweede", "derde", "vierde", "vijfde", "zesde", "zevende"
    $belangst = "EM","TC","WT","WM"
    if ($klas.Substring(0,2) -in $belangst){
    if ($klasjaar -match '^[0-9]+$') {
        # als het een cijfer is
        $klasjaarwoord = $jaararray[$klasjaar - 1]
    }
    else {
        $klasjaarwoord = $jaararray[6] #als het geen cijfer is neem je "zevende"
    }   
    }
    else {$klasjaarwoord = "CLW"}
    return $klasjaarwoord 
}

function Set-VerwijderAccenten {
    # deze functie verwijdert accenten, maar geen afkappingstekens, koppeltekens of spaties
    # aanroepen met $gebruikersnaam = Set-verwijderaccenten -woord $gebruikersnaam
    PARAM ([string]$woord)
    [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($woord))
}

function Set-VerwijderTekens {
    #deze functie verwijdert spaties, accenten en koppeltekens uit een woord
    # aanroepen met $gebruikersnaam = Set-VerwijderTekens -woord $gebruikersnaam
    param (
        $woord
    )
    $woord = $woord.replace(" ", '')
    $woord = $woord.replace("-", '')
    $woord = $woord.replace("'", '')
    return $woord
}

function Get-RandomCharacters($length, $characters) {
    # deze functie genereert random karakters (nodig voor wachtwoord)
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs = ""
    return [String]$characters[$random]
}

function Get-RandomWachtwoord {
    # deze functie genereert een wachtwoord in de vorm XxxXxx99-
    # aanroepen zonder parameter
    $password = Get-RandomCharacters -length 1 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
    $password += Get-RandomCharacters -length 2 -characters 'abcdefghikmnoprstuvwxyz'
    $password += Get-RandomCharacters -length 1 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
    $password += Get-RandomCharacters -length 2 -characters 'abcdefghikmnoprstuvwxyz'
    $password += Get-RandomCharacters -length 2 -characters '1234567890'
    $password += Get-RandomCharacters -length 1 -characters '!./-*'
    return $password
}

function Get-Gebruikersnaam {
    # deze functie maakt de gebruikersnaam van een leerling aan
    # aanroepen met Get-gebruikersnaam -voornaam "voornaam" -achternaam "achternaam" -geboortedatum "01/01/1973"
    param (
        $voornaam,
        $achternaam,
        $geboortedatum
    )
    # diakritische tekens verwijderen en gebruikersnaam samenstellen
    $voornaamzuiver = Set-VerwijderAccenten($voornaam)
    $voornaamzuiver = Set-VerwijderTekens($voornaamzuiver)
    $achternaamzuiver = Set-VerwijderAccenten($achternaam)
    $achternaamzuiver = Set-VerwijderTekens($achternaamzuiver)
    # geboordatum in 6 cijfers samenstellen
    $gebdatum6 = $geboortedatum.substring(0, 2) + $geboortedatum.substring(3, 2) + $geboortedatum.substring(8, 2)
    $gebruikersnaam = $achternaamzuiver.substring(0, 2) + $voornaamzuiver.substring(0, 2) + $gebdatum6
    $gebruikersnaam = $gebruikersnaam.ToLower()
    return $gebruikersnaam
}

function Get-GebruikersnaamPersoneel {
    # deze functie maakt de gebruikersnaam van een leerling aan
    # aanroepen met Get-gebruikersnaam -voornaam "voornaam" -achternaam "achternaam" -geboortedatum "01/01/1973"
    param (
        $voornaam,
        $achternaam
    )
    # diakritische tekens verwijderen en gebruikersnaam samenstellen
    $voornaamzuiver = Set-VerwijderAccenten($voornaam)
    $voornaamzuiver = Set-VerwijderTekens($voornaamzuiver)
    $achternaamzuiver = Set-VerwijderAccenten($achternaam)
    $achternaamzuiver = Set-VerwijderTekens($achternaamzuiver)
    # geboordatum in 6 cijfers samenstellen
        $gebruikersnaam = $voornaamzuiver + "." + $achternaamzuiver
    $gebruikersnaam = $gebruikersnaam.ToLower()
    return $gebruikersnaam
}

function Set-LeerkrachtUITDienst {
    # script om een leerkracht uit dienst te zetten
        # Wordt in de AD verplaatst naar OU LeerkrachtenUitDienst
        # Wordt in de AD uit de groep leerkrachten gehaald
        # Wordt in de AD aan de groep leerkrachten_uit_dienst toegevoegd
        # Wordt "disabled" gezet (in O365 komt dan automatisch "sign-in blocked")
    param(
        $gebruikersnaam
    )
    $nieuweOU = "OU=LeerkrachtenUitDienst,OU=OULeerkrachten,OU=OUAzureAD,DC=xxx,DC=lok"
    $groepuitdienst = "leerkrachten_uit_dienst"
    $groep = "Leerkrachten"
    
    $gebruiker = Get-ADUser -Identity $gebruikersnaam -Properties CanonicalName         #SAMAccountName opvragen uit de AD
    Move-ADObject  -Identity $gebruiker.DistinguishedName -TargetPath $nieuweOU         #gebruiker naar $nieuweOU verplaatsen
    Add-ADGroupMember -Identity $groepuitdienst -Members $gebruikersnaam                #gebruiker toevoegen aan leerkrachten_uit_dienst groep
    Remove-ADGroupMember -Identity $groep -Members $gebruikersnaam -Confirm:$false      #gebruiker verwijderen uit de leerkrachten groep
    Disable-ADAccount -Identity $gebruikersnaam                                         #account van de gebruiker uitschakelen
}

function Set-LeerkrachtINDienst {
    # script om een leerkracht in dienst te zetten
    # Wordt in de AD verplaatst naar OU Leerkrachten
    # Wordt in de AD uit de groep leerkrachten_uit_dienst gehaald
    # Wordt in de AD aan de groep leerkrachten toegevoegd
    # Wordt "enabled" gezet 
    param(
        $gebruikersnaam
    )
    $nieuweOU = "OU=OULeerkrachten,OU=OUAzureAD,DC=kaso,DC=lok"
    $groepuitdienst = "leerkrachten_uit_dienst"
    $groep = "Leerkrachten"
    
    $gebruiker = Get-ADUser -Identity $gebruikersnaam -Properties CanonicalName         #SAMAccountName opvragen uit de AD
    Move-ADObject  -Identity $gebruiker.DistinguishedName -TargetPath $nieuweOU         #gebruiker naar $nieuweOU verplaatsen
    Add-ADGroupMember -Identity $groep -Members $gebruikersnaam                #gebruiker toevoegen aan leerkrachten_uit_dienst groep
    Remove-ADGroupMember -Identity $groepuitdienst -Members $gebruikersnaam -Confirm:$false      #gebruiker verwijderen uit de leerkrachten groep
    Enable-ADAccount -Identity $gebruikersnaam                                         #account van de gebruiker uitschakelen
}

Function getLeerlingAD($username) {
    Get-ADUser -LDAPFilter "(name=$username)" -Properties *
}

function Get-FileServerKlas($klas) {
    # deze functie geeft de fileserver voor een bepaalde klas
    $fslln1 = "WT3","WT4","WT5"
    $fslln2 = "EM3","EM4","EM5","EM6","EM7","TC3","TC4","TC5","TC6","WM3","WM4","WM5"
    $fslln3 = "WT6","WT7","WM6","WM7","WTH","WTM"
    $belangstellingsgebied = $klas.Substring(0,3)
    if ($belangstellingsgebied -in $fslln3) {
        $fileserver = "FS-LLN-3"}
        else {
            if ($belangstellingsgebied -in $fslln2) {
                $fileserver = "FS-LLN-2"
                }
                else {$fileserver = "FS-LLN-1"}
        }
        return $fileserver
}

function Set-WijzigKlas {
    # script om een klaswijziging te doen
    param(
        $gebruikersnaam,
        $oudeklas,
        $nieuweklas
    )
    $oudeklasjaarwoord = Get-KlasJaar $oudeklas
    $nieuweklasjaarwoord = Get-KlasJaar $nieuweklas
    $gebruiker = Get-ADUser -Identity $gebruikersnaam -Properties CanonicalName
    $oudeOU = ($gebruiker.DistinguishedName -split ",",2)[1]
    $servernieuw = Get-FileServerKlas $nieuweklas
    $serveroud = Get-FileServerKlas $oudeklas

    # settings in de properties van de leerling aanpassen (in de AD)
    Set-ADUser  -identity $gebruikersnaam -Department $nieuweklas `
                -HomeDirectory \\$servernieuw\homedirs\$nieuweklasjaarwoord\$nieuweklas\$gebruikersnaam
    
    # leerling verplaatsen naar nieuwe OU en groep
        $nieuweOU = "OU=$nieuweklas,OU=$nieuweklasjaarwoord,OU=OULeerlingen,OU=OUAzureAD,DC=kaso,DC=lok"
        Move-ADObject  -Identity $gebruiker.DistinguishedName -TargetPath $nieuweOU  
        Add-ADGroupMember -Identity $nieuweklas -Members $gebruikersnaam
        Remove-ADGroupMember -Identity $oudeklas -Members $gebruikersnaam -Confirm:$false
    
    #homedir kopieren naar nieuwe lokatie 
        Copy-Item -Path \\$serveroud\homedirs\$oudeklasjaarwoord\$oudeklas\$gebruikersnaam -Destination \\$servernieuw\homedirs\$nieuweklasjaarwoord\$nieuweklas\ -Recurse
        get-acl -path \\$serveroud\homedirs\$oudeklasjaarwoord\$oudeklas\$gebruikersnaam | set-acl -path \\$servernieuw\homedirs\$nieuweklasjaarwoord\$nieuweklas\$gebruikersnaam
        Rename-Item \\$serveroud\homedirs\$oudeklasjaarwoord\$oudeklas\$gebruikersnaam \\$serveroud\homedirs\$oudeklasjaarwoord\$oudeklas\$gebruikersnaam.klaswijz
}

function NieuweLeerlingAanmaken{
    param(
        $voornaam,
        $achternaam,
        $gebruikersnaam,
        $klas,
        $wachtwoord
    )
    $server = Get-FileServerKlas $klas
    $klasjaarwoord = Get-KlasJaar $klas

    $SecurePassword=ConvertTo-SecureString $wachtwoord -asplaintext -force

    # gebruiker aanmaken in de AD ZONDER profielpad
    New-ADUser -Name $gebruikersnaam -AccountPassword $securepassword -ChangePasswordAtLogon 0 -Department $klas `
            -DisplayName "$voornaam $achternaam" -EmailAddress $gebruikersnaam@leerling.mosa-rt.be -Enabled 1 -GivenName $voornaam `
            -HomeDirectory \\$server\homedirs\$klasjaarwoord\$klas\$gebruikersnaam -HomeDrive U: -PasswordNeverExpires 1 `
            -Path "OU=$klas,OU=$klasjaarwoord,OU=OULeerlingen,OU=OUAzureAD,DC=kaso,DC=lok" `
            -SamAccountName $gebruikersnaam -Surname $achternaam -UserPrincipalName $gebruikersnaam@leerling.mosa-rt.be

    # gebruiker toevoegen aan klasgroep en de groep "Leerlingen"
        Add-ADGroupMember -Identity $klas -Members $gebruikersnaam
        Add-ADGroupMember -Identity Leerlingen -Members $gebruikersnaam

     # homedir maken
        if (!(test-path -path "\\$server\homedirs\$klasjaarwoord\$klas\$gebruikersnaam"))
            {
            New-Item \\$server\homedirs\$klasjaarwoord\$klas\$gebruikersnaam -type directory
            # rechten op homedir instellen
            $acl = get-acl \\$server\homedirs\$klasjaarwoord\$klas\$gebruikersnaam
            $accessrule = new-object system.Security.AccessControl.FileSystemAccessRule("domein\$gebruikersnaam","Modify","ContainerInherit, ObjectInherit","None","Allow")
            $acl.SetAccessRule($AccessRule)
            $acl | set-acl \\$server\homedirs\$klasjaarwoord\$klas\$gebruikersnaam\
            }
            else {write-warning "De homedir voor $gebruikersnaam bestaat al"}

}

function MaakKlas{
    param(
    $klas
    )
    $klasjaarwoord = Get-KlasJaar $klas
    New-ADGroup -Name $klas -GroupCategory Security -GroupScope Global -Path "OU=OUGroepen,OU=OUAzureAD,DC=kaso,DC=lok"
    New-ADOrganizationalUnit -Name $klas -Path "OU=$klasjaarwoord,OU=OULeerlingen,OU=OUAzureAD,DC=kaso,DC=lok"
}

function VerstuurBerichtKlastitularis{
    param(
        $voornaam,
        $achternaam,
        $gebruikersnaam,
        $klas,
        $wachtwoord
    )
    # bericht versturen naar de klastitularissen Via berichten in Smartschool
            $eigentitle = "Leerling toegevoegd aan klas $klas" 
            $eigenbody = "De leerling $voornaam $achternaam is toegevoegd aan de klas. Gebruikersnaam is $gebruikersnaam en wachtwoord is $wachtwoord (voor computers, mail en Smartschool)"
            $eigenSenderidentifier = "smartschoolgebruiker"

    # Leestoegang tot Smartschool
            $accesscode = "accesscodevansmartschool"
            $urlSmartschool = "https://jouwschool.smartschool.be/Webservices/V3?wsdl"
            $proxy = New-WebServiceProxy -Uri $urlSmartschool

    # alle klastitularissen inlezen, true parameter voor alle klastitularissen van die klas
            $KlastitularissenJSON = $proxy.GetClassTeachers($accesscode,'true') 
            # output van klastitularissen converteren van JSON naar objecten
            $Klastitularissen = ConvertFrom-Json $KlastitularissenJSON
         
    # bericht naar iedere klastitularis sturen
            foreach ($i in $Klastitularissen) {
                if ($i.klasnaam -eq $klas){
                $klastitularis = $i.gebruikersnaam
                $proxy.sendMsg($accesscode,$klastitularis,$eigentitle,$eigenbody,$eigenSenderidentifier,0,0,0)
                }
            }  
    

}