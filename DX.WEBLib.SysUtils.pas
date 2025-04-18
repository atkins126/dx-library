﻿unit DX.WEBLib.SysUtils;

interface

uses
  System.Classes, System.SysUtils,
  Data.DB,
  JS, jsdelphisystem,
  web,

  WEBLib.Forms;

type
  TJSObjectHelper = class helper for TJSObject
    function ValueOfProperty(const APropertyName: string): string;
  end;

  TFormatSettingsHelper = record helper for TFormatSettings
    function NormalizedLocaleName: string;
  end;

  TJSConsoleHelper = class helper for TJSConsole
  public
    // Writes a log only if in debug mode
    procedure debug(Obj1: JSValue); reintroduce;
  end;

  TVersion = record
    Name: string;
    Major: integer;
    Minor: integer;
    Build: integer;
  end;

  /// <summary>TAppInfo returns the app's version information.
  /// Put this into the project's index.html file, just before rtl.run() :
  /// ProjectNameVersion="$(ProjectName)";  //Captures project name AND version
  /// </summary>
  TAppInfo = record
    class function AppName: string; static;
    class function BuildTimeStamp: TDateTime; static;
    class function Version: TVersion; static;
    class function VersionShort: string; static;
    class function VersionLong: string; static;

    /// <summary>
    /// Shows a fully formatted version string: "Version 1.0 Build: 20240701"
    /// </summary>
    class function VersionFull: string; static;

    class function IsPwa: Boolean; overload; static;
    class function IsPwa(ATrueMessage, AFalseMessage: string): string; overload; static;
    class function BaseURL: string; static;
  end;

  TPWAHelper = record
    class procedure Update; static;
    class procedure Install; static;
    class procedure InitializeInstaller; static;
  end;

function JSResponse(AValue: JSValue): TJSResponse;

function JSBlob(AValue: JSValue): TJSBlob;

procedure Assert(ACondition: Boolean);

implementation

uses
  WEBLib.TMSWEBUtils, DX.WEBLib.Logger;

function JSResponse(AValue: JSValue): TJSResponse;
begin
  result := TJSResponse(AValue);
end;

function JSBlob(AValue: JSValue): TJSBlob;
begin
  result := TJSBlob(AValue);
end;

function TJSObjectHelper.ValueOfProperty(const APropertyName: string): string;
begin
  result := string(self[APropertyName]);
end;

{ TFormatSettingsHelper }

function TFormatSettingsHelper.NormalizedLocaleName: string;
var
  s: string;
begin
{$IFDEF PAS2JS}
  asm
    s = Intl.DateTimeFormat().resolvedOptions().locale
  end;
{$ENDIF}
  result := s;
end;

{ TAppInfo }

class function TAppInfo.AppName: string;
begin
  result := Version.Name;
end;

class function TAppInfo.BaseURL: string;
var
  LOrigin: string;
  LPath: string;
  LPathSegments: TArray<string>;
  LNumberOfSegments: integer;
  i: integer;
begin
{$IFDEF PAS2JS}
  asm
    // http://example.com:8888
    LOrigin = window.location.origin;
    // /folder/index.html or /folder/
    LPath = window.location.pathname;
  end;
{$ENDIF}
  // First part of the URL
  result := LOrigin;

  // Add the path without a possible, trailing filename  (such as index.html)
  if not LPath.EndsWith('/') then
  begin
    // split LPath to find and remove the trailing filename
    LPathSegments := LPath.Split('/');

    // the last item is the filename, which we don't want
    LNumberOfSegments := Length(LPathSegments) - 1;

    for i := 0 to LNumberOfSegments - 1 do
    begin
      if LPathSegments[i] > '' then
      begin
        result := result + '/' + LPathSegments[i];
      end;
    end;
    // trailing "/" only if there is at least one folder/path segment
    if LNumberOfSegments > 0 then
    begin
      result := result + '/';
    end;
  end
  else
  begin
    result := result + LPath;
  end;
  Assert(result.EndsWith('/'));
end;

class function TAppInfo.BuildTimeStamp: TDateTime;
var
  LAppDate: string;
  LFormat: TFormatSettings;
begin
{$IFDEF PAS2JS}
  asm
    LAppDate = document.lastModified;
  end;
{$ENDIF}
  LFormat := TFormatSettings.Create('en-US');
  result := StrToDateTime(LAppDate, LFormat);
end;

class function TAppInfo.VersionFull: string;
begin
  result := Format('%s Version: %s Build: %s', [AppName, VersionLong, FormatDateTime('yyyymmddhhnnss', BuildTimeStamp)]);
end;

class function TAppInfo.VersionLong: string;
begin
  result := Format('%d.%d.%d', [Version.Major, Version.Minor, Version.Build]);
end;

class function TAppInfo.VersionShort: string;
begin
  result := Format('%d.%d', [Version.Major, Version.Minor]);
