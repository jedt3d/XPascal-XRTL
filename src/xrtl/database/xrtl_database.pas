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
  TXrtlSqliteValueKind = (xsvNull, xsvText, xsvInt64);

  TXrtlSqliteValue = record
  private
    FKind: TXrtlSqliteValueKind;
    FTextValue: string;
    FInt64Value: Int64;
  public
    class function Null: TXrtlSqliteValue; static;
    class function Text(const AValue: string): TXrtlSqliteValue; static;
    class function Int64Value(const AValue: Int64): TXrtlSqliteValue; static;
    function IsNull: Boolean;
    property Kind: TXrtlSqliteValueKind read FKind;
    property TextValue: string read FTextValue;
    property Int64ValueData: Int64 read FInt64Value;
  end;

  TXrtlSqliteField = record
  private
    FName: string;
    FValue: TXrtlSqliteValue;
  public
    class function Create(const AName: string; const AValue: TXrtlSqliteValue): TXrtlSqliteField; static;
    property Name: string read FName;
    property Value: TXrtlSqliteValue read FValue;
  end;

  TXrtlSqliteRow = class
  private
    FFields: array of TXrtlSqliteField;
    function GetFieldCount: Integer;
    function GetField(const AIndex: Integer): TXrtlSqliteField;
  public
    procedure Clear;
    procedure AddField(const AField: TXrtlSqliteField);
    function FieldByIndex(const AIndex: Integer; out AField: TXrtlSqliteField): TXrtlResult;
    function IndexOfField(const AName: string): Integer;
    function FieldByName(const AName: string; out AField: TXrtlSqliteField): TXrtlResult;
    function ValueByName(const AName: string; out AValue: TXrtlSqliteValue): TXrtlResult;
    property FieldCount: Integer read GetFieldCount;
    property Fields[const AIndex: Integer]: TXrtlSqliteField read GetField; default;
  end;

  TXrtlSqliteResultSet = class
  private
    FColumns: array of string;
    FRows: array of TXrtlSqliteRow;
    function GetColumnCount: Integer;
    function GetColumnName(const AIndex: Integer): string;
    function GetRowCount: Integer;
    function GetRow(const AIndex: Integer): TXrtlSqliteRow;
  public
    destructor Destroy; override;
    procedure Clear;
    procedure AddColumn(const AName: string);
    function AddRow: TXrtlSqliteRow;
    function ColumnByIndex(const AIndex: Integer; out AName: string): TXrtlResult;
    function IndexOfColumn(const AName: string): Integer;
    function RowByIndex(const AIndex: Integer; out ARow: TXrtlSqliteRow): TXrtlResult;
    property ColumnCount: Integer read GetColumnCount;
    property ColumnNames[const AIndex: Integer]: string read GetColumnName;
    property RowCount: Integer read GetRowCount;
    property Rows[const AIndex: Integer]: TXrtlSqliteRow read GetRow; default;
  end;

  TXrtlSqliteParameterKind = (xspNull, xspText, xspInt64);

  TXrtlSqliteParameter = record
  private
    FName: string;
    FKind: TXrtlSqliteParameterKind;
    FTextValue: string;
    FInt64Value: Int64;
  public
    class function Text(const AName, AValue: string): TXrtlSqliteParameter; static;
    class function Int64Value(const AName: string; const AValue: Int64): TXrtlSqliteParameter; static;
    class function Null(const AName: string): TXrtlSqliteParameter; static;
    property Name: string read FName;
    property Kind: TXrtlSqliteParameterKind read FKind;
    property TextValue: string read FTextValue;
    property Int64ValueData: Int64 read FInt64Value;
  end;

  TXrtlSqliteParameters = class
  private
    FItems: array of TXrtlSqliteParameter;
    function GetCount: Integer;
    function GetItem(const AIndex: Integer): TXrtlSqliteParameter;
    procedure Add(const AParameter: TXrtlSqliteParameter);
  public
    procedure Clear;
    function AddText(const AName, AValue: string): TXrtlSqliteParameters;
    function AddInt64(const AName: string; const AValue: Int64): TXrtlSqliteParameters;
    function AddNull(const AName: string): TXrtlSqliteParameters;
    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: TXrtlSqliteParameter read GetItem; default;
  end;

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
    FExplicitTransaction: Boolean;
    function EnsureOpen: TXrtlResult;
    function FailFromException(const ACode, AMessage: string): TXrtlResult;
    function TransactionActive: Boolean;
    function ApplyParameters(const AQuery: TObject; const AParams: TXrtlSqliteParameters): TXrtlResult;
    function LoadResultSet(const AQuery: TObject; const ARows: TXrtlSqliteResultSet): TXrtlResult;
    procedure EnsureTransactionStarted;
  public
    constructor Create;
    destructor Destroy; override;
    function Open(const AConfig: TXrtlSqliteConnectionConfig): TXrtlResult;
    function Close: TXrtlResult;
    function BeginTransaction: TXrtlResult;
    function Commit: TXrtlResult;
    function Rollback: TXrtlResult;
    function InTransaction: Boolean;
    function Execute(const ASql: string): TXrtlResult; overload;
    function Execute(const ASql: string; const AParams: TXrtlSqliteParameters): TXrtlResult; overload;
    function QueryInt64(const ASql: string; out AValue: Int64): TXrtlResult; overload;
    function QueryInt64(const ASql: string; const AParams: TXrtlSqliteParameters; out AValue: Int64): TXrtlResult; overload;
    function QueryRows(const ASql: string; ARows: TXrtlSqliteResultSet): TXrtlResult; overload;
    function QueryRows(const ASql: string; const AParams: TXrtlSqliteParameters; ARows: TXrtlSqliteResultSet): TXrtlResult; overload;
    property DatabasePath: string read FDatabasePath;
    property IsOpen: Boolean read FIsOpen;
  end;

