program database_orm_v1_tests;

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

procedure ExpectInt64Value(const AValue: TXrtlDatabaseValue; const AExpected: Int64; const Message: string);
begin
  Expect(AValue.Kind = xsvInt64, Message + ' kind');
  Expect(AValue.Int64ValueData = AExpected, Message + ' value');
end;

procedure ConfigureNoteSchema(const ASchema: TXrtlDatabaseOrmSchema);
begin
  ExpectOk(ASchema.Configure('notes', 'id'), 'configure notes schema');
  ExpectOk(ASchema.AddField('id', 'id', False, False), 'add id field');
  ExpectOk(ASchema.AddField('title', 'title', True, True), 'add title field');
  ExpectOk(ASchema.AddField('priority', 'priority', True, True), 'add priority field');
  ExpectOk(ASchema.AddField('memo', 'memo', False, True), 'add memo field');
end;

procedure CreateNotesTable(const AConnection: TXrtlDatabaseConnection);
begin
  ExpectOk(AConnection.Execute(
    'create table notes (' +
    'id integer primary key autoincrement, ' +
    'title text not null, ' +
    'priority integer not null, ' +
    'memo text null)'), 'create notes table');
end;

procedure RunMapperCrudAndSqlCache;
var
  Connection: TXrtlDatabaseConnection;
  Schema: TXrtlDatabaseOrmSchema;
  Mapper: TXrtlDatabaseOrmMapper;
  Input: TXrtlDatabaseOrmRecord;
  Output: TXrtlDatabaseOrmRecord;
  Value: TXrtlDatabaseValue;
  Id: Int64;
  Count: Int64;
  ResultInfo: TXrtlResult;
begin
  Connection := TXrtlDatabaseConnection.Create;
  Schema := TXrtlDatabaseOrmSchema.Create;
  Mapper := TXrtlDatabaseOrmMapper.Create;
  Input := TXrtlDatabaseOrmRecord.Create;
  Output := TXrtlDatabaseOrmRecord.Create;
  try
    ConfigureNoteSchema(Schema);
    ExpectOk(Connection.Open(TXrtlDatabaseConnectionConfig.SQLiteInMemory), 'open mapper connection');
    CreateNotesTable(Connection);

    Input.SetText('title', 'alpha');
    Input.SetInt64('priority', 10);
    ExpectOk(Mapper.Insert(Connection, Schema, Input, Id), 'insert alpha');
    Expect(Id = 1, 'inserted id');
    ExpectOk(Input.ValueByName('id', Value), 'insert fills id');
    ExpectInt64Value(Value, 1, 'inserted id value');
    ExpectOk(Connection.QueryInt64('select count(*) from notes where memo is null', Count), 'count null memo');
    Expect(Count = 1, 'optional memo bound as null');

    ExpectOk(Mapper.FindByInt64Id(Connection, Schema, Id, Output), 'find alpha');
    ExpectOk(Output.ValueByName('title', Value), 'found title');
    ExpectTextValue(Value, 'alpha', 'found title');
    ExpectOk(Mapper.FindByInt64Id(Connection, Schema, Id, Output), 'find alpha again');
    Expect(Mapper.SqlCache.HitCount >= 1, 'select sql cache hit');

    Input.Clear;
    Input.SetText('title', 'beta');
    Input.SetInt64('priority', 20);
    Input.SetText('memo', 'updated through mapper');
    ExpectOk(Mapper.Update(Connection, Schema, Id, Input), 'update beta');
    ExpectOk(Mapper.FindByInt64Id(Connection, Schema, Id, Output), 'find beta');
    ExpectOk(Output.ValueByName('title', Value), 'updated title');
    ExpectTextValue(Value, 'beta', 'updated title');
    ExpectOk(Output.ValueByName('memo', Value), 'updated memo');
    ExpectTextValue(Value, 'updated through mapper', 'updated memo');

    Input.Clear;
    Input.SetInt64('priority', 99);
    ResultInfo := Mapper.Insert(Connection, Schema, Input, Id);
    ExpectFailCode(ResultInfo, 'orm_required_field_missing', 'missing required title');

    ExpectOk(Mapper.DeleteByInt64Id(Connection, Schema, 1), 'delete beta');
    ResultInfo := Mapper.FindByInt64Id(Connection, Schema, 1, Output);
    ExpectFailCode(ResultInfo, 'orm_record_not_found', 'deleted record missing');
    ResultInfo := Mapper.DeleteByInt64Id(Connection, Schema, 99);
    ExpectFailCode(ResultInfo, 'orm_record_not_found', 'delete missing record');

    Expect(Mapper.SqlCache.MissCount >= 4, 'sql cache miss count');
    ExpectOk(Connection.Close, 'close mapper connection');
  finally
    Output.Free;
    Input.Free;
    Mapper.Free;
    Schema.Free;
    Connection.Free;
  end;
end;

