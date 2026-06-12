program database_migration_tests;

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

function BuildMigration(const AId, ADescription, ASql: string): TXrtlDatabaseMigration;
begin
  Result := TXrtlDatabaseMigration.Create(AId, ADescription);
  ExpectOk(Result.AddStatement(ASql), 'add statement ' + AId);
end;

procedure AddMigration(
  const APlan: TXrtlDatabaseMigrationPlan;
  const AMigration: TXrtlDatabaseMigration;
  const AMessage: string);
begin
  ExpectOk(APlan.Add(AMigration), AMessage);
end;

procedure InsertAppliedMigration(
  const AConnection: TXrtlDatabaseConnection;
  const AParams: TXrtlDatabaseParameters;
  const AId: string;
  const AOrder: Int64);
begin
  AParams.Clear;
  AParams.AddText('id', AId);
  AParams.AddText('description', 'manual metadata row');
  AParams.AddInt64('applied_order', AOrder);
  ExpectOk(AConnection.Execute(
    'insert into xrtl_schema_migrations(id, description, applied_order, applied_at_utc) ' +
    'values (:id, :description, :applied_order, strftime(''%Y-%m-%dT%H:%M:%fZ'', ''now''))',
    AParams), 'insert manual migration metadata ' + AId);
end;

procedure RunMainMigrationFlow;
var
  Connection: TXrtlDatabaseConnection;
  Runner: TXrtlDatabaseMigrationRunner;
  NilRunner: TXrtlDatabaseMigrationRunner;
  Plan: TXrtlDatabaseMigrationPlan;
  EmptyPlan: TXrtlDatabaseMigrationPlan;
  Params: TXrtlDatabaseParameters;
  Migration: TXrtlDatabaseMigration;
  AppliedCount: Integer;
  Count: Int64;
  ResultInfo: TXrtlResult;
begin
  Connection := TXrtlDatabaseConnection.Create;
  Runner := TXrtlDatabaseMigrationRunner.Create(Connection);
  NilRunner := TXrtlDatabaseMigrationRunner.Create(nil);
  Plan := TXrtlDatabaseMigrationPlan.Create;
  EmptyPlan := TXrtlDatabaseMigrationPlan.Create;
  Params := TXrtlDatabaseParameters.Create;
  try
    ResultInfo := Runner.Apply(nil, AppliedCount);
    ExpectFailCode(ResultInfo, 'invalid_migration_plan', 'nil migration plan');

    ResultInfo := Runner.Apply(EmptyPlan, AppliedCount);
    ExpectFailCode(ResultInfo, 'not_open', 'apply before open');

    ResultInfo := NilRunner.Apply(EmptyPlan, AppliedCount);
    ExpectFailCode(ResultInfo, 'invalid_connection', 'nil migration connection');

    ExpectOk(Connection.Open(TXrtlDatabaseConnectionConfig.SQLiteInMemory), 'open migration connection');

    Migration := TXrtlDatabaseMigration.Create('', 'missing id');
    ExpectOk(Migration.AddStatement('select 1'), 'add missing id statement');
    ResultInfo := Plan.Add(Migration);
    ExpectFailCode(ResultInfo, 'invalid_migration', 'empty migration id');

    Plan.Clear;
    Migration := BuildMigration('001_duplicate', 'duplicate guard', 'create table duplicate_guard(id integer)');
    AddMigration(Plan, Migration, 'add duplicate first');
    ResultInfo := Plan.Add(Migration);
    ExpectFailCode(ResultInfo, 'duplicate_migration', 'duplicate migration id');

    Plan.Clear;
    Migration := TXrtlDatabaseMigration.Create('001_empty', 'no statements');
    AddMigration(Plan, Migration, 'add empty migration');
    ResultInfo := Runner.Apply(Plan, AppliedCount);
    ExpectFailCode(ResultInfo, 'invalid_migration', 'migration without statements');

    Plan.Clear;
    ExpectOk(Runner.Apply(Plan, AppliedCount), 'apply empty plan');
    Expect(AppliedCount = 0, 'empty plan applied count');
    ExpectOk(Connection.QueryInt64('select count(*) from xrtl_schema_migrations', Count), 'count empty metadata');
    Expect(Count = 0, 'empty metadata count');

    ExpectOk(Connection.BeginTransaction, 'begin outer transaction');
    ResultInfo := Runner.Apply(Plan, AppliedCount);
    ExpectFailCode(ResultInfo, 'migration_transaction_active', 'migration inside outer transaction');
    ExpectOk(Connection.Rollback, 'rollback outer transaction');

    Plan.Clear;
    Migration := TXrtlDatabaseMigration.Create('001_create_notes', 'Create notes table');
    ExpectOk(Migration.AddStatement(
      'create table notes (' +
      'id integer primary key autoincrement, ' +
      'title text not null)'), 'add create notes statement');
    AddMigration(Plan, Migration, 'add create notes migration');

    Migration := TXrtlDatabaseMigration.Create('002_seed_notes', 'Seed notes table');
    ExpectOk(Migration.AddStatement('insert into notes(title) values (''alpha'')'), 'add alpha seed');
    ExpectOk(Migration.AddStatement('insert into notes(title) values (''beta'')'), 'add beta seed');
    AddMigration(Plan, Migration, 'add seed migration');

    ExpectOk(Runner.Apply(Plan, AppliedCount), 'apply first migration plan');
    Expect(AppliedCount = 2, 'first plan applied count');
    ExpectOk(Connection.QueryInt64('select count(*) from notes', Count), 'count seeded notes');
    Expect(Count = 2, 'seeded note count');
    ExpectOk(Connection.QueryInt64('select count(*) from xrtl_schema_migrations', Count), 'count applied migrations');
    Expect(Count = 2, 'applied migration count');

    ExpectOk(Runner.Apply(Plan, AppliedCount), 'reapply migration plan');
    Expect(AppliedCount = 0, 'reapply no-op count');

    Migration := BuildMigration('003_more_notes', 'Insert another note', 'insert into notes(title) values (''gamma'')');
    AddMigration(Plan, Migration, 'add third migration');
    ExpectOk(Runner.Apply(Plan, AppliedCount), 'apply third migration only');
    Expect(AppliedCount = 1, 'third migration applied count');
    ExpectOk(Connection.QueryInt64('select count(*) from notes', Count), 'count after third migration');
    Expect(Count = 3, 'third migration note count');

    Params.Clear;
    Params.AddText('id', '003_more_notes');
    ExpectOk(Connection.QueryInt64(
      'select applied_order from xrtl_schema_migrations where id = :id',
      Params,
      Count), 'query third applied order');
    Expect(Count = 3, 'third applied order');

    ExpectOk(Connection.Close, 'close migration connection');
  finally
    Params.Free;
    EmptyPlan.Free;
    Plan.Free;
    NilRunner.Free;
    Runner.Free;
    Connection.Free;
  end;
