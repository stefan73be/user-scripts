# Met dit script maak je een nieuwe klas aan in de AD

$klas = read-host "Geef de klasnaam volledig (vb WT5EM3)"

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

# groep aanmaken in de AD
New-ADGroup -Name $klas -GroupCategory Security -GroupScope Global -Path "OU=OUGroepen,OU=OUAzureAD,DC=domein,DC=lok"

#OU aanmaken voor de klas
New-ADOrganizationalUnit -Name $klas -Path "OU=$klasjaarwoord,OU=OULeerlingen,OU=OUAzureAD,DC=domein,DC=lok"