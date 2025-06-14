param(
    [Parameter(Mandatory=$true)]
    [string]$replaceString,
    
    [Parameter(Mandatory=$true)]
    [string]$replaceWith,
    
    [Parameter(Mandatory=$true)]
    [string]$rootDir
)

# Initialize variables
$searchString = if ([string]::IsNullOrWhiteSpace($replaceString)) { "TEMPLATE" } else { $replaceString }
$replacementString = if ([string]::IsNullOrWhiteSpace($replaceWith)) { "UPDATED-TEMPLATE" } else { $replaceWith }
$directory = if ([string]::IsNullOrWhiteSpace($rootDir)) {
    $PSScriptRoot
} else {
    if ([System.IO.Path]::IsPathRooted($rootDir)) {
        $rootDir
    } else {
        Join-Path $PSScriptRoot $rootDir
    }
}

# Validate directory exists
if (-not (Test-Path -Path $directory)) {
    Write-Error "Directory not found: $directory"
    exit 1
}


# Function to replace content in files
function Replace-FileContent {
    param($filePath)
    
    # Skip binary files
    if ((Get-Item $filePath).Extension -in @('.exe', '.dll', '.pdb', '.zip')) { return }
    
    try {
        $content = Get-Content $filePath -Raw -ErrorAction Stop
        if ($content -match $searchString) {
            $newContent = $content -replace $searchString, $replacementString
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
        $newName = $name -replace $searchString, $replacementString
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

# Verify directory exists
if (-not (Test-Path -Path $directory)) {
    Write-Error "Directory not found: $directory"
    exit 1
}

# Process all files first (content replacement)
Get-ChildItem -Path $directory -Recurse -File | ForEach-Object {
    Replace-FileContent $_.FullName
}

# Process files for renaming (bottom-up to handle nested paths)
Get-ChildItem -Path $directory -Recurse -File | 
    Sort-Object -Property FullName -Descending | 
    ForEach-Object {
        Rename-FSItem $_.FullName
    }

# Process directories for renaming (bottom-up to handle nested paths)
Get-ChildItem -Path $directory -Recurse -Directory | 
    Sort-Object -Property FullName -Descending | 
    ForEach-Object {
        Rename-FSItem $_.FullName
    }

Write-Host "Operation completed successfully"