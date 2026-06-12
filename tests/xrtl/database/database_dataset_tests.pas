program database_dataset_tests;

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
  Result := IncludeTrailingPathDelimiter(GetCurrentDir) + 'build' + DirectorySeparator + 'xrtl_database_dataset_test.sqlite';
end;

procedure AddNote(
  const ADatabase: TXrtlSqliteDatabase;
  const AParams: TXrtlSqliteParameters;
  const ATitle: string;
  const APriority: Int64;
  const AMemo: string);
begin
  AParams.Clear;
  AParams.AddText('title', ATitle);
  AParams.AddInt64('priority', APriority);
  AParams.AddText('memo', AMemo);
  ExpectOk(ADatabase.Execute(
    'insert into notes(title, priority, memo) values (:title, :priority, :memo)',
    AParams), 'insert note ' + ATitle);
end;

procedure ExpectTextValue(const AValue: TXrtlSqliteValue; const AExpected, Message: string);
begin
  Expect(AValue.Kind = xsvText, Message + ' kind');
  Expect(AValue.TextValue = AExpected, Message + ' value');
end;

procedure ExpectInt64Value(const AValue: TXrtlSqliteValue; const AExpected: Int64; const Message: string);
begin
  Expect(AValue.Kind = xsvInt64, Message + ' kind');
  Expect(AValue.Int64ValueData = AExpected, Message + ' value');
end;

var
  DatabasePath: string;
  Database: TXrtlSqliteDatabase;
  Params: TXrtlSqliteParameters;
  DataSet: TXrtlSqliteDataSet;
  Rows: TXrtlSqliteResultSet;
  Row: TXrtlSqliteRow;
  Value: TXrtlSqliteValue;
  ResultInfo: TXrtlResult;
begin
  DatabasePath := BuildDatabasePath;
  DeleteFile(DatabasePath);

  Database := TXrtlSqliteDatabase.Create;
  Params := TXrtlSqliteParameters.Create;
  DataSet := TXrtlSqliteDataSet.Create;
  Rows := TXrtlSqliteResultSet.Create;
  try
    ResultInfo := DataSet.ValueByName('title', Value);
    ExpectFailCode(ResultInfo, 'dataset_not_active', 'value before active');
    ResultInfo := DataSet.First;
    ExpectFailCode(ResultInfo, 'dataset_not_active', 'first before active');
    ResultInfo := DataSet.LoadFromResultSet(nil);
    ExpectFailCode(ResultInfo, 'invalid_result_set', 'load nil result set');

    ExpectOk(Database.Open(TXrtlSqliteConnectionConfig.FileDatabase(DatabasePath)), 'open sqlite file');
    ExpectOk(Database.Execute(
      'create table notes (' +
      'id integer primary key autoincrement, ' +
      'title text not null, ' +
      'priority integer not null, ' +
      'memo text null)'), 'create notes table');

    AddNote(Database, Params, 'alpha', 10, 'memo alpha');
    AddNote(Database, Params, 'beta', 20, 'memo beta');
    AddNote(Database, Params, 'gamma', 30, 'memo gamma');

    Params.Clear;
    Params.AddInt64('minimum_priority', 10);
    ExpectOk(Database.QueryDataSet(
      'select title, priority, memo from notes where priority >= :minimum_priority order by priority',
      Params,
      DataSet), 'query dataset');
    Expect(DataSet.Active, 'dataset active');
    Expect(not DataSet.Eof, 'dataset not eof after query');
    Expect(DataSet.RecordCount = 3, 'dataset record count');
    Expect(DataSet.FieldCount = 3, 'dataset field count');
    Expect(DataSet.CurrentIndex = 0, 'dataset starts at first record');

    ExpectOk(DataSet.ValueByName('title', Value), 'first title');
    ExpectTextValue(Value, 'alpha', 'first title');
    ExpectOk(DataSet.ValueByName('priority', Value), 'first priority');
    ExpectInt64Value(Value, 10, 'first priority');

    ExpectOk(DataSet.Next, 'move second');
    Expect(DataSet.CurrentIndex = 1, 'dataset current index second');
    ExpectOk(DataSet.ValueByName('title', Value), 'second title');
    ExpectTextValue(Value, 'beta', 'second title');

    ExpectOk(DataSet.Next, 'move third');
    ExpectOk(DataSet.ValueByName('memo', Value), 'third memo');
    ExpectTextValue(Value, 'memo gamma', 'third memo');

    ExpectOk(DataSet.Next, 'move eof');
    Expect(DataSet.Eof, 'dataset eof after last');
    ResultInfo := DataSet.ValueByName('title', Value);
    ExpectFailCode(ResultInfo, 'no_current_row', 'value after eof');

    ExpectOk(DataSet.First, 'return first');
    ExpectOk(DataSet.ValueByName('title', Value), 'title after first');
    ExpectTextValue(Value, 'alpha', 'title after first');

    Params.Clear;
    Params.AddInt64('minimum_priority', 99);
    ExpectOk(Database.QueryDataSet(
      'select title, priority from notes where priority >= :minimum_priority order by priority',
      Params,
      DataSet), 'query empty dataset');
    Expect(DataSet.Active, 'empty dataset active');
    Expect(DataSet.RecordCount = 0, 'empty dataset record count');
    Expect(DataSet.FieldCount = 2, 'empty dataset field count');
    Expect(DataSet.Eof, 'empty dataset eof');
    ResultInfo := DataSet.ValueByName('title', Value);
    ExpectFailCode(ResultInfo, 'no_current_row', 'empty current row');

    ExpectOk(Database.QueryRows(
      'select title, priority from notes where title = ''beta''',
      Rows), 'query raw rows for load');
    ExpectOk(DataSet.LoadFromResultSet(Rows), 'load dataset from raw rows');
    Expect(DataSet.RecordCount = 1, 'loaded dataset record count');
    ExpectOk(DataSet.ValueByName('title', Value), 'loaded title');
    ExpectTextValue(Value, 'beta', 'loaded title');

    DataSet.Clear;
    Expect(not DataSet.Active, 'dataset inactive after clear');
    ResultInfo := DataSet.CurrentRow(Row);
    ExpectFailCode(ResultInfo, 'dataset_not_active', 'current row after clear');

    ResultInfo := Database.QueryDataSet('select title from notes', nil);
    ExpectFailCode(ResultInfo, 'invalid_dataset', 'nil dataset target');

    ExpectOk(Database.Close, 'close sqlite file');
  finally
    Rows.Free;
    DataSet.Free;
    Params.Free;
    Database.Free;
    DeleteFile(DatabasePath);
  end;

  WriteLn('ok: database_dataset_tests');
end.
