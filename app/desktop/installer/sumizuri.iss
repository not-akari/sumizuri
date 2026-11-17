; The setup of Sumizuri for Windows, which only shows a small window while it unpacks the app to a temporary folder, then starts the app's own setup and ends with it, installing nothing by itself.

; The packageReleaseSetup task passes AppVersion as the version, AppImage as the folder of the built app, and OutputDir as where the setup goes.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef AppImage
  #error AppImage must be given, as /DAppImage=folder
#endif
#ifndef OutputDir
  #define OutputDir "build"
#endif
; Windows takes only numbers for the version of the file, so a suffix such as -beta is left out there.
#define NumericVersion Copy(AppVersion, 1, Pos("-", AppVersion + "-") - 1)

[Setup]
AppId={{56C99E6E-9410-484E-A5FE-8E8C3BA0B470}
AppName=Sumizuri
AppVersion={#AppVersion}
AppPublisher=Sumizuri
VersionInfoVersion={#NumericVersion}
VersionInfoDescription=Sumizuri Setup
PrivilegesRequired=lowest
; Nothing is installed by this file, so it has no folder of its own and no uninstaller.
CreateAppDir=no
Uninstallable=no
CloseApplications=no
; A second copy of this setup, opened while one is running, says so and ends, so pressing Install or the file again never opens it twice.
SetupMutex=SumizuriSetup
ShowLanguageDialog=no
SetupArchitecture=x64
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#OutputDir}
OutputBaseFilename=Sumizuri-{#AppVersion}-setup
SetupIconFile=..\icons\app-icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
; An error message, the only other thing it can show, follows the light or dark of Windows.
WizardStyle=modern dynamic

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "ja"; MessagesFile: "compiler:Languages\Japanese.isl"

[CustomMessages]
en.Preparing=Getting the setup ready…
ja.Preparing=セットアップを準備しています…

[Files]
; The icon of the small window comes first, so it is out at once without unpacking the app before it.
Source: "art\splash-logo.png"; Flags: dontcopy
Source: "{#AppImage}\*"; DestDir: "{tmp}\payload"; Flags: dontcopy recursesubdirs createallsubdirs

[Code]
const
  // Asks Windows 11 to round the corners of the small window.
  DWMWA_WINDOW_CORNER_PREFERENCE = 33;
  DWMWCP_ROUND = 2;

function DwmSetWindowAttribute(Window: HWND; Attribute: DWORD; var Value: Integer; Size: DWORD): Integer;
  external 'DwmSetWindowAttribute@dwmapi.dll stdcall delayload';

// A label in the middle of the window, in the colors given.
function CenteredText(Form: TSetupForm; const Text: String; Top, Size: Integer; Bold: Boolean; Color: TColor): TNewStaticText;
begin
  Result := TNewStaticText.Create(Form);
  Result.Parent := Form;
  Result.AutoSize := True;
  Result.Font.Size := Size;
  Result.Font.Color := Color;
  if Bold then Result.Font.Style := [fsBold];
  Result.Caption := Text;
  Result.Top := Top;
  Result.Left := (Form.ClientWidth - Result.Width) div 2;
end;

// The small window shown while the app unpacks: the icon, the name and a line that the setup is getting ready, on the page color of the app in the light or dark of Windows.
function ShowSplash(): TSetupForm;
var
  Form: TSetupForm;
  Logo: TBitmapImage;
  Page, Ink, Quiet: TColor;
  Corner: Integer;
begin
  // Colors are written blue, green, red.
  if IsWinDark then
  begin
    Page := $1D1816;
    Ink := $E6EAEC;
    Quiet := $8F989B;
  end
  else
  begin
    Page := $ECF4F7;
    Ink := $241F1E;
    Quiet := $636B6E;
  end;
  Form := CreateCustomForm(ScaleX(340), ScaleY(220), False, False);
  Form.BorderStyle := bsNone;
  Form.Caption := 'Sumizuri';
  Form.Color := Page;
  Logo := TBitmapImage.Create(Form);
  Logo.Parent := Form;
  Logo.Width := ScaleX(80);
  Logo.Height := ScaleY(80);
  Logo.Left := (Form.ClientWidth - Logo.Width) div 2;
  Logo.Top := ScaleY(36);
  Logo.Stretch := True;
  Logo.BackColor := Page;
  Logo.PngImage.LoadFromFile(ExpandConstant('{tmp}\splash-logo.png'));
  CenteredText(Form, 'Sumizuri', ScaleY(128), 15, True, Ink);
  CenteredText(Form, CustomMessage('Preparing'), ScaleY(162), 9, False, Quiet);
  Form.Show;
  Corner := DWMWCP_ROUND;
  try
    DwmSetWindowAttribute(Form.Handle, DWMWA_WINDOW_CORNER_PREFERENCE, Corner, 4);
  except
  end;
  // Drawn now, as unpacking keeps the window busy until it is done.
  Form.Repaint;
  Result := Form;
end;

// Everything happens here, before any page of Inno Setup would show: the app is unpacked behind the small window and its own setup started, and when that closes this one ends without a page of its own.
function InitializeSetup(): Boolean;
var
  Splash: TSetupForm;
  Payload: String;
  Code: Integer;
begin
  Result := False;
  ExtractTemporaryFile('splash-logo.png');
  Splash := ShowSplash();
  try
    ExtractTemporaryFiles('{tmp}\payload\*');
    Payload := ExpandConstant('{tmp}\payload');
    // The setup of the app hides the small window by its handle once its own window has drawn.
    if not Exec(Payload + '\Sumizuri.exe', '--setup --splash=' + IntToStr(Splash.Handle), Payload, SW_SHOWNORMAL, ewWaitUntilTerminated, Code) then
    begin
      Splash.Hide;
      MsgBox(SysErrorMessage(Code), mbError, MB_OK);
    end;
  finally
    Splash.Free;
  end;
end;
