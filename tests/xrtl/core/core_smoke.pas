program core_smoke;

{$mode objfpc}{$H+}

uses
  xrtl_core;

type
  TIntegerOption = specialize TXrtlOption<Integer>;

procedure Expect(const Condition: Boolean; const Message: string);
begin
  if not Condition then
  begin
    WriteLn('fail: ', Message);
    Halt(1);
  end;
end;

var
  Option: TIntegerOption;
begin
  Expect(XRTL_CORE_LIBRARY_NAME = 'XRTL.Core', 'library name');
  Expect(XRTL_CORE_CONTRACT_VERSION = 1, 'contract version');
  Expect(XrtlStatusOk(xsOk), 'status ok helper');
  Expect(XrtlStatusFailed(xsError), 'status failure helper');
  Expect(XrtlPresenceHasValue(xpPresent), 'presence helper');

  Option := TIntegerOption.Some(42);
  Expect(Option.HasValue, 'generic option has value');
  Expect(Option.Value = 42, 'generic option value');

  WriteLn('ok: core_smoke');
end.