implementation

uses
  SysUtils, DB, SQLDB, SQLite3Conn;

class function TXrtlSqliteValue.Null: TXrtlSqliteValue;
begin
  Result.FKind := xsvNull;
  Result.FTextValue := '';
  Result.FInt64Value := 0;
end;

class function TXrtlSqliteValue.Text(const AValue: string): TXrtlSqliteValue;
begin
  Result.FKind := xsvText;
  Result.FTextValue := AValue;
  Result.FInt64Value := 0;
end;

class function TXrtlSqliteValue.Int64Value(const AValue: Int64): TXrtlSqliteValue;
begin
  Result.FKind := xsvInt64;
  Result.FTextValue := '';
  Result.FInt64Value := AValue;
end;

function TXrtlSqliteValue.IsNull: Boolean;
begin
  Result := FKind = xsvNull;
end;

class function TXrtlSqliteField.Create(const AName: string; const AValue: TXrtlSqliteValue): TXrtlSqliteField;
begin
  Result.FName := AName;
  Result.FValue := AValue;
end;

function TXrtlSqliteRow.GetFieldCount: Integer;
begin
  Result := Length(FFields);
end;

function TXrtlSqliteRow.GetField(const AIndex: Integer): TXrtlSqliteField;
begin
  if (AIndex < 0) or (AIndex >= Length(FFields)) then
    raise ERangeError.Create('SQLite row field index out of range');
  Result := FFields[AIndex];
end;

procedure TXrtlSqliteRow.Clear;
begin
  SetLength(FFields, 0);
end;

procedure TXrtlSqliteRow.AddField(const AField: TXrtlSqliteField);
begin
  SetLength(FFields, Length(FFields) + 1);
  FFields[High(FFields)] := AField;
end;

function TXrtlSqliteRow.FieldByIndex(const AIndex: Integer; out AField: TXrtlSqliteField): TXrtlResult;
begin
  if (AIndex < 0) or (AIndex >= Length(FFields)) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'field_index_out_of_range',
      'SQLite row field index is out of range'));

  AField := FFields[AIndex];
  Result := TXrtlResult.Ok;
end;

function TXrtlSqliteRow.IndexOfField(const AName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FFields) do
    if SameText(FFields[I].Name, AName) then
      Exit(I);
end;

function TXrtlSqliteRow.FieldByName(const AName: string; out AField: TXrtlSqliteField): TXrtlResult;
var
  Index: Integer;
begin
  Index := IndexOfField(AName);
  if Index < 0 then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'field_not_found',
      'SQLite row field was not found: ' + AName));

  AField := FFields[Index];
  Result := TXrtlResult.Ok;
end;

function TXrtlSqliteRow.ValueByName(const AName: string; out AValue: TXrtlSqliteValue): TXrtlResult;
var
  Field: TXrtlSqliteField;
begin
  Result := FieldByName(AName, Field);
  if Result.Failed then
    Exit;

  AValue := Field.Value;
  Result := TXrtlResult.Ok;
end;

function TXrtlSqliteResultSet.GetColumnCount: Integer;
begin
  Result := Length(FColumns);
