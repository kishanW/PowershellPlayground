#1: SETUP FILE DROP PATH
$global:outputFileDirectoryUrl = "C:\sitecore_poweshell"

#2: SETUP THE TEMPLARTES TO UPDATE SECURITY
$templatesToUpdate = @(
    {49181A09-7514-424B-BAA2-C7CF0551D2F7} 	#template1
    ,{49181A09-7514-424B-BAA2-C7CF0551D2F7} #template2
)

#3: NEW SECURITY TO APPEND
$newSecurityValue = "ar|sitecore\MiNonAdminUsrCntEdtr|pe|+item:read|pd|+item:read|"

#OTHER GLOBAL VARIABLES
$global:totalCount = [int] 0
$global:currentCount = [int] 0
$global:skippedItemCount = [int] 0
$global:shouldExport = [string] ""

#HELPER FUNCTIONS
function WriteExistingSecurityDetailsToCSV{
    $outputFilePrefix = Get-Date -format "yyyyMMdd-HHmmss"
    $outputFileName = "{0}_security_settings.csv" -f $outputFilePrefix
    
    #create directory to dump the file
    If(!(test-path $global:outputFileDirectoryUrl))
    {
        New-Item -Path $global:outputFileDirectoryUrl -ItemType directory -Force
    }
    
    $outputFilePath = "{0}\{1}" -f $global:outputFileDirectoryUrl,$outputFileName
    $results = @();
    
    $global:currentCount = 0
    $itemsToUpdate | ForEach-Object {
        $properties = @{
            ItemID = $_.ID
            Name = $_.Name
            Template = $_.TemplateName
            Path = $_.ItemPath
            OldSecurity = $_.Fields["__Security"].Value
            Skipped = (($_.Fields["__Security"].Value.ToLower()) -match ([RegEx]::Escape($newSecurityValue.ToLower())))
        }
        $results += New-Object psobject -Property $properties
        
        $global:currentCount = $global:currentCount + 1
        $percentCompleted = [int] (($global:currentCount/$global:totalCount)*100)
        
        $statusText = "{0} ({1})" -f $_.Name,$_.TemplateName
        $activityText = "Exporting Old Security [{0}%]" -f $percentCompleted
        Write-Progress -Activity $activityText -Status $statusText -PercentComplete $percentCompleted;
    }
    $Results | Select-Object ItemID,Skipped,Name,Template,OldSecurity | Export-Csv -notypeinformation -Path $outputFilePath
    Write-Host ("The exported CSV file is located at {0}. The file name is {1}" -f $global:outputFileDirectoryUrl,$outputFileName)
}


function UpdateItemSecurity{
    #UPDATE LOGIC
    $global:currentCount = 0
    
    $itemsToUpdate | ForEach-Object {
        $shouldSkip = (($_.Fields["__Security"].Value.ToLower()) -match ([RegEx]::Escape($newSecurityValue.ToLower())))
        If($shouldSkip)
        {
            $global:skippedItemCount = $global:skippedItemCount + 1
        }
        Else
        {
            $_.BeginEdit() | Out-Null
            $_.Fields["__Security"].Value = "{0}{1}" -f $_.Fields["__Security"].Value,$newSecurityValue
            $_.EndEdit() | Out-Null
        }
        
        $global:currentCount = $global:currentCount + 1
        $percentCompleted = [int] (($global:currentCount/$global:totalCount)*100)
        
        $statusText = "{0} ({1}) - [{2}/{3}]" -f $_.Name,$_.TemplateName,$global:currentCount,$global:totalCount
        $activityText = "Updating Security [{0}%]" -f $percentCompleted
        Write-Progress -Activity $activityText -Status $statusText -PercentComplete $percentCompleted;
    }
}

function GetShouldExportInput {
    Param ([string]$global:shouldExport=(Read-Host "Do you want to export the existing security values? (y/n)"))
}

#JOB - START
$stopwatch = new-object -type 'System.Diagnostics.Stopwatch'
$stopwatch.Start()

#GATHERING THE ITEMS
$itemsToUpdate = @(Get-ChildItem -Path "master:\sitecore\content\MIHomesCom\Home" -Recurse) |
    Where-Object { $templatesToUpdate -contains $_.TemplateId }
    
#GET THE TOTAL COUNT
$global:totalCount = ($itemsToUpdate | Measure-Object).Count

#GET USER INPUT FOR EXPORTING EXISTING SECURITY
GetShouldExportInput

#WRITE EXISTING SECURITY SETTINGS TO CSV FILE
If(($global:shouldExport.ToLower()) -like "y")
{
    WriteExistingSecurityDetailsToCSV
    Write-Host "Exporting to CSV completed at: " $stopwatch.Elapsed.ToString('dd\.hh\:mm\:ss') -ForegroundColor Green
}


#UPDATE SECURITY TO BY APPENDING NEW
$global:currentCount = 0
UpdateItemSecurity

#SECURITY UPDATE - END

#JOB - END
$stopwatch.Stop()
Write-Host "Total elapsed time: " $stopwatch.Elapsed.ToString('dd\.hh\:mm\:ss') -ForegroundColor Green 
Write-Host "Skipped Items" $global:skippedItemCount -ForegroundColor Yellow 
Write-Host "Total Items" $global:totalCount -ForegroundColor Green 