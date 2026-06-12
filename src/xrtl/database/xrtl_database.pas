unit xrtl_database;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  xrtl_core;

const
  XRTL_DATABASE_LIBRARY_NAME = 'XRTL.Database';
  XRTL_DATABASE_CONTRACT_VERSION = 1;
  XRTL_DATABASE_ERROR_DOMAIN = 'xrtl.database';

type
  TXrtlSqliteConnectionConfig = record
  private
    FDatabasePath: string;
  public
    class function FileDatabase(const ADatabasePath: string): TXrtlSqliteConnectionConfig; static;
    class function InMemory: TXrtlSqliteConnectionConfig; static;
    function IsValid: Boolean;
    function IsInMemory: Boolean;
    property DatabasePath: string read FDatabasePath;
  end;

  TXrtlSqliteDatabase = class
  private
    FConnection: TObject;
    FTransaction: TObject;
    FDatabasePath: string;
    FIsOpen: Boolean;
    function EnsureOpen: TXrtlResult;
    function FailFromException(const ACode, AMessage: string): TXrtlResult;
    procedure EnsureTransactionStarted;
  public
    constructor Create;
    destructor Destroy; override;
    function Open(const AConfig: TXrtlSqliteConnectionConfig): TXrtlResult;
    function Close: TXrtlResult;
    function Execute(const ASql: string): TXrtlResult;
    function QueryInt64(const ASql: string; out AValue: Int64): TXrtlResult;
    property DatabasePath: string read FDatabasePath;
    property IsOpen: Boolean read FIsOpen;
  end;

implementation

uses
  SysUtils, SQLDB, SQLite3Conn;

class function TXrtlSqliteConnectionConfig.FileDatabase(const ADatabasePath: string): TXrtlSqliteConnectionConfig;
begin
  Result.FDatabasePath := ADatabasePath;
end;

class function TXrtlSqliteConnectionConfig.InMemory: TXrtlSqliteConnectionConfig;
begin
  Result.FDatabasePath := ':memory:';
end;

function TXrtlSqliteConnectionConfig.IsValid: Boolean;
begin
  Result := FDatabasePath <> '';
end;

function TXrtlSqliteConnectionConfig.IsInMemory: Boolean;
begin
  Result := FDatabasePath = ':memory:';
end;

constructor TXrtlSqliteDatabase.Create;
begin
  inherited Create;
  FConnection := nil;
  FTransaction := nil;
  FDatabasePath := '';
  FIsOpen := False;
end;

destructor TXrtlSqliteDatabase.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TXrtlSqliteDatabase.FailFromException(const ACode, AMessage: string): TXrtlResult;
begin
  Result := TXrtlResult.Fail(XRTL_DATABASE_ERROR_DOMAIN, ACode, AMessage);
end;

function TXrtlSqliteDatabase.EnsureOpen: TXrtlResult;
begin
  if FIsOpen and Assigned(FConnection) and TSQLite3Connection(FConnection).Connected then
    Exit(TXrtlResult.Ok);

  Result := TXrtlResult.Fail(
    XRTL_DATABASE_ERROR_DOMAIN,
    'not_open',
    'SQLite database is not open');
end;

procedure TXrtlSqliteDatabase.EnsureTransactionStarted;
begin
  if Assigned(FTransaction) and not TSQLTransaction(FTransaction).Active then
    TSQLTransaction(FTransaction).StartTransaction;
end;

function TXrtlSqliteDatabase.Open(const AConfig: TXrtlSqliteConnectionConfig): TXrtlResult;
begin
  if not AConfig.IsValid then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_config',
      'SQLite database path must not be empty'));

  if FIsOpen then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'already_open',
      'SQLite database is already open'));

  try
    FConnection := TSQLite3Connection.Create(nil);
    FTransaction := TSQLTransaction.Create(nil);

    FDatabasePath := AConfig.DatabasePath;
    TSQLite3Connection(FConnection).DatabaseName := FDatabasePath;
    TSQLite3Connection(FConnection).Transaction := TSQLTransaction(FTransaction);
    TSQLTransaction(FTransaction).Database := TSQLite3Connection(FConnection);

    TSQLite3Connection(FConnection).Open;
    FIsOpen := True;
    Result := TXrtlResult.Ok;
  except
    on E: Exception do
    begin
      FIsOpen := False;
      FreeAndNil(FTransaction);
      FreeAndNil(FConnection);
      FDatabasePath := '';
      Result := FailFromException('open_failed', E.Message);
    end;
  end;
end;

function TXrtlSqliteDatabase.Close: TXrtlResult;
begin
  try
    if Assigned(FTransaction) and TSQLTransaction(FTransaction).Active then
      TSQLTransaction(FTransaction).Rollback;
    if Assigned(FConnection) and TSQLite3Connection(FConnection).Connected then
      TSQLite3Connection(FConnection).Close;

    FreeAndNil(FTransaction);
    FreeAndNil(FConnection);
    FDatabasePath := '';
    FIsOpen := False;
    Result := TXrtlResult.Ok;
  except
    on E: Exception do
      Result := FailFromException('close_failed', E.Message);
  end;
end;

function TXrtlSqliteDatabase.Execute(const ASql: string): TXrtlResult;
var
  Query: TSQLQuery;
begin
  Result := EnsureOpen;
  if Result.Failed then
    Exit;
  if Trim(ASql) = '' then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'empty_sql',
      'SQL text must not be empty'));

  Query := TSQLQuery.Create(nil);
  try
    Query.DataBase := TSQLite3Connection(FConnection);
    Query.Transaction := TSQLTransaction(FTransaction);
    Query.SQL.Text := ASql;

    EnsureTransactionStarted;
    try
      Query.ExecSQL;
      TSQLTransaction(FTransaction).Commit;
      Result := TXrtlResult.Ok;
    except
      on E: Exception do
      begin
        if TSQLTransaction(FTransaction).Active then
          TSQLTransaction(FTransaction).Rollback;
        Result := FailFromException('execute_failed', E.Message);
      end;
    end;
  finally
    Query.Free;
  end;
end;

function TXrtlSqliteDatabase.QueryInt64(const ASql: string; out AValue: Int64): TXrtlResult;
var
  Query: TSQLQuery;
begin
  AValue := 0;
  Result := EnsureOpen;
  if Result.Failed then
    Exit;
  if Trim(ASql) = '' then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'empty_sql',
      'SQL text must not be empty'));

  Query := TSQLQuery.Create(nil);
  try
    Query.DataBase := TSQLite3Connection(FConnection);
    Query.Transaction := TSQLTransaction(FTransaction);
    Query.SQL.Text := ASql;

    EnsureTransactionStarted;
    try
      Query.Open;
      if Query.EOF or (Query.Fields.Count = 0) then
      begin
        if Query.Active then
          Query.Close;
        TSQLTransaction(FTransaction).Rollback;
        Exit(TXrtlResult.Fail(
          XRTL_DATABASE_ERROR_DOMAIN,
          'empty_result',
          'Query did not return a scalar value'));
      end;

      AValue := Query.Fields[0].AsLargeInt;
      Query.Close;
      TSQLTransaction(FTransaction).Commit;
      Result := TXrtlResult.Ok;
    except
      on E: Exception do
      begin
        if Query.Active then
          Query.Close;
        if TSQLTransaction(FTransaction).Active then
          TSQLTransaction(FTransaction).Rollback;
        Result := FailFromException('query_failed', E.Message);
      end;
    end;
  finally
    Query.Free;
  end;
end;

end.
