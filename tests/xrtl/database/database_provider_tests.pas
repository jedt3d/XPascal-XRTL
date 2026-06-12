program database_provider_tests;

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

var
  Capabilities: TXrtlDatabaseProviderCapabilities;
  Config: TXrtlDatabaseConnectionConfig;
  Connection: TXrtlDatabaseConnection;
  Params: TXrtlDatabaseParameters;
  Rows: TXrtlDatabaseResultSet;
  DataSet: TXrtlDatabaseDataSet;
  Value: TXrtlDatabaseValue;
  Count: Int64;
  ResultInfo: TXrtlResult;
begin
  Capabilities := TXrtlDatabaseProviderCapabilities.SQLite;
  Expect(Capabilities.ProviderKind = xdpSqlite, 'sqlite provider kind');
  Expect(Capabilities.Name = 'sqlite', 'sqlite provider name');
  Expect(Capabilities.LocalOnly, 'sqlite provider local only');
  Expect(Capabilities.SupportsTransactions, 'sqlite provider transactions');
  Expect(Capabilities.SupportsParameters, 'sqlite provider parameters');
  Expect(Capabilities.SupportsRawResults, 'sqlite provider raw results');
  Expect(Capabilities.SupportsDataSets, 'sqlite provider datasets');

  Config := TXrtlDatabaseConnectionConfig.SQLiteInMemory;
  Expect(Config.IsValid, 'sqlite in-memory config valid');
  Expect(Config.ProviderKind = xdpSqlite, 'connection config provider kind');

  Connection := TXrtlDatabaseConnection.Create;
  Params := TXrtlDatabaseParameters.Create;
  Rows := TXrtlDatabaseResultSet.Create;
  DataSet := TXrtlDatabaseDataSet.Create;
  try
    Expect(Connection.ProviderKind = xdpSqlite, 'default connection provider kind');
    Capabilities := Connection.Capabilities;
    Expect(Capabilities.SupportsDataSets, 'connection capabilities');

    ResultInfo := Connection.Execute('create table should_fail(id integer)');
    ExpectFailCode(ResultInfo, 'not_open', 'execute before open');

    ResultInfo := Connection.Open(TXrtlDatabaseConnectionConfig.SQLiteFile(''));
    ExpectFailCode(ResultInfo, 'invalid_config', 'invalid provider config');

    ExpectOk(Connection.Open(Config), 'open provider connection');
    Expect(Connection.IsOpen, 'provider connection open');
    ResultInfo := Connection.Open(Config);
    ExpectFailCode(ResultInfo, 'already_open', 'provider double open');

    ExpectOk(Connection.Execute(
      'create table notes (' +
      'id integer primary key autoincrement, ' +
      'title text not null, ' +
      'priority integer not null)'), 'create notes table');

    AddNote(Connection, Params, 'alpha', 10);
    AddNote(Connection, Params, 'beta', 20);

    Params.Clear;
    Params.AddText('title', 'alpha');
    ExpectOk(Connection.QueryInt64(
      'select priority from notes where title = :title',
      Params,
      Count), 'query scalar through provider');
    Expect(Count = 10, 'scalar value through provider');

    Params.Clear;
    Params.AddInt64('minimum_priority', 10);
    ExpectOk(Connection.QueryRows(
      'select title, priority from notes where priority >= :minimum_priority order by priority',
      Params,
      Rows), 'query rows through provider');
    Expect(Rows.RowCount = 2, 'provider raw row count');

    ExpectOk(Connection.QueryDataSet(
      'select title, priority from notes where priority >= :minimum_priority order by priority',
      Params,
      DataSet), 'query dataset through provider');
    Expect(DataSet.Active, 'provider dataset active');
    Expect(DataSet.RecordCount = 2, 'provider dataset record count');
    ExpectOk(DataSet.ValueByName('title', Value), 'provider dataset first title');
    Expect(Value.TextValue = 'alpha', 'provider dataset first value');

    ExpectOk(Connection.BeginTransaction, 'provider begin transaction');
    AddNote(Connection, Params, 'rolled back', 30);
    Expect(Connection.InTransaction, 'provider in transaction');
    ExpectOk(Connection.Rollback, 'provider rollback transaction');
    Params.Clear;
    Params.AddText('title', 'rolled back');
    ExpectOk(Connection.QueryInt64(
      'select count(*) from notes where title = :title',
      Params,
      Count), 'count rolled back provider row');
    Expect(Count = 0, 'provider rollback removed row');

    ExpectOk(Connection.BeginTransaction, 'provider begin commit transaction');
    AddNote(Connection, Params, 'committed', 40);
    ExpectOk(Connection.Commit, 'provider commit transaction');
    Params.Clear;
    Params.AddText('title', 'committed');
    ExpectOk(Connection.QueryInt64(
      'select count(*) from notes where title = :title',
      Params,
      Count), 'count committed provider row');
    Expect(Count = 1, 'provider commit kept row');

    ExpectOk(Connection.Close, 'close provider connection');
    Expect(not Connection.IsOpen, 'provider connection closed');
  finally
    DataSet.Free;
    Rows.Free;
    Params.Free;
    Connection.Free;
  end;

  WriteLn('ok: database_provider_tests');
end.
