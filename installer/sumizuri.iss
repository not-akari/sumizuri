; Inno Setup script that builds one setup.exe from the Windows release build.
; Compile with ISCC installer\sumizuri.iss, or let build_all.bat do it.

#define MyAppName "Sumizuri"
; build_all.bat passes the real version from pubspec.yaml with /DMyAppVersion=...
#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif
#define MyAppExeName "sumizuri.exe"
#define ReleaseDir "..\build\windows\x64\runner\Release"

[Setup]
AppId={{8F2C9E1A-4B3D-4A7E-9C2F-6D1A5E8B3C90}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
; Installs for the current user, so in-app updates are silent. The setup offers all users.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
DefaultDirName={autopf}\{#MyAppName}
; Closes a running copy before replacing its files, so upgrading in place just works.
CloseApplications=yes
RestartApplications=no
DefaultGroupName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
OutputDir=..\build\dist
OutputBaseFilename=sumizuri-setup
Compression=lzma2
SolidCompression=yes
SetupIconFile=..\windows\runner\resources\app_icon.ico
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"

[Files]
; Everything except the .exp and .lib files, which are only needed when linking.
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Excludes: "*.exp,*.lib"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
; Lets a link like sumizuri://add-repo?url=... open the app, see docs/repository.md.
Root: HKA; Subkey: "Software\Classes\sumizuri"; ValueType: string; ValueName: ""; ValueData: "URL:Sumizuri"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\sumizuri"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKA; Subkey: "Software\Classes\sumizuri\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
; A silent install is an in-app update, so start the new version straight away.
Filename: "{app}\{#MyAppExeName}"; Flags: nowait; Check: WizardSilent
