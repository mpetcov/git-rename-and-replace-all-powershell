# Git and File Rename & Replace Scripts

A collection of PowerShell scripts for batch renaming and content replacement in files and directories.

## Scripts Overview

### 1. ren-rep-git.ps1
Recursively renames files/directories and replaces content while maintaining Git history.
- Uses `git mv` for renaming operations
- Preserves Git history
- Skips binary files and .git directory

```powershell
.\ren-rep-git.ps1 -replaceString "oldtext" -replaceWith "newtext" -rootDir "path/to/dir-in-local-git-repo"
```

### 2. ren-rep-win.ps1
Performs the same operations using standard OS commands (no Git integration).
- Uses native PowerShell rename commands
- Works in any directory (no Git required)
- Skips binary files

```powershell
.\ren-rep-win.ps1 -replaceString "oldtext" -replaceWith "newtext" -rootDir "path/to/directory"
```

### 3. ren-rep-copy.ps1
Creates a copy of the source directory and performs replacements on the copy.
- Copies source directory to destination
- Performs replacements on the copied files
- Preserves original files untouched

```powershell
.\ren-rep-copy.ps1 -replaceString "oldtext" -replaceWith "newtext" -sourceDir "path/to/source" -destDir "path/to/destination"
```

## Common Features
- Recursive directory traversal
- Text content replacement
- File name replacement
- Directory name replacement
- Binary file detection and skipping
- Error handling and


## Known Issues // Future Improvments
- Case sensitivity has not been considered. 
- More configurations for filtering out files or directories based on name pattern or their extensions. This could get complicated if we do it right.
- The excluded binary files are currently hard-coded by extension: ```'.exe', '.dll', '.pdb', '.zip'``` (I commonly work with C# code.)




