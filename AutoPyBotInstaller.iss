[Setup]
AppName=AutoPyBot
AppVersion=1.0
DefaultDirName={commonpf}\AutoPyBot
DefaultGroupName=AutoPyBot
OutputDir=Output
OutputBaseFilename=AutoPyBotSetup
Compression=lzma
SolidCompression=yes
UninstallDisplayIcon={app}\bootstrap.exe

[Files]
Source: "dist\bootstrap.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "Python-3.13.2-amd64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Run]
; 1. Install Python if not found or not the correct version
Filename: "{tmp}\Python-3.13.2-amd64.exe"; Parameters: "/passive InstallAllUsers=1 PrependPath=1"; StatusMsg: "Installing Python 3.13.2..."; Flags: waituntilterminated runhidden; Check: not IsPython313Installed

; 2. Run the application AFTER Python installation is complete
Filename: "{app}\bootstrap.exe"; Description: "Launch AutoPyBot"; Flags: nowait postinstall skipifsilent; Check: IsPython313InstalledAndFunctional

[Icons]
Name: "{group}\AutoPyBot - Launch AutoPyBot"; Filename: "{app}\bootstrap.exe"
Name: "{commondesktop}\AutoPyBot - Launch AutoPyBot"; Filename: "{app}\bootstrap.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Code]
function IsPython313Installed: Boolean;
var
  ErrorCode: Integer;
  PythonPath: String;
begin
  // Check if Python 3.13 is installed (search registry in both HKLM and HKCU)
  if RegQueryStringValue(HKLM, 'SOFTWARE\Python\PythonCore\3.13\InstallPath', '', PythonPath) then
    PythonPath := AddBackslash(PythonPath) + 'python.exe'
  else if RegQueryStringValue(HKCU, 'SOFTWARE\Python\PythonCore\3.13\InstallPath', '', PythonPath) then
    PythonPath := AddBackslash(PythonPath) + 'python.exe'
  else
  begin
    Result := False; // Python 3.13 not found
    Exit;
  end;

  // Verify that the found Python executable is functional
  Result := Exec(PythonPath, '-c "import sys"', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode) and (ErrorCode = 0);
end;

function IsPython313InstalledAndFunctional: Boolean;
var
  ErrorCode: Integer;
  PythonPath: String;
begin
  // Retrieve the Python install path for version 3.13 from the registry (check both HKLM and HKCU)
  if RegQueryStringValue(HKLM, 'SOFTWARE\Python\PythonCore\3.13\InstallPath', '', PythonPath) then
    PythonPath := AddBackslash(PythonPath) + 'python.exe'
  else if RegQueryStringValue(HKCU, 'SOFTWARE\Python\PythonCore\3.13\InstallPath', '', PythonPath) then
    PythonPath := AddBackslash(PythonPath) + 'python.exe'
  else
  begin
    Result := False; // Python 3.13 not found in the registry
    Exit;
  end;

  // Execute a simple command to ensure Python is functional
  Result := Exec(PythonPath, '-c "import sys"', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode) and (ErrorCode = 0);
end;

procedure InitializeWizard();
begin
  try
    CreateDir(ExpandConstant('{commonpf}\AutoPyBot\logs'));
    CreateDir(ExpandConstant('{userdocs}\AutoPyBot\logs'));
  except
    MsgBox('Error creating directory. Installation may continue but some features may not work.', mbError, MB_OK);
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  // (Optional) Additional logging can be added here if needed.
end;
