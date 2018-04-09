#1 THE ITEM PATH TO DELETE
$global:pathToDelete = "";

#OTHER GLOBAL VARIABLES
$global:totalCount = [int] 0
$global:currentCount = [int] 0

#HELPER FUNCTIONS
function DeleteItems{
    #UPDATE LOGIC
    $global:currentCount = 0
    
    $itemsToDelete | ForEach-Object {
        $global:currentCount = $global:currentCount + 1
        $percentCompleted = [int] (($global:currentCount / $global:totalCount) * 100)

        $statusText = "{0} ({1}) - [{2}/{3}]" -f $_.Name, $_.TemplateName, $global:currentCount, $global:totalCount
        $activityText = "Deleting Items [{0}%]" -f $percentCompleted
        Write-Progress -Activity $activityText -Status $statusText -PercentComplete $percentCompleted;

        Remove-Item -Path $_.ItemPath -Permanently -recurse
    }

    Remove-Item -Path $global:pathToDelete -Permanently -recurse
}

function GetPathToDelete {
    Param ([string]$global:pathToDelete=(Read-Host "Path to item you want to delete"))
}

#JOB - START
$stopwatch = new-object -type 'System.Diagnostics.Stopwatch'
$stopwatch.Start()

# GET THE ITEM PATH TO DELETE
GetPathToDelete

#GATHERING THE ITEMS
$itemsToDelete = @(Get-ChildItem -Path $global:pathToDelete -Recurse)
    
#GET THE TOTAL COUNT
$global:totalCount = ($itemsToDelete | Measure-Object).Count + 1

$global:currentCount = 0

#ITEM DELETE START
Write-Host "Total Items to be deleted: " $global:totalCount -ForegroundColor Red -BackgroundColor Yellow

DeleteItems

Write-Host "Item deletion complete." -ForegroundColor Red -BackgroundColor Yellow 
#ITEM DELETE END

#JOB - END
$stopwatch.Stop()
Write-Host "Total elapsed time: " $stopwatch.Elapsed.ToString('dd\.hh\:mm\:ss') -ForegroundColor Green 
