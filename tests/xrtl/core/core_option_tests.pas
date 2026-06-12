program core_option_tests;

{$mode objfpc}{$H+}

uses
  xrtl_core;

type
  TStringOption = specialize TXrtlOption<string>;

procedure Expect(const Condition: Boolean; const Message: string);
begin
  if not Condition then
  begin
    WriteLn('fail: ', Message);
    Halt(1);
  end;
end;

var
  Missing: TStringOption;
  Present: TStringOption;
  SupportedCapability: TXrtlCapability;
  UnsupportedCapability: TXrtlCapability;
begin
  Missing := TStringOption.None;
  Expect(Missing.IsMissing, 'option missing');
  Expect(not Missing.HasValue, 'missing option has no value');
  Expect(Missing.Presence = xpMissing, 'missing option presence');

  Present := TStringOption.Some('configured');
  Expect(Present.HasValue, 'present option has value');
  Expect(not Present.IsMissing, 'present option not missing');
  Expect(Present.Presence = xpPresent, 'present option presence');
  Expect(Present.Value = 'configured', 'present option value');

  SupportedCapability := TXrtlCapability.Supported('database.sqlite');
  Expect(SupportedCapability.Name = 'database.sqlite', 'supported capability name');
  Expect(SupportedCapability.IsSupported, 'supported capability flag');
  Expect(not SupportedCapability.HasDetail, 'supported capability no detail');

  UnsupportedCapability := TXrtlCapability.Unsupported('database.firebird', 'driver not installed');
  Expect(UnsupportedCapability.Name = 'database.firebird', 'unsupported capability name');
  Expect(not UnsupportedCapability.IsSupported, 'unsupported capability flag');
  Expect(UnsupportedCapability.HasDetail, 'unsupported capability detail');
  Expect(UnsupportedCapability.Detail = 'driver not installed', 'unsupported capability detail text');
  Expect(UnsupportedCapability.DetailPresence = xpPresent, 'unsupported capability detail presence');

  WriteLn('ok: core_option_tests');
end.
