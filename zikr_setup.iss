[Setup]
AppName=জিকির (Zikr)
AppVersion=1.1.0
AppPublisher=Zikr Islamic Reminder
DefaultDirName={autopf}\Zikr
DefaultGroupName=Zikr
OutputDir=e:\ZIKR\build\installer
OutputBaseFilename=Zikr_Setup_v1.1
SetupIconFile=e:\ZIKR\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "e:\ZIKR\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\জিকির (Zikr)"; Filename: "{app}\zikr.exe"
Name: "{autodesktop}\জিকির (Zikr)"; Filename: "{app}\zikr.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\zikr.exe"; Description: "{cm:LaunchProgram,Zikr}"; Flags: nowait postinstall skipifsilent
