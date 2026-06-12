program database_transaction_tests;

{$mode objfpc}{$H+}

uses
  SysUtils, xrtl_core, xrtl_database;

procedure Expect(const Condition: Boolean; const Message: string);
begin
  if not Condition then
  begin
    WriteLn('fail: ', Message);
    Halt(1);
  end;
end;

procedure ExpectOk(const AResult: TXrtlResult; const Message: string);
begin
  if AResult.Failed then
  begin
    WriteLn('fail: ', Message, ': ', AResult.Error.Code, ': ', AResult.Error.Message);
    Halt(1);
  end;
end;

procedure ExpectFailCode(const AResult: TXrtlResult; const ACode, Message: string);
begin
  if not AResult.Failed then
  begin
    WriteLn('fail: ', Message, ': expected failure');
    Halt(1);
  end;
  if AResult.Error.Code <> ACode then
  begin
    WriteLn('fail: ', Message, ': expected ', ACode, ', got ', AResult.Error.Code);
    Halt(1);
  end;
end;

function BuildDatabasePath: string;
begin
  Result := IncludeTrailingPathDelimiter(GetCurrentDir) + 'build' + DirectorySeparator + 'xrtl_database_transaction_test.sqlite';
end;

procedure AddNote(
  const ADatabase: TXrtlSqliteDatabase;
  const AParams: TXrtlSqliteParameters;
  const ATitle: string;
  const APriority: Int64;
  const AUseNullMemo: Boolean);
begin
  AParams.Clear;
  AParams.AddText('title', ATitle);
  AParams.AddInt64('priority', APriority);
  if AUseNullMemo then
    AParams.AddNull('memo')
  else
    AParams.AddText('memo', 'memo for ' + ATitle);

  ExpectOk(ADatabase.Execute(
    'insert into notes(title, priority, memo) values (:title, :priority, :memo)',
    AParams), 'insert note ' + ATitle);
end;

function CountByTitle(
  const ADatabase: TXrtlSqliteDatabase;
  const AParams: TXrtlSqliteParameters;
  const ATitle: string): Int64;
begin
  AParams.Clear;
  AParams.AddText('title', ATitle);
  ExpectOk(ADatabase.QueryInt64(
    'select count(*) from notes where title = :title',
    AParams,
    Result), 'count title ' + ATitle);
end;

var
  DatabasePath: string;
  Database: TXrtlSqliteDatabase;
  Params: TXrtlSqliteParameters;
  Count: Int64;
  ResultInfo: TXrtlResult;
begin
  DatabasePath := BuildDatabasePath;
  DeleteFile(DatabasePath);

  Database := TXrtlSqliteDatabase.Create;
  Params := TXrtlSqliteParameters.Create;
  try
    ResultInfo := Database.BeginTransaction;
    ExpectFailCode(ResultInfo, 'not_open', 'begin before open');

    ExpectOk(Database.Open(TXrtlSqliteConnectionConfig.FileDatabase(DatabasePath)), 'open sqlite file');
    Expect(not Database.InTransaction, 'no transaction after open');

    ResultInfo := Database.Commit;
    ExpectFailCode(ResultInfo, 'no_transaction', 'commit without transaction');
    ResultInfo := Database.Rollback;
    ExpectFailCode(ResultInfo, 'no_transaction', 'rollback without transaction');

    ExpectOk(Database.Execute(
      'create table notes (' +
      'id integer primary key autoincrement, ' +
      'title text not null, ' +
      'priority integer not null, ' +
      'memo text null)'), 'create notes table');

    AddNote(Database, Params, 'alpha', 10, False);
    AddNote(Database, Params, 'null memo', 20, True);

    Params.Clear;
    ExpectOk(Database.QueryInt64('select count(*) from notes where memo is null', Params, Count), 'count null memo');
    Expect(Count = 1, 'null memo count');

    Params.Clear;
    Params.AddText('title', 'alpha');
    ExpectOk(Database.QueryInt64('select priority from notes where title = :title', Params, Count), 'query alpha priority');
    Expect(Count = 10, 'alpha priority');

    ExpectOk(Database.BeginTransaction, 'begin rollback transaction');
    Expect(Database.InTransaction, 'transaction active after begin');
    ResultInfo := Database.BeginTransaction;
    ExpectFailCode(ResultInfo, 'transaction_active', 'double begin');
    AddNote(Database, Params, 'rolled back', 30, False);
    ExpectOk(Database.Rollback, 'rollback transaction');
    Expect(not Database.InTransaction, 'transaction inactive after rollback');
    Expect(CountByTitle(Database, Params, 'rolled back') = 0, 'rolled back note absent');

    ExpectOk(Database.BeginTransaction, 'begin commit transaction');
    AddNote(Database, Params, 'committed', 40, False);
    ExpectOk(Database.Commit, 'commit transaction');
    Expect(not Database.InTransaction, 'transaction inactive after commit');
    Expect(CountByTitle(Database, Params, 'committed') = 1, 'committed note present');

    Params.Clear;
    Params.AddText('', 'bad');
    ResultInfo := Database.Execute('insert into notes(title, priority) values (:title, 1)', Params);
    ExpectFailCode(ResultInfo, 'invalid_parameter', 'empty parameter name');

    Params.Clear;
    Params.AddText('missing', 'bad');
    ResultInfo := Database.Execute('insert into notes(title, priority) values (:title, 1)', Params);
    ExpectFailCode(ResultInfo, 'bind_failed', 'missing parameter name');

    ExpectOk(Database.Close, 'close sqlite file');
  finally
    Params.Free;
    Database.Free;
    DeleteFile(DatabasePath);
  end;

  WriteLn('ok: database_transaction_tests');
end.
