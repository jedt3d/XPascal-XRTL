program xpc;

{$mode objfpc}{$H+}

uses
  Classes,
  SysUtils;

const
  XPascalVersion = '0.0.0-bootstrap';
  RequiredFpcVersion = '3.3.1';

function TargetOs: string;
begin
  {$IFDEF WINDOWS}
  Result := 'windows';
  {$ELSEIF DEFINED(DARWIN)}
  Result := 'macos';
  {$ELSEIF DEFINED(LINUX)}
  Result := 'linux';
  {$ELSE}
  Result := 'unknown';
  {$ENDIF}
end;

function TargetCpu: string;
begin
  {$IFDEF CPUX86_64}
  Result := 'x86_64';
  {$ELSEIF DEFINED(CPUAARCH64)}
  Result := 'aarch64';
  {$ELSEIF DEFINED(CPUI386)}
  Result := 'i386';
  {$ELSE}
  Result := 'unknown';
  {$ENDIF}
end;

function ShellQuote(const Value: string): string;
begin
  {$IFDEF WINDOWS}
  Result := '"' + StringReplace(Value, '"', '\"', [rfReplaceAll]) + '"';
  {$ELSE}
  Result := '''' + StringReplace(Value, '''', '''"''"''', [rfReplaceAll]) + '''';
  {$ENDIF}
end;

function CaptureCompilerVersion(out VersionText: string): Boolean;
var
  CompilerPath: string;
  CommandLine: string;
  ExitCode: LongInt;
  OutputPath: string;
  Lines: TStringList;
begin
  VersionText := '';
  CompilerPath := GetEnvironmentVariable('FPC_BIN');
  if CompilerPath = '' then
    CompilerPath := 'fpc';

  OutputPath := IncludeTrailingPathDelimiter(GetTempDir) +
    'xpc-fpc-version-' + IntToStr(GetProcessID) + '.txt';

  {$IFDEF WINDOWS}
  CommandLine := ShellQuote(CompilerPath) + ' -iV > ' + ShellQuote(OutputPath);
  ExitCode := ExecuteProcess('cmd.exe', ['/C', CommandLine]);
  {$ELSE}
  CommandLine := ShellQuote(CompilerPath) + ' -iV > ' + ShellQuote(OutputPath);
  ExitCode := ExecuteProcess('/bin/sh', ['-c', CommandLine]);
  {$ENDIF}

  Result := (ExitCode = 0) and FileExists(OutputPath);
  if Result then
  begin
    Lines := TStringList.Create;
    try
      Lines.LoadFromFile(OutputPath);
      if Lines.Count > 0 then
        VersionText := Trim(Lines[0]);
    finally
      Lines.Free;
    end;
    Result := VersionText <> '';
  end;

  if FileExists(OutputPath) then
    DeleteFile(OutputPath);
end;

procedure PrintVersion;
var
  FpcVersion: string;
begin
  WriteLn('XPascal/XRTL ', XPascalVersion);
  WriteLn('target: ', TargetOs, '-', TargetCpu);
  if CaptureCompilerVersion(FpcVersion) then
    WriteLn('fpc: ', FpcVersion)
  else
    WriteLn('fpc: not found');
end;

function Doctor: Integer;
var
  FpcVersion: string;
begin
  WriteLn('xpc doctor');
  WriteLn('target: ', TargetOs, '-', TargetCpu);

  if not CaptureCompilerVersion(FpcVersion) then
  begin
    WriteLn('fail: FreePascal was not found');
    WriteLn('hint: run tools/install-fpc for your platform or set FPC_BIN, then retry');
    Exit(1);
  end;

  WriteLn('fpc: ', FpcVersion);
  if FpcVersion <> RequiredFpcVersion then
  begin
    WriteLn('fail: expected fpc ', RequiredFpcVersion);
    Exit(1);
  end;

  WriteLn('ok: FreePascal toolchain is pinned to ', RequiredFpcVersion);
  Result := 0;
end;

procedure PrintHelp;
begin
  WriteLn('xpc - XPascal bootstrap CLI');
  WriteLn;
  WriteLn('Usage:');
  WriteLn('  xpc version');
  WriteLn('  xpc doctor');
  WriteLn('  xpc help');
end;

var
  Command: string;
begin
  if ParamCount = 0 then
  begin
    PrintHelp;
    Halt(0);
  end;

  Command := LowerCase(ParamStr(1));
  case Command of
    'version':
      begin
        PrintVersion;
        Halt(0);
      end;
    'doctor':
      Halt(Doctor);
    'help', '--help', '-h':
      begin
        PrintHelp;
        Halt(0);
      end;
    else
      begin
        WriteLn('unknown command: ', ParamStr(1));
        PrintHelp;
        Halt(64);
      end;
  end;
end.
