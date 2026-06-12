program xpc;

{$mode objfpc}{$H+}

uses
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

procedure PrintVersion;
var
  FpcVersion: string;
begin
  WriteLn('XPascal/XRTL ', XPascalVersion);
  WriteLn('target: ', TargetOs, '-', TargetCpu);
  FpcVersion := GetEnvironmentVariable('FPC_VERSION');
  if FpcVersion <> '' then
    WriteLn('fpc: ', FpcVersion)
  else
    WriteLn('fpc: not verified');
end;

function Doctor: Integer;
var
  FpcVersion: string;
begin
  WriteLn('xpc doctor');
  WriteLn('target: ', TargetOs, '-', TargetCpu);

  FpcVersion := GetEnvironmentVariable('FPC_VERSION');
  if FpcVersion = '' then
  begin
    WriteLn('fail: FreePascal version was not verified');
    WriteLn('hint: run xpc through tools/run-xpc after tools/check-toolchain');
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

function Build: Integer;
var
  FpcVersion: string;
begin
  WriteLn('xpc build');
  WriteLn('target: ', TargetOs, '-', TargetCpu);

  FpcVersion := GetEnvironmentVariable('FPC_VERSION');
  if FpcVersion = '' then
  begin
    WriteLn('fail: FreePascal version was not verified');
    WriteLn('hint: run xpc build through tools/run-xpc after tools/check-toolchain');
    Exit(1);
  end;

  WriteLn('fpc: ', FpcVersion);
  if FpcVersion <> RequiredFpcVersion then
  begin
    WriteLn('fail: expected fpc ', RequiredFpcVersion);
    Exit(1);
  end;

  WriteLn('fail: direct in-process build is not available in bootstrap CLI v0');
  WriteLn('hint: use tools/run-xpc build so the platform launcher can invoke the correct build script');
  Result := 1;
end;

procedure PrintHelp;
begin
  WriteLn('xpc - XPascal bootstrap CLI');
  WriteLn;
  WriteLn('Usage:');
  WriteLn('  xpc version');
  WriteLn('  xpc doctor');
  WriteLn('  xpc build');
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
    'build':
      Halt(Build);
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