procedure RunSchemaCache;
var
  Schema: TXrtlDatabaseOrmSchema;
  Cache: TXrtlDatabaseOrmSchemaCache;
  Index: Integer;
  ResultInfo: TXrtlResult;
begin
  Schema := TXrtlDatabaseOrmSchema.Create;
  Cache := TXrtlDatabaseOrmSchemaCache.Create;
  try
    ConfigureNoteSchema(Schema);
    ExpectOk(Cache.RegisterSchema(Schema, Index), 'register schema first');
    Expect(Index = 0, 'schema first index');
    ExpectOk(Cache.RegisterSchema(Schema, Index), 'register schema second');
    Expect(Index = 0, 'schema cached index');
    Expect(Cache.Count = 1, 'schema cache count');
    Expect(Cache.HitCount = 1, 'schema cache hit');
    Expect(Cache.MissCount = 1, 'schema cache miss');

    ResultInfo := Cache.RegisterSchema(nil, Index);
    ExpectFailCode(ResultInfo, 'invalid_orm_schema', 'register nil schema');
  finally
    Cache.Free;
    Schema.Free;
  end;
end;

procedure RunSessionRepositoryAndRollback;
var
  Connection: TXrtlDatabaseConnection;
  Params: TXrtlDatabaseParameters;
  Schema: TXrtlDatabaseOrmSchema;
  Session: TXrtlDatabaseOrmSession;
  Repository: TXrtlDatabaseOrmRepository;
  Input: TXrtlDatabaseOrmRecord;
  Output: TXrtlDatabaseOrmRecord;
  Value: TXrtlDatabaseValue;
  Id: Int64;
  RolledBackId: Int64;
  Count: Int64;
begin
  Connection := TXrtlDatabaseConnection.Create;
  Params := TXrtlDatabaseParameters.Create;
  Schema := TXrtlDatabaseOrmSchema.Create;
  Session := TXrtlDatabaseOrmSession.Create(Connection);
  Repository := TXrtlDatabaseOrmRepository.Create(Session, Schema);
  Input := TXrtlDatabaseOrmRecord.Create;
  Output := TXrtlDatabaseOrmRecord.Create;
  try
    ConfigureNoteSchema(Schema);
    ExpectOk(Connection.Open(TXrtlDatabaseConnectionConfig.SQLiteInMemory), 'open session connection');
    CreateNotesTable(Connection);

    ExpectOk(Session.BeginWork, 'begin session work');
    Input.SetText('title', 'session cached');
    Input.SetInt64('priority', 1);
    ExpectOk(Repository.Insert(Input, Id), 'repository insert');
    Expect(Session.IdentityMapCount = 1, 'identity after insert');

    Params.Clear;
    Params.AddText('title', 'external mutation');
    Params.AddInt64('id', Id);
    ExpectOk(Connection.Execute('update notes set title = :title where id = :id', Params), 'external mutation');
    ExpectOk(Repository.FindByInt64Id(Id, Output), 'repository cached find');
    ExpectOk(Output.ValueByName('title', Value), 'cached title field');
    ExpectTextValue(Value, 'session cached', 'identity map returns snapshot');
    Expect(Session.IdentityMapHitCount = 1, 'identity map hit count');

    Input.Clear;
    Input.SetText('title', 'session update');
    Input.SetInt64('priority', 2);
    ExpectOk(Repository.Update(Id, Input), 'repository update');
    ExpectOk(Repository.FindByInt64Id(Id, Output), 'repository find after update');
    ExpectOk(Output.ValueByName('title', Value), 'updated cached title field');
    ExpectTextValue(Value, 'session update', 'updated identity snapshot');
    ExpectOk(Session.Commit, 'commit session work');
    Expect(not Connection.InTransaction, 'transaction committed');

    ExpectOk(Session.BeginWork, 'begin rollback work');
    Input.Clear;
    Input.SetText('title', 'rollback me');
    Input.SetInt64('priority', 3);
    ExpectOk(Repository.Insert(Input, RolledBackId), 'insert rollback row');
    ExpectOk(Session.Rollback, 'rollback session work');
    Expect(Session.IdentityMapCount = 0, 'identity map cleared after rollback');

    Params.Clear;
    Params.AddInt64('id', RolledBackId);
    ExpectOk(Connection.QueryInt64('select count(*) from notes where id = :id', Params, Count), 'count rollback row');
    Expect(Count = 0, 'rollback row absent');

    Expect(Session.SchemaCache.Count = 1, 'session schema cache count');
    Expect(Session.SchemaCache.HitCount >= 1, 'session schema cache hit');
    ExpectOk(Connection.Close, 'close session connection');
  finally
    Output.Free;
    Input.Free;
    Repository.Free;
    Session.Free;
    Schema.Free;
    Params.Free;
    Connection.Free;
  end;
end;

begin
  RunMapperCrudAndSqlCache;
  RunSchemaCache;
  RunSessionRepositoryAndRollback;
  WriteLn('ok: database_orm_v1_tests');
end.
