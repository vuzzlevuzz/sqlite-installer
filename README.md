# SQLite Installer

It always seems to take me forever to figure out how to install SQLite so I've whipped up some helper functions

This is currently hard coded to install v 1.0.113.0

## Usage
Dot source the file
```
. .\sqlite-installer.ps1
```

Then run the relevant commands

| command | effect |
|---------|--------|
| Import-Sqlite | Installs Sqlite 1.0.113.0 if not already installed |
| Uninstall-Sqlite | Uninstalls Sqlite if installed |