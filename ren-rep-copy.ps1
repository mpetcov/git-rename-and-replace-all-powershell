param(
    [Parameter(Mandatory=$true)]
    [string]$replaceString,
    
    [Parameter(Mandatory=$true)]
    [string]$replaceWith,
    
    [Parameter(Mandatory=$true)]
    [string]$sourceDir,

    [Parameter(Mandatory=$true)]
    [string]$destDir
)

# Initialize variables with validation
$searchString = if ([string]::IsNullOrWhiteSpace($replaceString)) { "oldtext" } else { $replaceString }
$replacement = if ([string]::IsNullOrWhiteSpace($replaceWith)) { "newtext" } else { $replaceWith }

# Handle source directory path
$directory = if ([string]::IsNullOrWhiteSpace($sourceDir)) {
    $PSScriptRoot
} else {
    if ([System.IO.Path]::IsPathRooted($sourceDir)) {
        $sourceDir
    } else {
        Join-Path $PSScriptRoot $sourceDir
    }
}

# Handle destination directory path
$destinationPath = if ([System.IO.Path]::IsPathRooted($destDir)) {
    $destDir
} else {
    Join-Path $PSScriptRoot $destDir
}

# Create destination directory if it doesn't exist and ensure it's empty
if (Test-Path -Path $destinationPath) {
    Write-Host "Destination directory exists: $destinationPath"
    $choice = Read-Host "Directory exists. Do you want to clear it? (Y/N)"
    if ($choice -eq 'Y' -or $choice -eq 'y') {
        Remove-Item -Path "$destinationPath\*" -Recurse -Force
        Write-Host "Cleared destination directory"
    }
} else {
    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    Write-Host "Created new destination directory: $destinationPath"
}

# Function to replace content in files
function Replace-FileContent {
    param($filePath)
    
    # Skip binary files
    if ((Get-Item $filePath).Extension -in @('.exe', '.dll', '.pdb', '.zip')) { return }
    
    try {
        $content = Get-Content $filePath -Raw -ErrorAction Stop
        if ($content -match $searchString) {
            $newContent = $content -replace $searchString, $replacement
            Set-Content -Path $filePath -Value $newContent -NoNewline
            Write-Host "Updated content in: $filePath"
        }
    }
    catch {
        Write-Warning "Could not process file: $filePath"
    }
}

# Function to rename files and directories
function Rename-FSItem {
    param($path)
    
    $parent = Split-Path $path -Parent
    $name = Split-Path $path -Leaf
    
    if ($name -match $searchString) {
        $newName = $name -replace $searchString, $replacement
        $newPath = Join-Path $parent $newName
        
        try {
            Rename-Item -Path $path -NewName $newName -ErrorAction Stop
            Write-Host "Renamed: $path -> $newPath"
        }
        catch {
            Write-Warning "Could not rename: $path"
        }
    }
}

# Verify source directory exists
if (-not (Test-Path -Path $directory)) {
    Write-Error "Source directory not found: $directory"
    exit 1
}

# Create destination directory if it doesn't exist
if (-not (Test-Path -Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath -Force
    Write-Host "Created destination directory: $destinationPath"
}

# Copy all items to destination
Write-Host "Copying files to destination..."
Copy-Item -Path "$directory\*" -Destination $destinationPath -Recurse -Force

# Process all files in destination (content replacement)
Get-ChildItem -Path $destinationPath -Recurse -File | ForEach-Object {
    Replace-FileContent $_.FullName
}

# Process files for renaming (bottom-up)
Get-ChildItem -Path $destinationPath -Recurse -File | 
    Sort-Object -Property FullName -Descending | 
    ForEach-Object {
        Rename-FSItem $_.FullName
    }

# Process directories for renaming (bottom-up)
Get-ChildItem -Path $destinationPath -Recurse -Directory | 
    Sort-Object -Property FullName -Descending | 
    ForEach-Object {
        Rename-FSItem $_.FullName
    }

Write-Host "Operation completed successfully"