end;

function TXrtlSqliteResultSet.GetColumnName(const AIndex: Integer): string;
begin
  if (AIndex < 0) or (AIndex >= Length(FColumns)) then
    raise ERangeError.Create('SQLite result column index out of range');
  Result := FColumns[AIndex];
end;

function TXrtlSqliteResultSet.GetRowCount: Integer;
begin
  Result := Length(FRows);
end;

function TXrtlSqliteResultSet.GetRow(const AIndex: Integer): TXrtlSqliteRow;
begin
  if (AIndex < 0) or (AIndex >= Length(FRows)) then
    raise ERangeError.Create('SQLite result row index out of range');
  Result := FRows[AIndex];
end;

destructor TXrtlSqliteResultSet.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TXrtlSqliteResultSet.Clear;
var
  I: Integer;
begin
  for I := 0 to High(FRows) do
    FRows[I].Free;
  SetLength(FRows, 0);
  SetLength(FColumns, 0);
end;

procedure TXrtlSqliteResultSet.AddColumn(const AName: string);
begin
  SetLength(FColumns, Length(FColumns) + 1);
  FColumns[High(FColumns)] := AName;
end;

function TXrtlSqliteResultSet.AddRow: TXrtlSqliteRow;
begin
  Result := TXrtlSqliteRow.Create;
  SetLength(FRows, Length(FRows) + 1);
  FRows[High(FRows)] := Result;
end;

function TXrtlSqliteResultSet.ColumnByIndex(const AIndex: Integer; out AName: string): TXrtlResult;
begin
  if (AIndex < 0) or (AIndex >= Length(FColumns)) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'column_index_out_of_range',
      'SQLite result column index is out of range'));

  AName := FColumns[AIndex];
  Result := TXrtlResult.Ok;
end;

function TXrtlSqliteResultSet.IndexOfColumn(const AName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FColumns) do
    if SameText(FColumns[I], AName) then
      Exit(I);
end;

function TXrtlSqliteResultSet.RowByIndex(const AIndex: Integer; out ARow: TXrtlSqliteRow): TXrtlResult;
begin
  if (AIndex < 0) or (AIndex >= Length(FRows)) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'row_index_out_of_range',
      'SQLite result row index is out of range'));

  ARow := FRows[AIndex];
  Result := TXrtlResult.Ok;
end;

class function TXrtlSqliteParameter.Text(const AName, AValue: string): TXrtlSqliteParameter;
begin
  Result.FName := AName;
  Result.FKind := xspText;
  Result.FTextValue := AValue;
  Result.FInt64Value := 0;
end;

class function TXrtlSqliteParameter.Int64Value(const AName: string; const AValue: Int64): TXrtlSqliteParameter;
begin
  Result.FName := AName;
  Result.FKind := xspInt64;
  Result.FTextValue := '';
  Result.FInt64Value := AValue;
end;

class function TXrtlSqliteParameter.Null(const AName: string): TXrtlSqliteParameter;
begin
  Result.FName := AName;
  Result.FKind := xspNull;
  Result.FTextValue := '';
  Result.FInt64Value := 0;
end;

function TXrtlSqliteParameters.GetCount: Integer;
begin
  Result := Length(FItems);
end;

function TXrtlSqliteParameters.GetItem(const AIndex: Integer): TXrtlSqliteParameter;
begin
  if (AIndex < 0) or (AIndex >= Length(FItems)) then
    raise ERangeError.Create('SQLite parameter index out of range');
  Result := FItems[AIndex];
end;

procedure TXrtlSqliteParameters.Add(const AParameter: TXrtlSqliteParameter);
begin
  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := AParameter;
end;

procedure TXrtlSqliteParameters.Clear;
begin
  SetLength(FItems, 0);
end;

function TXrtlSqliteParameters.AddText(const AName, AValue: string): TXrtlSqliteParameters;
begin
  Add(TXrtlSqliteParameter.Text(AName, AValue));
  Result := Self;
end;

function TXrtlSqliteParameters.AddInt64(const AName: string; const AValue: Int64): TXrtlSqliteParameters;
begin
  Add(TXrtlSqliteParameter.Int64Value(AName, AValue));
  Result := Self;
end;

function TXrtlSqliteParameters.AddNull(const AName: string): TXrtlSqliteParameters;
begin
  Add(TXrtlSqliteParameter.Null(AName));
  Result := Self;
end;

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
  FExplicitTransaction := False;
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

