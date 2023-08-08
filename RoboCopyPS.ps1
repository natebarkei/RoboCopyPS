<#
RoboCopyPS.ps1
Copyright 2023 by Nate Barkei, MIT license
github.com/natebarkei/RoboCopyPS/
#>



<#
.SYNOPSIS
Copy all files from source root path to destination excluding things in specific folders
.NOTES
Here is a sample usage for migrating files from a remote computer to a local folder

Write-Host "Computer File Migration Script"
$ComputerName = Read-Host "Enter the name of the source computer: "
if([string]::IsNullOrWhiteSpace($ComputerName)){
    write-host "Migration canceled!"
}
else {
    [string]$RealName = '\\' + $ComputerName + '\C$\'
    RoboCopyPS -Source $RealName -Destination "C:\destination_folder" -ExcludedFolders @(
        "*\Windows",
        "*\ProgramData,
        "*\Dell"
    )

}

#>
function RoboCopyPS{
    [CmdletBinding()]
    param(
        [string]$Source,
        [string]$Destination,
        [array]$ExcludedFolders
    )


    function ProcessDirectory {
        param($Root, $Depth=0)
        foreach($folder in [System.IO.Directory]::EnumerateDirectories($Root)){
            Write-Progress -Activity "Migration" -Id 99 -Status "Examining Directory $folder"
            ## Validate that we aren't excluding it
            $ProcessFolder = $true
            foreach($e in $ExcludedFolders) { if($folder -like $e){$ProcessFolder=$false}}
            Write-Verbose "Working: $(' ' * $Depth)$folder [Process:$ProcessFolder]"
            Write-Output "Folder: $(' ' * $Depth)$folder [Process:$ProcessFolder]"
            if($ProcessFolder) {
                $DestinationFolder = join-path -path $Destination $($folder.Substring([System.io.path]::GetPathRoot($folder).Length))
                Write-Verbose "DestFolder: $DestinationFolder"
                #First copy any files that are in the folder
                try {
                    $FilesToCopy = [System.IO.Directory]::EnumerateFiles($folder)
                    if($FilesToCopy.Length -gt 0) {
                        if(!(Test-Path -Path $DestinationFolder)) {
                            # Create the directory
                            try {
                                $null = New-Item -ItemType Directory -Path $DestinationFolder -Force
                            }
                            catch{
                                Write-Error "Unable to create Directory: $_"
                            }

                        }
                    }
                    foreach($file in $FilesToCopy) {
                        Write-Progress -Activity "Migration" -Id 100 -Status "Copy $File" -ParentId 99
                        Write-Output "Copying $(' ' * $Depth)  $file ==> $DestinationFolder"
                        Write-Verbose "  Copy: $(' ' * $Depth) $File"
                        try {
                            $null = Copy-Item -Path $file -Destination $DestinationFolder -Force
                        }
                        catch {
                            Write-Error "Unable to copy File: $_"
                        }

                    }
                    ProcessDirectory $folder ($Depth+1)
                }
                catch {
                    Write-Warning "Unable to enumerate files in '$folder'  Error $_"
                }
            }
        }
    }

    ProcessDirectory($Source)

}
