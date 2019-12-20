<#
Dit script maakt van een CSV bestand een aangifte van stagiairs voor Dimona klaar
CSV moet volgende kolommen bevatten, gescheiden door komma's:
StartingDate
EndingDate
INSS

De rest van de velden is vast (RSZ nummer, type STG, F2, ...)

Best wel datum en tijd van invoering nog aanpassen en eventueel de eerste regel met "xmlns:" erin

#>

$XMLfile = ".\" + ( get-date -format yyMMddhhmmss) + "_dimona.XML"
$formcreationdate = "2019-12-20"
$formcreationhour = "14:35:00.000"
$onsRSZnummer = "RSZNUMMER"

$csv = read-host "Geef de naam van het importbestand (inclusief .csv extensie)"
$XMLlijnen = Import-csv $csv -encoding UTF7


Add-content $XMLfile -value '<Dimona xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="Dimona_20193.xsd">'

<#
Add-Content $XMLfile -value "    <Reference>"
Add-Content $XMLfile -value "      <ReferenceType>1</ReferenceType>"
Add-Content $XMLfile -value "      <ReferenceOrigin>1</ReferenceOrigin>"
Add-Content $XMLfile -value "      <ReferenceNbr></ReferenceNbr>"
Add-Content $XMLfile -value "    </Reference>"
#>

foreach ($lijn in $XMLlijnen) {
    $startingdate = $lijn.StartingDate
    $endingdate = $lijn.EndingDate
    $inss = $lijn.INSS
    #$ActivityWithRisk = $lijn.ActivityWithRisk

    Add-Content $XMLfile -value "  <Form>"
    Add-Content $XMLfile -value "    <Identification>DIMONA</Identification>"
    Add-Content $XMLfile -value "    <FormCreationDate>$formcreationdate</FormCreationDate>"
    Add-Content $XMLfile -value "    <FormCreationHour>$formcreationhour</FormCreationHour>"
    Add-Content $XMLfile -value "    <AttestationStatus>0</AttestationStatus>"
    Add-Content $XMLfile -value "    <TypeForm>SU</TypeForm>"
    Add-Content $XMLfile -value "    <DimonaIn>"
    Add-Content $XMLfile -value "      <StartingDate>$StartingDate</StartingDate>"
    Add-Content $XMLfile -value "      <EndingDate>$EndingDate</EndingDate>"
    Add-Content $XMLfile -value "      <EmployerId>"
    Add-Content $XMLfile -value "        <NOSSRegistrationNbr>$onsRSZnummer</NOSSRegistrationNbr>"
    Add-Content $XMLfile -value "      </EmployerId>"
    Add-Content $XMLfile -value "      <NaturalPerson>"
    Add-Content $XMLfile -value "        <INSS>$INSS</INSS>"
    Add-Content $XMLfile -value "      </NaturalPerson>"
    Add-Content $XMLfile -value "      <DimonaFeatures>"
    Add-content $XMLfile -Value "        <JointCommissionNbr>XXX</JointCommissionNbr>"
    Add-content $XMLfile -Value "        <WorkerType>STG</WorkerType>"
    Add-Content $XMLfile -value "      </DimonaFeatures>"
    Add-Content $XMLfile -value "      <SmallStatutesInformation>"
    Add-Content $XMLfile -value "        <EmploymentNature>EMPLOYEE</EmploymentNature>"
    #Add-Content $XMLfile -value "        <ActivityWithRisk>$ActivityWithRisk</ActivityWithRisk>"
    Add-Content $XMLfile -value "        <WorkerStatus>F2</WorkerStatus>"
    Add-Content $XMLfile -value "      </SmallStatutesInformation>"
    Add-Content $XMLfile -value "    </DimonaIn>"
    Add-Content $XMLfile -value "  </Form>"
}

Add-Content $XMLfile -value "</Dimona>"