function TXrtlSqliteDatabase.TransactionActive: Boolean;
begin
  Result := Assigned(FTransaction) and TSQLTransaction(FTransaction).Active;
end;

function TXrtlSqliteDatabase.ApplyParameters(const AQuery: TObject; const AParams: TXrtlSqliteParameters): TXrtlResult;
var
  I: Integer;
  Parameter: TXrtlSqliteParameter;
  SqlParam: TParam;
begin
  if not Assigned(AParams) then
    Exit(TXrtlResult.Ok);

  try
    for I := 0 to AParams.Count - 1 do
    begin
      Parameter := AParams[I];
      if Trim(Parameter.Name) = '' then
        Exit(TXrtlResult.Fail(
          XRTL_DATABASE_ERROR_DOMAIN,
          'invalid_parameter',
          'SQLite parameter name must not be empty'));

      SqlParam := TSQLQuery(AQuery).Params.ParamByName(Parameter.Name);
      case Parameter.Kind of
        xspNull:
          begin
            SqlParam.Clear;
            SqlParam.Bound := True;
          end;
        xspText:
          SqlParam.AsString := Parameter.TextValue;
        xspInt64:
          SqlParam.AsLargeInt := Parameter.Int64ValueData;
      end;
    end;
    Result := TXrtlResult.Ok;
  except
    on E: Exception do
      Result := FailFromException('bind_failed', E.Message);
  end;
end;

function TXrtlSqliteDatabase.LoadResultSet(const AQuery: TObject; const ARows: TXrtlSqliteResultSet): TXrtlResult;
var
  Query: TSQLQuery;
  Row: TXrtlSqliteRow;
  I: Integer;
  FieldValue: TXrtlSqliteValue;
begin
  if not Assigned(ARows) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_result_set',
      'SQLite result set target must not be nil'));

  ARows.Clear;
  Query := TSQLQuery(AQuery);

  try
    for I := 0 to Query.Fields.Count - 1 do
      ARows.AddColumn(Query.Fields[I].FieldName);

    while not Query.EOF do
    begin
      Row := ARows.AddRow;
      for I := 0 to Query.Fields.Count - 1 do
      begin
        if Query.Fields[I].IsNull then
          FieldValue := TXrtlSqliteValue.Null
        else if Query.Fields[I].DataType in [ftSmallint, ftInteger, ftWord, ftAutoInc, ftLargeint] then
          FieldValue := TXrtlSqliteValue.Int64Value(Query.Fields[I].AsLargeInt)
        else
          FieldValue := TXrtlSqliteValue.Text(Query.Fields[I].AsString);
        Row.AddField(TXrtlSqliteField.Create(Query.Fields[I].FieldName, FieldValue));
      end;
      Query.Next;
    end;
    Result := TXrtlResult.Ok;
  except
    on E: Exception do
    begin
      ARows.Clear;
      Result := FailFromException('map_failed', E.Message);
    end;
  end;
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
    FExplicitTransaction := False;
    Result := TXrtlResult.Ok;
  except
    on E: Exception do
    begin
      FIsOpen := False;
      FreeAndNil(FTransaction);
      FreeAndNil(FConnection);
      FDatabasePath := '';
      FExplicitTransaction := False;
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
    FExplicitTransaction := False;
    Result := TXrtlResult.Ok;
  except
    on E: Exception do
      Result := FailFromException('close_failed', E.Message);
  end;
end;

function TXrtlSqliteDatabase.Execute(const ASql: string): TXrtlResult;
begin
  Result := Execute(ASql, nil);
end;

function TXrtlSqliteDatabase.BeginTransaction: TXrtlResult;
begin
  Result := EnsureOpen;
  if Result.Failed then
    Exit;

  if FExplicitTransaction or TransactionActive then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'transaction_active',
      'SQLite transaction is already active'));

  try
    TSQLTransaction(FTransaction).StartTransaction;
    FExplicitTransaction := True;
    Result := TXrtlResult.Ok;
  except
    on E: Exception do
      Result := FailFromException('begin_failed', E.Message);
  end;
end;

function TXrtlSqliteDatabase.Commit: TXrtlResult;
begin
  Result := EnsureOpen;
  if Result.Failed then
    Exit;

  if not InTransaction then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'no_transaction',
      'SQLite transaction is not active'));

  try
    TSQLTransaction(FTransaction).Commit;
    FExplicitTransaction := False;
    Result := TXrtlResult.Ok;
  except
    on E: Exception do
      Result := FailFromException('commit_failed', E.Message);
  end;
