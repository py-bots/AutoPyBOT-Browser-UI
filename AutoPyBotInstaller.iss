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
Source: "7z.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "MinGit-2.48.1-64-bit.zip"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Run]
Filename: "{tmp}\Python-3.13.2-amd64.exe"; Parameters: "/passive InstallAllUsers=1 PrependPath=1"; StatusMsg: "Installing Python 3.13.2..."; Flags: waituntilterminated runhidden; Check: not IsPython313Installed

Filename: "{app}\bootstrap.exe"; Description: "Launch AutoPyBot"; Flags: nowait postinstall skipifsilent; Check: IsPython313InstalledAndFunctional

[Icons]
Name: "{group}\AutoPyBot - Launch AutoPyBot"; Filename: "{app}\bootstrap.exe"
Name: "{commondesktop}\AutoPyBot - Launch AutoPyBot"; Filename: "{app}\bootstrap.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Code]
const
    MinGitInstallDir = '{app}\MinGit';
    GitExecutablePath = '{app}\MinGit\cmd\git.exe';
    SevenZipExePath = '{tmp}\7z.exe';
    MinGitZipPath = '{tmp}\MinGit-2.48.1-64-bit.zip';

function IsGitInstalled: Boolean;
begin
    Result := FileExists(ExpandConstant(GitExecutablePath));
end;

procedure ExtractZip(ZipPath, DestDir: String);
var
    ErrorCode: Integer;
    CmdLine: String;
begin
    ForceDirectories(DestDir);
    CmdLine := '"' + ExpandConstant(SevenZipExePath) + '" x "' + ExpandConstant(ZipPath) + '" -o"' + ExpandConstant(DestDir) + '" -y';
    if not Exec(ExpandConstant('{cmd}'), '/c ' + CmdLine, '', SW_HIDE, ewWaitUntilTerminated, ErrorCode) then
    begin
        MsgBox('MinGit extraction failed. Error Code: ' + IntToStr(ErrorCode), mbError, MB_OK);
        Abort;
    end;
end;

procedure MoveFiles(Source, Destination: String);
var
    FindRec: TFindRec;
begin
    if not DirExists(Source) then Exit;
    ForceDirectories(Destination);
    if FindFirst(Source + '\*', FindRec) then
    begin
        repeat
            if (FindRec.Name <> '.') and (FindRec.Name <> '..') then
            begin
                if FindRec.Attributes and FILE_ATTRIBUTE_DIRECTORY <> 0 then
                    MoveFiles(Source + '\' + FindRec.Name, Destination + '\' + FindRec.Name)
                else
                    CopyFile(Source + '\' + FindRec.Name, Destination + '\' + FindRec.Name, False);
            end;
        until not FindNext(FindRec);
        FindClose(FindRec);
    end;
    RemoveDir(Source);
end;

procedure InstallGitIfNeeded();
var
    TempDir: String;
    MinGitSubdir: String; // To store the path to the MinGit subdirectory
begin
    if IsGitInstalled then Exit;

    TempDir := ExpandConstant('{tmp}\MinGitExtracted');
    ExtractZip(ExpandConstant(MinGitZipPath), TempDir);

    // *** KEY CHANGE: Determine the MinGit subdirectory ***
    // This assumes the ZIP extracts to a single subdirectory (e.g., MinGit)
    // You might need to adjust this if the structure is different
    MinGitSubdir := TempDir + '\MinGit';  // Most common structure. Adjust if needed.

    if DirExists(MinGitSubdir) then  // Check if the subdirectory exists
    begin
        MoveFiles(MinGitSubdir, ExpandConstant(MinGitInstallDir)); // Move from the subdirectory
    end
    else
    begin
        Log('MinGit subdirectory not found in archive.  Check the ZIP file structure.');
        MsgBox('MinGit installation failed. Check the setup log.', mbError, MB_OK);
        Abort;
    end;


    RemoveDir(TempDir); // Clean up the temporary directory

    if not IsGitInstalled then  // Check AFTER moving to the correct location
    begin
        MsgBox('MinGit installation failed. Git executable not found after moving.', mbError, MB_OK);
        Abort;
    end;
end;
function IsPython313Installed: Boolean;
var
    PythonPath: String;
begin
    Result := RegQueryStringValue(HKLM, 'SOFTWARE\Python\PythonCore\3.13\InstallPath', '', PythonPath) or
              RegQueryStringValue(HKCU, 'SOFTWARE\Python\PythonCore\3.13\InstallPath', '', PythonPath);
    if Result then PythonPath := AddBackslash(PythonPath) + 'python.exe';
    Result := FileExists(PythonPath);
end;

function IsPython313InstalledAndFunctional: Boolean;
var
    ErrorCode: Integer;
    PythonPath: String;
begin
    Result := RegQueryStringValue(HKLM, 'SOFTWARE\Python\PythonCore\3.13\InstallPath', '', PythonPath) or
              RegQueryStringValue(HKCU, 'SOFTWARE\Python\PythonCore\3.13\InstallPath', '', PythonPath);
    if not Result then Exit;
    PythonPath := AddBackslash(PythonPath) + 'python.exe';
    Result := Exec(PythonPath, '-c "import sys"', '', SW_HIDE, ewWaitUntilTerminated, ErrorCode) and (ErrorCode = 0);
end;