end;

class function TAppInfo.IsPwa(ATrueMessage, AFalseMessage: string): string;
begin
  if IsPwa then
  begin
    result := ATrueMessage;
  end
  else
  begin
    result := AFalseMessage;
  end;
end;

class function TAppInfo.IsPwa: Boolean;
var
  LStandalone: Boolean;
begin
  LStandalone := false;
  // We are trying TMS's method and our custom method to detect if we are running as installed PWA app.
{$IFDEF PAS2JS}
  asm
    if (window.matchMedia('(display-mode: standalone)').matches) {
    LStandalone = true;
     }
    // iOS only
    if (window.navigator.standalone === true) {
    LStandalone = true;
     }
  end;
{$ENDIF}
  result := LStandalone or Application.IsPwa;
end;

class function TAppInfo.Version: TVersion;
var
  LAppName: string;
  LAppVersion: string;
  LVersionPos: integer;
  LVersionParts: TArray<string>;
begin
  // Put this into the project's index.html file, just before rtl.run();
  // ProjectNameVersion="$(ProjectName)";  //Captures project name AND version

{$IFDEF PAS2JS}
  asm
    if (typeof ProjectNameVersion !== 'undefined') {
    LAppVersion = ProjectNameVersion;
    } else {
    LAppVersion = "WebApp_0_0_0";
    }
  end;
{$ENDIF}
  // LAppVersion = 'AppName_2_0_47'
  LVersionPos := Pos('_', LAppVersion);
  if LVersionPos = 0 then
  begin
    LAppVersion := 'UnknownApp_0_0_0'; // unexpected value in LAppVersion
  end;

  result := Default(TVersion); // 0.0.0

  //App Name
  result.Name := Copy(LAppVersion, 1, LVersionPos);

  //App Version
  LAppVersion := Copy(LAppVersion, LVersionPos + 1, Length(LAppVersion) - LVersionPos);
  LAppVersion := LAppVersion.Replace('_', '.');

  LVersionParts := LAppVersion.Split(['.']);
  if Length(LVersionParts) > 0 then
    result.Major := LVersionParts[0].ToInteger;
  if Length(LVersionParts) > 1 then
    result.Minor := LVersionParts[1].ToInteger;
  if Length(LVersionParts) > 2 then
    result.Build := LVersionParts[2].ToInteger;
end;

{ TJSConsoleHelper }

procedure TJSConsoleHelper.debug(Obj1: JSValue);
begin
{$IFDEF debug }
{$IFDEF PAS2JS}
  asm
    console.debug(Obj1);
  end;
{$ENDIF}
{$ENDIF }
end;

procedure Assert(ACondition: Boolean);
begin
{$IFDEF DEBUG}
  if not ACondition then
  begin
    DXLog('Assert failed');
    raise Exception.Create('Assert failed');
  end;
{$ENDIF}
end;

class procedure TPWAHelper.InitializeInstaller;
begin
{$IFDEF PAS2JS}
  asm
    window.addEventListener('beforeinstallprompt', (e) => {
    // Verhindern, dass das Mini-Infobar erscheint.
    e.preventDefault();
    // Das Ereignis speichern, um es später auszulösen.
    // Der Einfachheit halber nutzen wir hier das globale window-Objekt
    window.deferredPwaPrompt = e;
     });
  end;
{$ENDIF}
end;

class procedure TPWAHelper.Install;
var
  LSuccess: Boolean;
  LPwaPromptAvailable: Boolean;
begin
  LSuccess := false;
  LPwaPromptAvailable := true;
{$IFDEF PAS2JS}
  asm
    if (window.deferredPwaPrompt) {
    window.deferredPwaPrompt.prompt();
    window.deferredPwaPrompt.userChoice.then((choiceResult) => {
    if (choiceResult.outcome === 'accepted') {
    LSuccess = true;
     } else {
    LSuccess = false;
     }
    window.deferredPwaPrompt = null;
    })
    }  else {
    LPwaPromptAvailable = false;
     }
  end;
{$ENDIF }
  if not LPwaPromptAvailable then
  begin
    DXLog(
      'App ist bereits installiert oder PWA Installation nicht verfügbar');
  end
  else
  begin
    if LSuccess then
    begin
      DXLog('Benutzer hat die Installation akzeptiert');
    end
    else
    begin
      DXLog('Benutzer hat die Installation abgelehnt');
    end;
  end;
end;

class
  procedure TPWAHelper.Update;
  begin
{$IFDEF PAS2JS}
    asm
    // Taken from here:
    // https://forum.quasar-framework.org/topic/2560/solved-pwa-force-refresh-when-new-version-released/38
    if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations().then(function (registrations) {
    for (let registration of registrations) {
    registration.update()
     }
    })
    }
    window.location.reload(true);
    end;
{$ENDIF}
  end;

initialization TPWAHelper.InitializeInstaller;
end.

