program database_orm_tests;

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

procedure ConfigureNoteSchema(const ASchema: TXrtlDatabaseOrmSchema);
begin
  ExpectOk(ASchema.Configure('notes', 'id'), 'configure notes schema');
  ExpectOk(ASchema.AddField('id', 'id'), 'add id field');
  ExpectOk(ASchema.AddField('title', 'title'), 'add title field');
  ExpectOk(ASchema.AddField('priority', 'priority'), 'add priority field');
end;

procedure RunSchemaValidation;
var
  Schema: TXrtlDatabaseOrmSchema;
  ResultInfo: TXrtlResult;
begin
  Schema := TXrtlDatabaseOrmSchema.Create;
  try
    ResultInfo := Schema.Validate;
    ExpectFailCode(ResultInfo, 'invalid_orm_schema', 'validate empty schema');

    ResultInfo := Schema.Configure('bad table', 'id');
    ExpectFailCode(ResultInfo, 'invalid_orm_schema', 'invalid table identifier');
    ResultInfo := Schema.Configure('notes', 'bad-id');
    ExpectFailCode(ResultInfo, 'invalid_orm_schema', 'invalid id column');

    ExpectOk(Schema.Configure('notes', 'id'), 'configure schema');
    ResultInfo := Schema.Validate;
    ExpectFailCode(ResultInfo, 'invalid_orm_schema', 'validate schema without fields');

    ResultInfo := Schema.AddField('bad field', 'title');
    ExpectFailCode(ResultInfo, 'invalid_orm_schema', 'invalid field name');
    ResultInfo := Schema.AddField('title', 'bad-column');
    ExpectFailCode(ResultInfo, 'invalid_orm_schema', 'invalid column name');

    ExpectOk(Schema.AddField('title', 'title'), 'add title field');
    ResultInfo := Schema.AddField('title', 'title_copy');
    ExpectFailCode(ResultInfo, 'duplicate_orm_field', 'duplicate field name');
    ResultInfo := Schema.AddField('titleCopy', 'title');
    ExpectFailCode(ResultInfo, 'duplicate_orm_column', 'duplicate column name');
    ExpectOk(Schema.Validate, 'validate fielded schema');

    Schema.Clear;
    Expect(Schema.FieldCount = 0, 'schema clear fields');
    ResultInfo := Schema.Validate;
    ExpectFailCode(ResultInfo, 'invalid_orm_schema', 'validate cleared schema');
  finally
    Schema.Free;
  end;
end;

procedure RunMapper;
var
  Connection: TXrtlDatabaseConnection;
  Params: TXrtlDatabaseParameters;
  Schema: TXrtlDatabaseOrmSchema;
  BrokenSchema: TXrtlDatabaseOrmSchema;
  Mapper: TXrtlDatabaseOrmMapper;
  RecordData: TXrtlDatabaseOrmRecord;
  Value: TXrtlDatabaseValue;
  ResultInfo: TXrtlResult;
begin
  Connection := TXrtlDatabaseConnection.Create;
  Params := TXrtlDatabaseParameters.Create;
  Schema := TXrtlDatabaseOrmSchema.Create;
  BrokenSchema := TXrtlDatabaseOrmSchema.Create;
  Mapper := TXrtlDatabaseOrmMapper.Create;
  RecordData := TXrtlDatabaseOrmRecord.Create;
  try
    ConfigureNoteSchema(Schema);

    ResultInfo := Mapper.FindByInt64Id(nil, Schema, 1, RecordData);
    ExpectFailCode(ResultInfo, 'invalid_connection', 'mapper nil connection');
    ResultInfo := Mapper.FindByInt64Id(Connection, nil, 1, RecordData);
    ExpectFailCode(ResultInfo, 'invalid_orm_schema', 'mapper nil schema');
    ResultInfo := Mapper.FindByInt64Id(Connection, Schema, 1, nil);
    ExpectFailCode(ResultInfo, 'invalid_orm_record', 'mapper nil record');

    ExpectOk(Connection.Open(TXrtlDatabaseConnectionConfig.SQLiteInMemory), 'open orm connection');
    ExpectOk(Connection.Execute(
      'create table notes (' +
      'id integer primary key autoincrement, ' +
      'title text not null, ' +
      'priority integer not null)'), 'create notes table');
    AddNote(Connection, Params, 'alpha', 10);
    AddNote(Connection, Params, 'beta', 20);

    ExpectOk(Mapper.FindByInt64Id(Connection, Schema, 2, RecordData), 'find beta by id');
    Expect(RecordData.ValueCount = 3, 'mapped value count');
    ExpectOk(RecordData.ValueByName('id', Value), 'mapped id');
    ExpectInt64Value(Value, 2, 'mapped id');
    ExpectOk(RecordData.ValueByName('title', Value), 'mapped title');
    ExpectTextValue(Value, 'beta', 'mapped title');
    ExpectOk(RecordData.ValueByName('priority', Value), 'mapped priority');
    ExpectInt64Value(Value, 20, 'mapped priority');

    ResultInfo := RecordData.ValueByName('missing', Value);
    ExpectFailCode(ResultInfo, 'orm_field_not_found', 'missing mapped field');

    ResultInfo := Mapper.FindByInt64Id(Connection, Schema, 99, RecordData);
    ExpectFailCode(ResultInfo, 'orm_record_not_found', 'missing orm record');

    ExpectOk(BrokenSchema.Configure('notes', 'id'), 'configure broken schema');
    ExpectOk(BrokenSchema.AddField('missing', 'missing_column'), 'add missing column mapping');
    ResultInfo := Mapper.FindByInt64Id(Connection, BrokenSchema, 1, RecordData);
    ExpectFailCode(ResultInfo, 'query_failed', 'missing mapped column query failure');

    ExpectOk(Connection.Close, 'close orm connection');
  finally
    RecordData.Free;
    Mapper.Free;
    BrokenSchema.Free;
    Schema.Free;
    Params.Free;
    Connection.Free;
  end;
end;

begin
  RunSchemaValidation;
  RunMapper;
  WriteLn('ok: database_orm_tests');
end.
