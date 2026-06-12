program database_raw_mapping_tests;

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
  Result := IncludeTrailingPathDelimiter(GetCurrentDir) + 'build' + DirectorySeparator + 'xrtl_database_raw_mapping_test.sqlite';
end;

procedure AddNote(
  const ADatabase: TXrtlSqliteDatabase;
  const AParams: TXrtlSqliteParameters;
  const ATitle: string;
  const APriority: Int64;
  const AMemo: string;
  const AUseNullMemo: Boolean);
begin
  AParams.Clear;
  AParams.AddText('title', ATitle);
  AParams.AddInt64('priority', APriority);
  if AUseNullMemo then
    AParams.AddNull('memo')
  else
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
  Rows: TXrtlSqliteResultSet;
  Row: TXrtlSqliteRow;
  Field: TXrtlSqliteField;
  Value: TXrtlSqliteValue;
  ColumnName: string;
  ResultInfo: TXrtlResult;
begin
  DatabasePath := BuildDatabasePath;
  DeleteFile(DatabasePath);

  Database := TXrtlSqliteDatabase.Create;
  Params := TXrtlSqliteParameters.Create;
  Rows := TXrtlSqliteResultSet.Create;
  try
    ResultInfo := Database.QueryRows('select 1 as value', Rows);
    ExpectFailCode(ResultInfo, 'not_open', 'query rows before open');

    ExpectOk(Database.Open(TXrtlSqliteConnectionConfig.FileDatabase(DatabasePath)), 'open sqlite file');
    ExpectOk(Database.Execute(
      'create table notes (' +
      'id integer primary key autoincrement, ' +
      'title text not null, ' +
      'priority integer not null, ' +
      'memo text null)'), 'create notes table');

    AddNote(Database, Params, 'alpha', 10, 'memo alpha', False);
    AddNote(Database, Params, 'beta', 20, '', True);
    AddNote(Database, Params, 'gamma', 30, 'memo gamma', False);

    Params.Clear;
    Params.AddInt64('minimum_priority', 10);
    ExpectOk(Database.QueryRows(
      'select id, title, priority, memo from notes where priority >= :minimum_priority order by priority',
      Params,
      Rows), 'query raw rows');

    Expect(Rows.ColumnCount = 4, 'column count');
    Expect(Rows.RowCount = 3, 'row count');
    Expect(Rows.IndexOfColumn('TITLE') = 1, 'case-insensitive column lookup');
    ExpectOk(Rows.ColumnByIndex(0, ColumnName), 'column by index');
    Expect(ColumnName = 'id', 'first column name');
    ResultInfo := Rows.ColumnByIndex(99, ColumnName);
    ExpectFailCode(ResultInfo, 'column_index_out_of_range', 'bad column index');

    ExpectOk(Rows.RowByIndex(0, Row), 'first row by index');
    Expect(Row.FieldCount = 4, 'first row field count');
    ExpectOk(Row.ValueByName('title', Value), 'first row title by name');
    ExpectTextValue(Value, 'alpha', 'first row title');
    ExpectOk(Row.ValueByName('priority', Value), 'first row priority by name');
    ExpectInt64Value(Value, 10, 'first row priority');
    ExpectOk(Row.FieldByIndex(0, Field), 'first row first field');
    Expect(Field.Name = 'id', 'first row first field name');
    Expect(Field.Value.Kind = xsvInt64, 'first row id kind');

    ExpectOk(Rows.RowByIndex(1, Row), 'second row by index');
    ExpectOk(Row.ValueByName('memo', Value), 'second row null memo');
    Expect(Value.IsNull, 'second row memo null');
    Expect(Row.IndexOfField('PRIORITY') = 2, 'case-insensitive field lookup');

    ResultInfo := Row.FieldByIndex(99, Field);
    ExpectFailCode(ResultInfo, 'field_index_out_of_range', 'bad field index');
    ResultInfo := Row.ValueByName('missing', Value);
    ExpectFailCode(ResultInfo, 'field_not_found', 'missing field');
    ResultInfo := Rows.RowByIndex(99, Row);
    ExpectFailCode(ResultInfo, 'row_index_out_of_range', 'bad row index');

    Params.Clear;
    Params.AddText('title', 'gamma');
    ExpectOk(Database.QueryRows(
      'select title, memo from notes where title = :title',
      Params,
      Rows), 'reuse rows for filtered query');
    Expect(Rows.ColumnCount = 2, 'filtered column count');
    Expect(Rows.RowCount = 1, 'filtered row count');
    ExpectOk(Rows.RowByIndex(0, Row), 'filtered row by index');
    ExpectOk(Row.ValueByName('memo', Value), 'filtered memo');
    ExpectTextValue(Value, 'memo gamma', 'filtered memo');

    ResultInfo := Database.QueryRows('select title from notes', nil);
    ExpectFailCode(ResultInfo, 'invalid_result_set', 'nil result set');

    ExpectOk(Database.Close, 'close sqlite file');
  finally
    Rows.Free;
    Params.Free;
    Database.Free;
    DeleteFile(DatabasePath);
  end;

  WriteLn('ok: database_raw_mapping_tests');
end.
