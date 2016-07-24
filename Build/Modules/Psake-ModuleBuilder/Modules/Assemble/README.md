Assemble
========

A PowerShell Module for building modules and packages from source (.ps1) scripts.

Exported Commands
-----------------

### Invoke-ScriptBuild

`Invoke-ScriptBuild -Name [-SourcePath <Path>] [-TargetPath <Path>] [-DependenciesToValidate] [-Force] [-Exclude <String[]>] [-Flags <String[]>]`

**Name**

Name of the module to build. This will determine the 'psd1' and 'psm1' file names.

**SourcePath**

Optional. Path to the directory that contains the source files for the module,
e.g. '.\Scripts'. If not specified, the current directory is used.

**TargetPath**

Optional. Path to the directory where the completed module will be copied. If
not specified, the current directory is used.

**DependenciesToValidate**

Optional. The names of dependent modules to validate. If a module with the specified name
has not already been imported, attempts to import the module from a global
location (i.e. PSModulePath).

**Force**

Optional. If the target module file(s) already exist, overwrite it with the result.

**Exclude**

Optional. A list of files (or wildcard patterns) in the source directory to exclude.

**Flags**

Optional. Flags used by preprocessor.
