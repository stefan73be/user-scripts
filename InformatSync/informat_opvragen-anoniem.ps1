 param (
    [switch]$ResetPassword = $false,
    [switch]$berichtnaarklastit = $false
 )

import-module ".\AD-functies.psm1" -force
import-module ".\Algemene-Functies.psm1" -Force

$logfile = "c:\log\" + ( get-date -format yyMMddhhmmss) + "_InformatToAD.log"

<#
schoolnummer = 
#>

# Login account om de webservice van Informat te kunnen aanspreken
$login = "accountvoorwebserviceinformat"
#Wachtwoord van bovenstaand account
$paswoord = "wachtwoordwebserviceinformat"
#Schooljaar waar je de leerlingen wil van ophalen
$schooljaar = "2019-20"
#Instellingsnummer van de school
$instelnr = "schoolnummer1","schoolnummer2","schoolnummer3","schoolnummer4","schoolnummer5"
#Referentiedatum, meer precieze resultaten kun je bekomen door de datum van vandaag te gebruiken
$datum = "01/09/2019"
#hoofdstructuur; meestal 311
$hoofdstructuur = "311"
 
$urlInfVKSO       = "http://webservice.informatsoftware.be/wsInfSoftVkso.asmx"

foreach ($school in $instelnr) {

$proxy = New-WebServiceProxy -Uri $urlInfVKSO
$ds = $proxy.LeerlingenNaDatum($login, $paswoord, $school, $datum, $schooljaar)

$leerlingen_idem = 0
$leerlingen_nieuw = 0
$leerlingen_update = 0
$totaalleerlingen = 0

LogWrite "=== START IMPORT INFORMAT TO AD ==="
LogWrite "Logfile          : $logfile"
LogWrite "Schooljaar       : $schooljaar"
LogWrite "Schoolnummer     : $school"

LogWrite "LEERLINGEN VERWERKEN UIT INFORMAT"
LogWrite "=============================================="

foreach ($row in $ds.Tables["Table1"]) {
      
      $username = $row.gebruikersnaamSmartschool
      $klas = $row.klascode
      $klas = $klas.replace(" ", '')
      $wachtwoord = $row.wachtwoordSmartschool
      $voornaam = set-verwijderaccenten $row.voornaam
      $voornaam = Set-VerwijderTekens $voornaam
      $achternaam = Set-VerwijderAccenten $row.naam
      $achternaam = Set-VerwijderTekens $achternaam
      $uniekeID = $row.p_persoon
      
      # controleren of de klas bestaat, anders aanmaken
      if (!(Get-ADGroup -F {Name -eq $klas})){
            LogWrite "De klas $klas is nieuw en wordt aangemaakt."
            Maakklas $klas
            }

      #Wanneer er geen username/wachtwoord is ingevuld in Informat -> error voor leerlingen geven in error_informat.log  
      if (([DBNull]::Value).Equals($username)) { LogWrite "$row heeft geen gebruikersnaam in Informat" }
      else {
            $totaalleerlingen++
            $user = getLeerlingAD($username)
            $huidigeklas = $user.department
            
            #Leerling bestaat nog niet in AD -> aanmaken
            if ( -not $user) { 
                  LogWrite "GEBRUIKER NIEUW: $username - $klas - $wachtwoord"
                  <#            
                  Write-Host "Nieuwe leerling wordt NIET automatisch aangemaakt:"
                  Write-Host "Voornaam: $voornaam"
                  Write-Host "Achternaam: $achternaam"
                  Write-Host "Gebruikersnaam: $username"
                  Write-Host "Klas: $klas"
                  Write-Host "Wachtwoord: $wachtwoord"
                  Write-Host "Unieke ID: $uniekeID"
                  Write-Host "------------------------------------------"
                  #>
                  NieuweLeerlingAanmaken $voornaam $achternaam $username $klas $wachtwoord
                  $leerlingen_nieuw++
                  if ($berichtnaarklastit){VerstuurBerichtKlastitularis $voornaam $achternaam $username $klas $wachtwoord}
            }
            
            else { 
                  if ($user.department -eq $klas) {
                        # LogWrite "GEBRUIKER BESTAAT: $username - $huidigeklas blijft $klas - $wachtwoord"
                        $leerlingen_idem++
                  }
                  else {
                        LogWrite "GEBRUIKER UPDATE: $username - van $huidigeklas naar $klas - $wachtwoord"
                        Set-WijzigKlas $username $huidigeklas $klas
                        $leerlingen_update++
                  }
                  if ($ResetPassword) {
                        LogWrite "     wachtwoord wijzigen van $username"
                        
                  }
            }
      }

}

LogWrite "TOTALEN"
LogWrite "======="
Logwrite "VERWERKTE LEERLINGEN: $totaalleerlingen"
Logwrite "NIEUWE LEERLINGEN   : $leerlingen_nieuw"
Logwrite "KLASWIJZIGING       : $leerlingen_update"
Logwrite "LEERLINGEN IDEM     : $leerlingen_idem"
LogWrite "=============================================="
LogWrite "=============================================="
LogWrite " "
LogWrite " "



}

$body = [IO.File]::ReadAllText($logfile)
Send-MailMessage -smtpserver uit.telenet.be -from "mailadresafzender" -to "mailadresontvanger" -Subject "[CAMPUS] Import Informat - resultaat import leerlingen" -Body $body