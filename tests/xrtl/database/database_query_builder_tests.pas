program database_query_builder_tests;

{$mode objfpc}{$H+}

uses
  xrtl_core, xrtl_database;

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

procedure ExpectTextValue(const AValue: TXrtlDatabaseValue; const AExpected, Message: string);
begin
  Expect(AValue.Kind = xsvText, Message + ' kind');
  Expect(AValue.TextValue = AExpected, Message + ' value');
end;

procedure AddNote(
  const AConnection: TXrtlDatabaseConnection;
  const AParams: TXrtlDatabaseParameters;
  const ATitle: string;
  const APriority: Int64);
begin
  AParams.Clear;
  AParams.AddText('title', ATitle);
  AParams.AddInt64('priority', APriority);
  ExpectOk(AConnection.Execute(
    'insert into notes(title, priority) values (:title, :priority)',
    AParams), 'insert note ' + ATitle);
end;

procedure RunBuilderValidation;
var
  Builder: TXrtlDatabaseSelectBuilder;
  Params: TXrtlDatabaseParameters;
  Sql: string;
  ResultInfo: TXrtlResult;
begin
  Builder := TXrtlDatabaseSelectBuilder.Create;
  Params := TXrtlDatabaseParameters.Create;
  try
    ResultInfo := Builder.Build(Sql, nil);
    ExpectFailCode(ResultInfo, 'invalid_parameters', 'build with nil params');

    ResultInfo := Builder.Build(Sql, Params);
    ExpectFailCode(ResultInfo, 'invalid_query', 'build without table');

    ResultInfo := Builder.FromTable('notes;drop');
    ExpectFailCode(ResultInfo, 'invalid_identifier', 'invalid table identifier');
    ResultInfo := Builder.AddColumn('bad column');
    ExpectFailCode(ResultInfo, 'invalid_identifier', 'invalid column identifier');
    ResultInfo := Builder.WhereTextEquals('title', 'bad-name', 'alpha');
    ExpectFailCode(ResultInfo, 'invalid_parameter', 'invalid parameter identifier');
    ResultInfo := Builder.SetLimit(-1);
    ExpectFailCode(ResultInfo, 'invalid_limit', 'negative limit');

    ExpectOk(Builder.FromTable('notes'), 'set valid table');
    ExpectOk(Builder.WhereTextEquals('title', 'title_param', 'alpha'), 'add first where');
    ResultInfo := Builder.WhereInt64Equals('priority', 'title_param', 10);
    ExpectFailCode(ResultInfo, 'duplicate_parameter', 'duplicate parameter name');

    Builder.Clear;
    Expect(Builder.ColumnCount = 0, 'clear columns');
    Expect(Builder.WhereCount = 0, 'clear where clauses');
    Expect(Builder.ParameterCount = 0, 'clear parameters');
    Expect(not Builder.HasLimit, 'clear limit');
  finally
    Params.Free;
    Builder.Free;
  end;
end;

procedure RunProviderQueryBuilder;
var
  Connection: TXrtlDatabaseConnection;
  Builder: TXrtlDatabaseSelectBuilder;
  Params: TXrtlDatabaseParameters;
  Rows: TXrtlDatabaseResultSet;
  Row: TXrtlDatabaseRow;
  Value: TXrtlDatabaseValue;
  Sql: string;
  Count: Int64;
begin
  Connection := TXrtlDatabaseConnection.Create;
  Builder := TXrtlDatabaseSelectBuilder.Create;
  Params := TXrtlDatabaseParameters.Create;
  Rows := TXrtlDatabaseResultSet.Create;
  try
    ExpectOk(Connection.Open(TXrtlDatabaseConnectionConfig.SQLiteInMemory), 'open query builder connection');
    ExpectOk(Connection.Execute(
      'create table notes (' +
      'id integer primary key autoincrement, ' +
      'title text not null, ' +
      'priority integer not null)'), 'create notes table');
    AddNote(Connection, Params, 'alpha', 10);
    AddNote(Connection, Params, 'beta', 20);
    AddNote(Connection, Params, 'gamma', 20);

    Builder.Clear;
    ExpectOk(Builder.FromTable('notes'), 'builder table');
    ExpectOk(Builder.AddColumn('title'), 'builder title column');
    ExpectOk(Builder.AddColumn('priority'), 'builder priority column');
    ExpectOk(Builder.WhereTextEquals('title', 'wanted_title', 'beta'), 'builder text where');
    ExpectOk(Builder.WhereInt64Equals('priority', 'wanted_priority', 20), 'builder int where');
    ExpectOk(Builder.AddOrderBy('priority', xsdDescending), 'builder order desc');
    ExpectOk(Builder.SetLimit(1), 'builder limit one');
    ExpectOk(Builder.Build(Sql, Params), 'build filtered query');
    Expect(Sql = 'select title, priority from notes where title = :wanted_title and priority = :wanted_priority order by priority desc limit 1', 'filtered SQL text');
    Expect(Params.Count = 2, 'filtered params count');
    ExpectOk(Connection.QueryRows(Sql, Params, Rows), 'execute filtered query');
    Expect(Rows.RowCount = 1, 'filtered row count');
    ExpectOk(Rows.RowByIndex(0, Row), 'filtered first row');
    ExpectOk(Row.ValueByName('title', Value), 'filtered title');
    ExpectTextValue(Value, 'beta', 'filtered title');

    Builder.Clear;
    ExpectOk(Builder.FromTable('notes'), 'default column table');
    ExpectOk(Builder.WhereTextEquals('title', 'wanted_title', 'alpha'), 'default column where');
    ExpectOk(Builder.Build(Sql, Params), 'build default column query');
    Expect(Sql = 'select * from notes where title = :wanted_title', 'default column SQL');
    ExpectOk(Connection.QueryRows(Sql, Params, Rows), 'execute default column query');
    Expect(Rows.RowCount = 1, 'default column row count');
    Expect(Rows.ColumnCount = 3, 'default column count');

    Builder.Clear;
    ExpectOk(Builder.FromTable('notes'), 'limit zero table');
    ExpectOk(Builder.AddColumn('title'), 'limit zero column');
    ExpectOk(Builder.AddOrderBy('title', xsdAscending), 'limit zero order');
    ExpectOk(Builder.SetLimit(0), 'limit zero');
    ExpectOk(Builder.Build(Sql, Params), 'build limit zero query');
    Expect(Sql = 'select title from notes order by title asc limit 0', 'limit zero SQL');
    ExpectOk(Connection.QueryRows(Sql, Params, Rows), 'execute limit zero query');
    Expect(Rows.RowCount = 0, 'limit zero row count');

    Builder.Clear;
    ExpectOk(Builder.FromTable('notes'), 'no result table');
    ExpectOk(Builder.WhereTextEquals('title', 'missing_title', 'missing'), 'no result where');
    ExpectOk(Builder.Build(Sql, Params), 'build no result query');
    ExpectOk(Connection.QueryRows(Sql, Params, Rows), 'execute no result query');
    Expect(Rows.RowCount = 0, 'no result row count');

    ExpectOk(Connection.QueryInt64('select count(*) from notes', Count), 'count all notes');
    Expect(Count = 3, 'all notes count remains unchanged');
    ExpectOk(Connection.Close, 'close query builder connection');
  finally
    Rows.Free;
    Params.Free;
    Builder.Free;
    Connection.Free;
  end;
end;

begin
  RunBuilderValidation;
  RunProviderQueryBuilder;
  WriteLn('ok: database_query_builder_tests');
end.
