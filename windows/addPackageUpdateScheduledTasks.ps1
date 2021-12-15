
function TaskExists ($name) { Get-ScheduledTask | Where-Object { $_.TaskName -like $name }}

$cargoTaskName = "Update Cargo Packages"
If(TaskExists($cargoTaskName)) {
    echo "Task '${cargoTaskName}' already exists, not creating"
} else {
    $action = New-ScheduledTaskAction -Execute (where.exe cargo) -Argument 'install-update --all'
    $trigger = New-ScheduledTaskTrigger -Daily -At 4am -RandomDelay (New-TimeSpan -Hours 1)
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $cargoTaskName
}

$scoopTaskName = "Update Scoop Packages"
If(TaskExists($scoopTaskName)) {
    echo "Task '${scoopTaskName}' already exists, not creating"
} else {
    $path = where.exe scoop | where { $_.endswith("cmd")}
    $action = New-ScheduledTaskAction -Execute $path -Argument 'update *'
    $trigger = New-ScheduledTaskTrigger -Daily -At 4am -RandomDelay (New-TimeSpan -Hours 1)
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $scoopTaskName
}


$scoopTaskName = "Update tldr"
If(TaskExists($scoopTaskName)) {
    echo "Task '${scoopTaskName}' already exists, not creating"
} else {
    $action = New-ScheduledTaskAction -Execute (where.exe tldr) -Argument '--update'
    $trigger = New-ScheduledTaskTrigger -Daily -At 4am -RandomDelay (New-TimeSpan -Hours 1)
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $scoopTaskName
}