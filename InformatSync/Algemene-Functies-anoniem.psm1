Function LogWrite {
    Param ([string]$logstring)
    $stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    Add-content $logfile -value "$stamp - $logstring"
}