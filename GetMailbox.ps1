###########################################################
##
##     Setup Connections
##
###########################################################

if (!$UserCredential) {$UserCredential = Get-Credential;}

#Check for O365 Connection and connect
$ActiveSession = Get-PSSession | select ComputerName

if ($ActiveSession -like '*ComputerName=outlook.office365.com*') { Write-Host 'Session Connected'  }  
else { 
  $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
  Import-PSSession $Session -DisableNameChecking 
      }

###########################################################
##
##     Get Mailboxes
##
###########################################################

$GetMailboxes = get-mailbox -ResultSize 1000 | select GUID ,Id ,UserPrincipalName,DisplayName ,ISMAILBOXENABLED ,ISSOFTDELETEDBYDISABLE ,ISSOFTDELETEDBYREMOVE ,ISVALID ,PRIMARYSMTPADDRESS ,RESETPASSWORDONNEXTLOGON,WHENCHANGED ,WHENCREATED,WHENMAILBOXCREATED,WHENSOFTDELETED 
$c = 1 

foreach ($mailbox in $GetMailboxes)
{
    Write-Progress -Activity "Inserting User $($_.DisplayName)" -Status "User $c of $($GetMailboxes.Count)" -PercentComplete (($c / $GetMailboxes.Count) * 100)
$GetMailboxStats=get-mailbox -Identity $mailbox.DisplayName | Get-MailboxStatistics | select OwnerADGuid, DISPLAYNAME, ISQUARANTINED, LASTLOGOFFTIME, LASTLOGONTIME, SYSTEMMESSAGECOUNT, TOTALITEMSIZE

$UID =$mailbox.GUID
$SID = $mailbox.Id
$UPN =$mailbox.UserPrincipalName
$DN = $mailbox.DisplayName
$IME = $mailbox.IsMailboxEnabled
$ISD = $mailbox.IsSoftDeletedByDisable
$ISDB = $mailbox.IsSoftDeletedByRemove
$IV = $mailbox.IsValid
$PSMTP = $mailbox.PrimarySmtpAddress
$RPONL = $mailbox.ResetPasswordOnNextLogon
$WCHD = $mailbox.WhenChanged
$WCD = $mailbox.WhenCreated
$WMBC = $mailbox.WhenMailboxCreated
$WSD = $mailbox.WhenSoftDeleted
$OGUID=$GetMailboxStats.OwnerADGuid
$IQ=$GetMailboxStats.IsQuarantined
$GMBS=$GetMailboxStats.LastLogoffTime
$LLT=$GetMailboxStats.LastLogonTime
$SMC=$GetMailboxStats.SystemMessageCount
$TIS=$GetMailboxStats.TotalItemSize


$MailboxQuery = "USE [DBName];
INSERT INTO [dbo].[TableName] 
([GUID],[Id],[UserPrincipalName],[DisplayName],[IsMailboxEnabled],[IsSoftDeletedByDisable],[IsSoftDeletedByRemove],[IsValid],[PrimarySmtpAddress],[ResetPasswordOnNextLogon],[WhenChanged],[WhenCreated],[WhenMailboxCreated],[WhenSoftDeleted],[OwnerADGuid],[IsQuarantined],[LastLogoffTime],[LastLogonTime],[SystemMessageCount],[TotalItemSize]) 
VALUES 
('$UID','$SID','$UPN','$DN','$IME','$ISD','$ISDB','$IV','$PSMTP','$RPONL','$WCHD','$WCD','$WMBC','$WSD','$OGUID','$IQ','$GMBS','$LLT','$SMC','$TIS')"

Invoke-Sqlcmd -ServerInstance 'cuvdbserver' -Query $MailboxQuery
$c++
}
