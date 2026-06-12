program core_result_tests;

{$mode objfpc}{$H+}

uses
  xrtl_core;

type
  TStringValueResult = specialize TXrtlValueResult<string>;

procedure Expect(const Condition: Boolean; const Message: string);
begin
  if not Condition then
  begin
    WriteLn('fail: ', Message);
    Halt(1);
  end;
end;

var
  EmptyError: TXrtlError;
  ParseError: TXrtlError;
  SameIdentityError: TXrtlError;
  DifferentError: TXrtlError;
  ResultOk: TXrtlResult;
  ResultFail: TXrtlResult;
  ValueOk: TStringValueResult;
  ValueFail: TStringValueResult;
begin
  EmptyError := TXrtlError.None;
  Expect(EmptyError.IsEmpty, 'empty error identity');

  ParseError := TXrtlError.Create('xrtl.core', 'invalid_argument', 'name must not be empty');
  SameIdentityError := TXrtlError.Create('xrtl.core', 'invalid_argument', 'message may differ');
  DifferentError := TXrtlError.Create('xrtl.core', 'unsupported_capability', 'not available');

  Expect(ParseError.Domain = 'xrtl.core', 'error domain');
  Expect(ParseError.Code = 'invalid_argument', 'error code');
  Expect(ParseError.Message = 'name must not be empty', 'error message');
  Expect(ParseError.SameIdentity(SameIdentityError), 'same error identity ignores message');
  Expect(not ParseError.SameIdentity(DifferentError), 'different error identity');

  ResultOk := TXrtlResult.Ok;
  Expect(ResultOk.Succeeded, 'result ok succeeded');
  Expect(not ResultOk.Failed, 'result ok not failed');
  Expect(ResultOk.Error.IsEmpty, 'result ok empty error');

  ResultFail := TXrtlResult.Fail(ParseError);
  Expect(ResultFail.Failed, 'result fail failed');
  Expect(not ResultFail.Succeeded, 'result fail not succeeded');
  Expect(ResultFail.Error.SameIdentity(ParseError), 'result fail error identity');

  ValueOk := TStringValueResult.Ok('value');
  Expect(ValueOk.Succeeded, 'value-result ok succeeded');
  Expect(ValueOk.Value = 'value', 'value-result value');

  ValueFail := TStringValueResult.Fail(ParseError);
  Expect(ValueFail.Failed, 'value-result fail failed');
  Expect(ValueFail.ResultInfo.Error.SameIdentity(ParseError), 'value-result error identity');

  WriteLn('ok: core_result_tests');
end.