end;

function TXrtlSqliteDatabase.Rollback: TXrtlResult;
begin
  Result := EnsureOpen;
  if Result.Failed then
    Exit;

  if not InTransaction then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'no_transaction',
      'SQLite transaction is not active'));

  try
    TSQLTransaction(FTransaction).Rollback;
    FExplicitTransaction := False;
    Result := TXrtlResult.Ok;
  except
    on E: Exception do
      Result := FailFromException('rollback_failed', E.Message);
  end;
end;

function TXrtlSqliteDatabase.InTransaction: Boolean;
begin
  Result := FExplicitTransaction and TransactionActive;
end;

function TXrtlSqliteDatabase.Execute(const ASql: string; const AParams: TXrtlSqliteParameters): TXrtlResult;
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

    Result := ApplyParameters(Query, AParams);
    if Result.Failed then
      Exit;

    EnsureTransactionStarted;
    try
      Query.ExecSQL;
      if not FExplicitTransaction then
        TSQLTransaction(FTransaction).Commit;
      Result := TXrtlResult.Ok;
    except
      on E: Exception do
      begin
        if (not FExplicitTransaction) and TSQLTransaction(FTransaction).Active then
          TSQLTransaction(FTransaction).Rollback;
        Result := FailFromException('execute_failed', E.Message);
      end;
    end;
  finally
    Query.Free;
  end;
end;

function TXrtlSqliteDatabase.QueryInt64(const ASql: string; out AValue: Int64): TXrtlResult;
begin
  Result := QueryInt64(ASql, nil, AValue);
end;

function TXrtlSqliteDatabase.QueryInt64(const ASql: string; const AParams: TXrtlSqliteParameters; out AValue: Int64): TXrtlResult;
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

    Result := ApplyParameters(Query, AParams);
    if Result.Failed then
      Exit;

    EnsureTransactionStarted;
    try
      Query.Open;
      if Query.EOF or (Query.Fields.Count = 0) then
      begin
        if Query.Active then
          Query.Close;
        if not FExplicitTransaction then
          TSQLTransaction(FTransaction).Rollback;
        Exit(TXrtlResult.Fail(
          XRTL_DATABASE_ERROR_DOMAIN,
          'empty_result',
          'Query did not return a scalar value'));
      end;

      AValue := Query.Fields[0].AsLargeInt;
      Query.Close;
      if not FExplicitTransaction then
        TSQLTransaction(FTransaction).Commit;
      Result := TXrtlResult.Ok;
    except
      on E: Exception do
      begin
        if Query.Active then
          Query.Close;
        if (not FExplicitTransaction) and TSQLTransaction(FTransaction).Active then
          TSQLTransaction(FTransaction).Rollback;
        Result := FailFromException('query_failed', E.Message);
      end;
    end;
  finally
    Query.Free;
  end;
end;

function TXrtlSqliteDatabase.QueryRows(const ASql: string; ARows: TXrtlSqliteResultSet): TXrtlResult;
begin
  Result := QueryRows(ASql, nil, ARows);
end;

function TXrtlSqliteDatabase.QueryRows(const ASql: string; const AParams: TXrtlSqliteParameters; ARows: TXrtlSqliteResultSet): TXrtlResult;
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
  if not Assigned(ARows) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_result_set',
      'SQLite result set target must not be nil'));

  Query := TSQLQuery.Create(nil);
  try
    Query.DataBase := TSQLite3Connection(FConnection);
    Query.Transaction := TSQLTransaction(FTransaction);
    Query.SQL.Text := ASql;

    Result := ApplyParameters(Query, AParams);
    if Result.Failed then
      Exit;

    EnsureTransactionStarted;
    try
      Query.Open;
      Result := LoadResultSet(Query, ARows);
      Query.Close;
      if Result.Failed then
      begin
        if not FExplicitTransaction and TSQLTransaction(FTransaction).Active then
          TSQLTransaction(FTransaction).Rollback;
        Exit;
      end;

      if not FExplicitTransaction then
        TSQLTransaction(FTransaction).Commit;
      Result := TXrtlResult.Ok;
    except
      on E: Exception do
      begin
        if Query.Active then
          Query.Close;
        if (not FExplicitTransaction) and TSQLTransaction(FTransaction).Active then
          TSQLTransaction(FTransaction).Rollback;
        ARows.Clear;
        Result := FailFromException('query_failed', E.Message);
      end;
    end;
  finally
    Query.Free;
  end;
end;

end.