end;

procedure RunOutOfOrderGuard;
var
  Connection: TXrtlDatabaseConnection;
  Runner: TXrtlDatabaseMigrationRunner;
  Plan: TXrtlDatabaseMigrationPlan;
  Params: TXrtlDatabaseParameters;
  AppliedCount: Integer;
  ResultInfo: TXrtlResult;
begin
  Connection := TXrtlDatabaseConnection.Create;
  Runner := TXrtlDatabaseMigrationRunner.Create(Connection);
  Plan := TXrtlDatabaseMigrationPlan.Create;
  Params := TXrtlDatabaseParameters.Create;
  try
    ExpectOk(Connection.Open(TXrtlDatabaseConnectionConfig.SQLiteInMemory), 'open out-of-order connection');
    ExpectOk(Runner.Apply(Plan, AppliedCount), 'ensure metadata for out-of-order test');
    InsertAppliedMigration(Connection, Params, '002_second', 1);

    AddMigration(Plan, BuildMigration('001_first', 'first migration', 'create table out_order_first(id integer)'), 'add pending first');
    AddMigration(Plan, BuildMigration('002_second', 'second migration', 'create table out_order_second(id integer)'), 'add already applied second');
    ResultInfo := Runner.Apply(Plan, AppliedCount);
    ExpectFailCode(ResultInfo, 'migration_out_of_order', 'out-of-order applied migration');
    Expect(AppliedCount = 0, 'out-of-order applied count remains zero');

    ExpectOk(Connection.Close, 'close out-of-order connection');
  finally
    Params.Free;
    Plan.Free;
    Runner.Free;
    Connection.Free;
  end;
end;

procedure RunFailureRollback;
var
  Connection: TXrtlDatabaseConnection;
  Runner: TXrtlDatabaseMigrationRunner;
  Plan: TXrtlDatabaseMigrationPlan;
  Migration: TXrtlDatabaseMigration;
  AppliedCount: Integer;
  Count: Int64;
  ResultInfo: TXrtlResult;
begin
  Connection := TXrtlDatabaseConnection.Create;
  Runner := TXrtlDatabaseMigrationRunner.Create(Connection);
  Plan := TXrtlDatabaseMigrationPlan.Create;
  try
    ExpectOk(Connection.Open(TXrtlDatabaseConnectionConfig.SQLiteInMemory), 'open rollback connection');

    Migration := TXrtlDatabaseMigration.Create('001_fail', 'Fail after DDL');
    ExpectOk(Migration.AddStatement('create table rollback_notes(id integer)'), 'add rollback DDL');
    ExpectOk(Migration.AddStatement('insert into missing_table(id) values (1)'), 'add failing statement');
    AddMigration(Plan, Migration, 'add failing migration');

    ResultInfo := Runner.Apply(Plan, AppliedCount);
    ExpectFailCode(ResultInfo, 'migration_failed', 'failing migration');
    Expect(AppliedCount = 0, 'failing migration applied count');
    Expect(not Connection.InTransaction, 'connection not in transaction after failed migration');

    ResultInfo := Connection.QueryInt64('select count(*) from rollback_notes', Count);
    ExpectFailCode(ResultInfo, 'query_failed', 'rolled back DDL table missing');
    ExpectOk(Connection.QueryInt64('select count(*) from xrtl_schema_migrations', Count), 'count metadata after failure');
    Expect(Count = 0, 'no migration metadata after failure');

    ExpectOk(Connection.Close, 'close rollback connection');
  finally
    Plan.Free;
    Runner.Free;
    Connection.Free;
  end;
end;

begin
  RunMainMigrationFlow;
  RunOutOfOrderGuard;
  RunFailureRollback;
  WriteLn('ok: database_migration_tests');
end.
