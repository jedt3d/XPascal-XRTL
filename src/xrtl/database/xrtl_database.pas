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

  TXrtlSqliteDataSet = class
  private
    FRows: TXrtlSqliteResultSet;
    FCurrentIndex: Integer;
    FActive: Boolean;
    function GetRecordCount: Integer;
    function GetFieldCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function LoadFromResultSet(const ASource: TXrtlSqliteResultSet): TXrtlResult;
    function First: TXrtlResult;
    function Next: TXrtlResult;
    function Eof: Boolean;
    function CurrentRow(out ARow: TXrtlSqliteRow): TXrtlResult;
    function ValueByName(const AName: string; out AValue: TXrtlSqliteValue): TXrtlResult;
    property Active: Boolean read FActive;
    property CurrentIndex: Integer read FCurrentIndex;
    property RecordCount: Integer read GetRecordCount;
    property FieldCount: Integer read GetFieldCount;
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
    function QueryDataSet(const ASql: string; ADataSet: TXrtlSqliteDataSet): TXrtlResult; overload;
    function QueryDataSet(const ASql: string; const AParams: TXrtlSqliteParameters; ADataSet: TXrtlSqliteDataSet): TXrtlResult; overload;
    property DatabasePath: string read FDatabasePath;
    property IsOpen: Boolean read FIsOpen;
  end;

  TXrtlDatabaseProviderKind = (xdpSqlite);

  TXrtlDatabaseProviderCapabilities = record
  private
    FProviderKind: TXrtlDatabaseProviderKind;
    FName: string;
    FLocalOnly: Boolean;
    FSupportsTransactions: Boolean;
    FSupportsParameters: Boolean;
    FSupportsRawResults: Boolean;
    FSupportsDataSets: Boolean;
  public
    class function SQLite: TXrtlDatabaseProviderCapabilities; static;
    property ProviderKind: TXrtlDatabaseProviderKind read FProviderKind;
    property Name: string read FName;
    property LocalOnly: Boolean read FLocalOnly;
    property SupportsTransactions: Boolean read FSupportsTransactions;
    property SupportsParameters: Boolean read FSupportsParameters;
    property SupportsRawResults: Boolean read FSupportsRawResults;
    property SupportsDataSets: Boolean read FSupportsDataSets;
  end;

  TXrtlDatabaseConnectionConfig = record
  private
    FProviderKind: TXrtlDatabaseProviderKind;
    FSqliteConfig: TXrtlSqliteConnectionConfig;
  public
    class function SQLiteFile(const ADatabasePath: string): TXrtlDatabaseConnectionConfig; static;
    class function SQLiteInMemory: TXrtlDatabaseConnectionConfig; static;
    function IsValid: Boolean;
    property ProviderKind: TXrtlDatabaseProviderKind read FProviderKind;
    property SqliteConfig: TXrtlSqliteConnectionConfig read FSqliteConfig;
  end;

  TXrtlDatabaseValueKind = TXrtlSqliteValueKind;
  TXrtlDatabaseValue = TXrtlSqliteValue;
  TXrtlDatabaseField = TXrtlSqliteField;
  TXrtlDatabaseRow = TXrtlSqliteRow;
  TXrtlDatabaseResultSet = TXrtlSqliteResultSet;
  TXrtlDatabaseParameterKind = TXrtlSqliteParameterKind;
  TXrtlDatabaseParameter = TXrtlSqliteParameter;
  TXrtlDatabaseParameters = TXrtlSqliteParameters;
  TXrtlDatabaseDataSet = TXrtlSqliteDataSet;

  TXrtlDatabaseConnection = class
  private
    FProviderKind: TXrtlDatabaseProviderKind;
    FSqliteDatabase: TXrtlSqliteDatabase;
    function GetIsOpen: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Capabilities: TXrtlDatabaseProviderCapabilities;
    function Open(const AConfig: TXrtlDatabaseConnectionConfig): TXrtlResult;
    function Close: TXrtlResult;
    function BeginTransaction: TXrtlResult;
    function Commit: TXrtlResult;
    function Rollback: TXrtlResult;
    function InTransaction: Boolean;
    function Execute(const ASql: string): TXrtlResult; overload;
    function Execute(const ASql: string; const AParams: TXrtlDatabaseParameters): TXrtlResult; overload;
    function QueryInt64(const ASql: string; out AValue: Int64): TXrtlResult; overload;
    function QueryInt64(const ASql: string; const AParams: TXrtlDatabaseParameters; out AValue: Int64): TXrtlResult; overload;
    function QueryRows(const ASql: string; ARows: TXrtlDatabaseResultSet): TXrtlResult; overload;
    function QueryRows(const ASql: string; const AParams: TXrtlDatabaseParameters; ARows: TXrtlDatabaseResultSet): TXrtlResult; overload;
    function QueryDataSet(const ASql: string; ADataSet: TXrtlDatabaseDataSet): TXrtlResult; overload;
    function QueryDataSet(const ASql: string; const AParams: TXrtlDatabaseParameters; ADataSet: TXrtlDatabaseDataSet): TXrtlResult; overload;
    property ProviderKind: TXrtlDatabaseProviderKind read FProviderKind;
    property IsOpen: Boolean read GetIsOpen;
  end;

  TXrtlDatabaseMigration = record
  private
    FId: string;
    FDescription: string;
    FStatements: array of string;
    function GetStatementCount: Integer;
    function GetStatement(const AIndex: Integer): string;
  public
    class function Create(const AId, ADescription: string): TXrtlDatabaseMigration; static;
    procedure ClearStatements;
    function AddStatement(const ASql: string): TXrtlResult;
    property Id: string read FId;
    property Description: string read FDescription;
    property StatementCount: Integer read GetStatementCount;
    property Statements[const AIndex: Integer]: string read GetStatement;
  end;

  TXrtlDatabaseMigrationPlan = class
  private
    FItems: array of TXrtlDatabaseMigration;
    function GetCount: Integer;
    function GetItem(const AIndex: Integer): TXrtlDatabaseMigration;
  public
    procedure Clear;
    function Add(const AMigration: TXrtlDatabaseMigration): TXrtlResult;
    function IndexOfId(const AId: string): Integer;
    function Validate: TXrtlResult;
    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: TXrtlDatabaseMigration read GetItem; default;
  end;

  TXrtlDatabaseMigrationRunner = class
  private
    FConnection: TXrtlDatabaseConnection;
    FMetadataTableName: string;
    function EnsureMetadataTable: TXrtlResult;
    function MigrationApplied(const AId: string; out AApplied: Boolean): TXrtlResult;
    function NextAppliedOrder(out AOrder: Int64): TXrtlResult;
    function ApplyMigration(const AMigration: TXrtlDatabaseMigration; var AAppliedCount: Integer): TXrtlResult;
    function FailMigration(const AMigration: TXrtlDatabaseMigration; const ACode: string; const ACause: TXrtlResult): TXrtlResult;
  public
    constructor Create(const AConnection: TXrtlDatabaseConnection);
    function Apply(const APlan: TXrtlDatabaseMigrationPlan; out AAppliedCount: Integer): TXrtlResult;
    property MetadataTableName: string read FMetadataTableName;
  end;

  TXrtlDatabaseSortDirection = (xsdAscending, xsdDescending);

  TXrtlDatabaseSelectBuilder = class
  private
    FTableName: string;
    FColumns: array of string;
    FWhereClauses: array of string;
    FOrderByClauses: array of string;
    FParameters: array of TXrtlDatabaseParameter;
    FHasLimit: Boolean;
    FLimit: Int64;
    function GetColumnCount: Integer;
    function GetWhereCount: Integer;
    function GetOrderByCount: Integer;
    function GetParameterCount: Integer;
    function IndexOfParameter(const AName: string): Integer;
    procedure AddParameter(const AParameter: TXrtlDatabaseParameter);
  public
    procedure Clear;
    function FromTable(const ATableName: string): TXrtlResult;
    function AddColumn(const AColumnName: string): TXrtlResult;
    function WhereTextEquals(const AColumnName, AParameterName, AValue: string): TXrtlResult;
    function WhereInt64Equals(const AColumnName, AParameterName: string; const AValue: Int64): TXrtlResult;
    function AddOrderBy(const AColumnName: string; const ADirection: TXrtlDatabaseSortDirection): TXrtlResult;
    function SetLimit(const ARowLimit: Int64): TXrtlResult;
    function Build(out ASql: string; const AParams: TXrtlDatabaseParameters): TXrtlResult;
    property TableName: string read FTableName;
    property ColumnCount: Integer read GetColumnCount;
    property WhereCount: Integer read GetWhereCount;
    property OrderByCount: Integer read GetOrderByCount;
    property ParameterCount: Integer read GetParameterCount;
    property HasLimit: Boolean read FHasLimit;
    property RowLimit: Int64 read FLimit;
  end;

implementation

uses
  SysUtils, Math, DB, SQLDB, SQLite3Conn;

function XrtlSqliteCallMask(const ACurrentMask: TFPUExceptionMask): TFPUExceptionMask;
begin
  Result := ACurrentMask + [exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision];
end;

function XrtlDatabaseIsIdentifierStart(const AChar: Char): Boolean;
begin
  Result := ((AChar >= 'A') and (AChar <= 'Z')) or
    ((AChar >= 'a') and (AChar <= 'z')) or
    (AChar = '_');
end;

function XrtlDatabaseIsIdentifierPart(const AChar: Char): Boolean;
begin
  Result := XrtlDatabaseIsIdentifierStart(AChar) or
    ((AChar >= '0') and (AChar <= '9'));
end;

function XrtlDatabaseIsValidIdentifier(const AValue: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  if AValue = '' then
    Exit;
  if not XrtlDatabaseIsIdentifierStart(AValue[1]) then
    Exit;
  for I := 2 to Length(AValue) do
    if not XrtlDatabaseIsIdentifierPart(AValue[I]) then
      Exit;
  Result := True;
end;

function XrtlDatabaseIsValidIdentifierPath(const AValue: string): Boolean;
var
  I: Integer;
  PartStart: Integer;
  Part: string;
begin
  Result := False;
  if AValue = '' then
    Exit;

  PartStart := 1;
  for I := 1 to Length(AValue) + 1 do
    if (I > Length(AValue)) or (AValue[I] = '.') then
    begin
      Part := Copy(AValue, PartStart, I - PartStart);
      if not XrtlDatabaseIsValidIdentifier(Part) then
        Exit;
      PartStart := I + 1;
    end;

  Result := True;
end;

function XrtlDatabaseJoinStrings(const AItems: array of string; const ASeparator: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := Low(AItems) to High(AItems) do
  begin
    if Result <> '' then
      Result := Result + ASeparator;
    Result := Result + AItems[I];
  end;
end;

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

constructor TXrtlSqliteDataSet.Create;
begin
  inherited Create;
  FRows := TXrtlSqliteResultSet.Create;
  FCurrentIndex := -1;
  FActive := False;
end;

destructor TXrtlSqliteDataSet.Destroy;
begin
  FRows.Free;
  inherited Destroy;
end;

function TXrtlSqliteDataSet.GetRecordCount: Integer;
begin
  Result := FRows.RowCount;
end;

function TXrtlSqliteDataSet.GetFieldCount: Integer;
begin
  Result := FRows.ColumnCount;
end;

procedure TXrtlSqliteDataSet.Clear;
begin
  FRows.Clear;
  FCurrentIndex := -1;
  FActive := False;
end;

function TXrtlSqliteDataSet.LoadFromResultSet(const ASource: TXrtlSqliteResultSet): TXrtlResult;
var
  I: Integer;
  J: Integer;
  ColumnName: string;
  SourceRow: TXrtlSqliteRow;
  TargetRow: TXrtlSqliteRow;
  Field: TXrtlSqliteField;
begin
  Clear;
  if not Assigned(ASource) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_result_set',
      'SQLite result set source must not be nil'));

  try
    for I := 0 to ASource.ColumnCount - 1 do
    begin
      Result := ASource.ColumnByIndex(I, ColumnName);
      if Result.Failed then
      begin
        Clear;
        Exit;
      end;
      FRows.AddColumn(ColumnName);
    end;

    for I := 0 to ASource.RowCount - 1 do
    begin
      Result := ASource.RowByIndex(I, SourceRow);
      if Result.Failed then
      begin
        Clear;
        Exit;
      end;

      TargetRow := FRows.AddRow;
      for J := 0 to SourceRow.FieldCount - 1 do
      begin
        Result := SourceRow.FieldByIndex(J, Field);
        if Result.Failed then
        begin
          Clear;
          Exit;
        end;
        TargetRow.AddField(Field);
      end;
    end;

    FActive := True;
    if FRows.RowCount > 0 then
      FCurrentIndex := 0
    else
      FCurrentIndex := -1;
    Result := TXrtlResult.Ok;
  except
    on E: Exception do
    begin
      Clear;
      Result := TXrtlResult.Fail(
        XRTL_DATABASE_ERROR_DOMAIN,
        'dataset_load_failed',
        E.Message);
    end;
  end;
end;

function TXrtlSqliteDataSet.First: TXrtlResult;
begin
  if not FActive then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'dataset_not_active',
      'SQLite dataset is not active'));

  if FRows.RowCount > 0 then
    FCurrentIndex := 0
  else
    FCurrentIndex := -1;
  Result := TXrtlResult.Ok;
end;

function TXrtlSqliteDataSet.Next: TXrtlResult;
begin
  if not FActive then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'dataset_not_active',
      'SQLite dataset is not active'));

  if FRows.RowCount = 0 then
    FCurrentIndex := -1
  else if FCurrentIndex < FRows.RowCount then
    Inc(FCurrentIndex);
  Result := TXrtlResult.Ok;
end;

function TXrtlSqliteDataSet.Eof: Boolean;
begin
  Result := (not FActive) or (FCurrentIndex < 0) or (FCurrentIndex >= FRows.RowCount);
end;

function TXrtlSqliteDataSet.CurrentRow(out ARow: TXrtlSqliteRow): TXrtlResult;
begin
  if not FActive then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'dataset_not_active',
      'SQLite dataset is not active'));
  if Eof then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'no_current_row',
      'SQLite dataset has no current row'));

  Result := FRows.RowByIndex(FCurrentIndex, ARow);
end;

function TXrtlSqliteDataSet.ValueByName(const AName: string; out AValue: TXrtlSqliteValue): TXrtlResult;
var
  Row: TXrtlSqliteRow;
begin
  Result := CurrentRow(Row);
  if Result.Failed then
    Exit;

  Result := Row.ValueByName(AName, AValue);
end;

class function TXrtlDatabaseProviderCapabilities.SQLite: TXrtlDatabaseProviderCapabilities;
begin
  Result.FProviderKind := xdpSqlite;
  Result.FName := 'sqlite';
  Result.FLocalOnly := True;
  Result.FSupportsTransactions := True;
  Result.FSupportsParameters := True;
  Result.FSupportsRawResults := True;
  Result.FSupportsDataSets := True;
end;

class function TXrtlDatabaseConnectionConfig.SQLiteFile(const ADatabasePath: string): TXrtlDatabaseConnectionConfig;
begin
  Result.FProviderKind := xdpSqlite;
  Result.FSqliteConfig := TXrtlSqliteConnectionConfig.FileDatabase(ADatabasePath);
end;

class function TXrtlDatabaseConnectionConfig.SQLiteInMemory: TXrtlDatabaseConnectionConfig;
begin
  Result.FProviderKind := xdpSqlite;
  Result.FSqliteConfig := TXrtlSqliteConnectionConfig.InMemory;
end;

function TXrtlDatabaseConnectionConfig.IsValid: Boolean;
begin
  case FProviderKind of
    xdpSqlite:
      Result := FSqliteConfig.IsValid;
  else
    Result := False;
  end;
end;

constructor TXrtlDatabaseConnection.Create;
begin
  inherited Create;
  FProviderKind := xdpSqlite;
  FSqliteDatabase := TXrtlSqliteDatabase.Create;
end;

destructor TXrtlDatabaseConnection.Destroy;
begin
  FSqliteDatabase.Free;
  inherited Destroy;
end;

function TXrtlDatabaseConnection.GetIsOpen: Boolean;
begin
  Result := Assigned(FSqliteDatabase) and FSqliteDatabase.IsOpen;
end;

function TXrtlDatabaseConnection.Capabilities: TXrtlDatabaseProviderCapabilities;
begin
  case FProviderKind of
    xdpSqlite:
      Result := TXrtlDatabaseProviderCapabilities.SQLite;
  end;
end;

function TXrtlDatabaseConnection.Open(const AConfig: TXrtlDatabaseConnectionConfig): TXrtlResult;
begin
  case AConfig.ProviderKind of
    xdpSqlite:
      begin
        FProviderKind := xdpSqlite;
        Result := FSqliteDatabase.Open(AConfig.SqliteConfig);
      end;
  else
    Result := TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'unsupported_provider',
      'Database provider is not supported');
  end;
end;

function TXrtlDatabaseConnection.Close: TXrtlResult;
begin
  Result := FSqliteDatabase.Close;
end;

function TXrtlDatabaseConnection.BeginTransaction: TXrtlResult;
begin
  Result := FSqliteDatabase.BeginTransaction;
end;

function TXrtlDatabaseConnection.Commit: TXrtlResult;
begin
  Result := FSqliteDatabase.Commit;
end;

function TXrtlDatabaseConnection.Rollback: TXrtlResult;
begin
  Result := FSqliteDatabase.Rollback;
end;

function TXrtlDatabaseConnection.InTransaction: Boolean;
begin
  Result := FSqliteDatabase.InTransaction;
end;

function TXrtlDatabaseConnection.Execute(const ASql: string): TXrtlResult;
begin
  Result := FSqliteDatabase.Execute(ASql);
end;

function TXrtlDatabaseConnection.Execute(const ASql: string; const AParams: TXrtlDatabaseParameters): TXrtlResult;
begin
  Result := FSqliteDatabase.Execute(ASql, AParams);
end;

function TXrtlDatabaseConnection.QueryInt64(const ASql: string; out AValue: Int64): TXrtlResult;
begin
  Result := FSqliteDatabase.QueryInt64(ASql, AValue);
end;

function TXrtlDatabaseConnection.QueryInt64(const ASql: string; const AParams: TXrtlDatabaseParameters; out AValue: Int64): TXrtlResult;
begin
  Result := FSqliteDatabase.QueryInt64(ASql, AParams, AValue);
end;

function TXrtlDatabaseConnection.QueryRows(const ASql: string; ARows: TXrtlDatabaseResultSet): TXrtlResult;
begin
  Result := FSqliteDatabase.QueryRows(ASql, ARows);
end;

function TXrtlDatabaseConnection.QueryRows(const ASql: string; const AParams: TXrtlDatabaseParameters; ARows: TXrtlDatabaseResultSet): TXrtlResult;
begin
  Result := FSqliteDatabase.QueryRows(ASql, AParams, ARows);
end;

function TXrtlDatabaseConnection.QueryDataSet(const ASql: string; ADataSet: TXrtlDatabaseDataSet): TXrtlResult;
begin
  Result := FSqliteDatabase.QueryDataSet(ASql, ADataSet);
end;

function TXrtlDatabaseConnection.QueryDataSet(const ASql: string; const AParams: TXrtlDatabaseParameters; ADataSet: TXrtlDatabaseDataSet): TXrtlResult;
begin
  Result := FSqliteDatabase.QueryDataSet(ASql, AParams, ADataSet);
end;

class function TXrtlDatabaseMigration.Create(const AId, ADescription: string): TXrtlDatabaseMigration;
begin
  Result.FId := AId;
  Result.FDescription := ADescription;
  SetLength(Result.FStatements, 0);
end;

function TXrtlDatabaseMigration.GetStatementCount: Integer;
begin
  Result := Length(FStatements);
end;

function TXrtlDatabaseMigration.GetStatement(const AIndex: Integer): string;
begin
  if (AIndex < 0) or (AIndex >= Length(FStatements)) then
    raise ERangeError.Create('Database migration statement index out of range');
  Result := FStatements[AIndex];
end;

procedure TXrtlDatabaseMigration.ClearStatements;
begin
  SetLength(FStatements, 0);
end;

function TXrtlDatabaseMigration.AddStatement(const ASql: string): TXrtlResult;
begin
  if Trim(ASql) = '' then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_migration',
      'Migration statement SQL must not be empty'));

  SetLength(FStatements, Length(FStatements) + 1);
  FStatements[High(FStatements)] := ASql;
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseMigrationPlan.GetCount: Integer;
begin
  Result := Length(FItems);
end;

function TXrtlDatabaseMigrationPlan.GetItem(const AIndex: Integer): TXrtlDatabaseMigration;
begin
  if (AIndex < 0) or (AIndex >= Length(FItems)) then
    raise ERangeError.Create('Database migration index out of range');
  Result := FItems[AIndex];
end;

procedure TXrtlDatabaseMigrationPlan.Clear;
begin
  SetLength(FItems, 0);
end;

function TXrtlDatabaseMigrationPlan.IndexOfId(const AId: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FItems) do
    if SameText(FItems[I].Id, AId) then
      Exit(I);
end;

function TXrtlDatabaseMigrationPlan.Add(const AMigration: TXrtlDatabaseMigration): TXrtlResult;
begin
  if Trim(AMigration.Id) = '' then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_migration',
      'Migration id must not be empty'));

  if IndexOfId(AMigration.Id) >= 0 then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'duplicate_migration',
      'Migration id is duplicated in the plan: ' + AMigration.Id));

  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := AMigration;
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseMigrationPlan.Validate: TXrtlResult;
var
  I: Integer;
  J: Integer;
begin
  for I := 0 to High(FItems) do
  begin
    if Trim(FItems[I].Id) = '' then
      Exit(TXrtlResult.Fail(
        XRTL_DATABASE_ERROR_DOMAIN,
        'invalid_migration',
        'Migration id must not be empty'));

    if FItems[I].StatementCount = 0 then
      Exit(TXrtlResult.Fail(
        XRTL_DATABASE_ERROR_DOMAIN,
        'invalid_migration',
        'Migration must include at least one SQL statement: ' + FItems[I].Id));

    for J := 0 to FItems[I].StatementCount - 1 do
      if Trim(FItems[I].Statements[J]) = '' then
        Exit(TXrtlResult.Fail(
          XRTL_DATABASE_ERROR_DOMAIN,
          'invalid_migration',
          'Migration statement SQL must not be empty: ' + FItems[I].Id));

    for J := I + 1 to High(FItems) do
      if SameText(FItems[I].Id, FItems[J].Id) then
        Exit(TXrtlResult.Fail(
          XRTL_DATABASE_ERROR_DOMAIN,
          'duplicate_migration',
          'Migration id is duplicated in the plan: ' + FItems[I].Id));
  end;

  Result := TXrtlResult.Ok;
end;

constructor TXrtlDatabaseMigrationRunner.Create(const AConnection: TXrtlDatabaseConnection);
begin
  inherited Create;
  FConnection := AConnection;
  FMetadataTableName := 'xrtl_schema_migrations';
end;

function TXrtlDatabaseMigrationRunner.EnsureMetadataTable: TXrtlResult;
begin
  if not Assigned(FConnection) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_connection',
      'Database migration runner requires a connection'));

  Result := FConnection.Execute(
    'create table if not exists xrtl_schema_migrations (' +
    'id text primary key not null, ' +
    'description text not null, ' +
    'applied_order integer not null, ' +
    'applied_at_utc text not null)');
end;

function TXrtlDatabaseMigrationRunner.MigrationApplied(const AId: string; out AApplied: Boolean): TXrtlResult;
var
  Params: TXrtlDatabaseParameters;
  Count: Int64;
begin
  AApplied := False;
  Params := TXrtlDatabaseParameters.Create;
  try
    Params.AddText('id', AId);
    Result := FConnection.QueryInt64(
      'select count(*) from xrtl_schema_migrations where id = :id',
      Params,
      Count);
    if Result.Failed then
      Exit;

    AApplied := Count > 0;
    Result := TXrtlResult.Ok;
  finally
    Params.Free;
  end;
end;

function TXrtlDatabaseMigrationRunner.NextAppliedOrder(out AOrder: Int64): TXrtlResult;
begin
  AOrder := 0;
  Result := FConnection.QueryInt64(
    'select count(*) + 1 from xrtl_schema_migrations',
    AOrder);
end;

function TXrtlDatabaseMigrationRunner.FailMigration(const AMigration: TXrtlDatabaseMigration; const ACode: string; const ACause: TXrtlResult): TXrtlResult;
begin
  Result := TXrtlResult.Fail(
    XRTL_DATABASE_ERROR_DOMAIN,
    ACode,
    'Migration ' + AMigration.Id + ' failed: ' + ACause.Error.Code + ': ' + ACause.Error.Message);
end;

function TXrtlDatabaseMigrationRunner.ApplyMigration(const AMigration: TXrtlDatabaseMigration; var AAppliedCount: Integer): TXrtlResult;
var
  I: Integer;
  Params: TXrtlDatabaseParameters;
  AppliedOrder: Int64;
  Cause: TXrtlResult;
begin
  Result := FConnection.BeginTransaction;
  if Result.Failed then
    Exit;

  for I := 0 to AMigration.StatementCount - 1 do
  begin
    Result := FConnection.Execute(AMigration.Statements[I]);
    if Result.Failed then
    begin
      Cause := Result;
      Result := FConnection.Rollback;
      if Result.Failed then
        Exit(FailMigration(AMigration, 'migration_rollback_failed', Result));
      Exit(FailMigration(AMigration, 'migration_failed', Cause));
    end;
  end;

  Result := NextAppliedOrder(AppliedOrder);
  if Result.Failed then
  begin
    Cause := Result;
    Result := FConnection.Rollback;
    if Result.Failed then
      Exit(FailMigration(AMigration, 'migration_rollback_failed', Result));
    Exit(FailMigration(AMigration, 'migration_failed', Cause));
  end;

  Params := TXrtlDatabaseParameters.Create;
  try
    Params.AddText('id', AMigration.Id);
    Params.AddText('description', AMigration.Description);
    Params.AddInt64('applied_order', AppliedOrder);
    Result := FConnection.Execute(
      'insert into xrtl_schema_migrations(id, description, applied_order, applied_at_utc) ' +
      'values (:id, :description, :applied_order, strftime(''%Y-%m-%dT%H:%M:%fZ'', ''now''))',
      Params);
  finally
    Params.Free;
  end;

  if Result.Failed then
  begin
    Cause := Result;
    Result := FConnection.Rollback;
    if Result.Failed then
      Exit(FailMigration(AMigration, 'migration_rollback_failed', Result));
    Exit(FailMigration(AMigration, 'migration_failed', Cause));
  end;

  Result := FConnection.Commit;
  if Result.Failed then
    Exit(FailMigration(AMigration, 'migration_commit_failed', Result));

  Inc(AAppliedCount);
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseMigrationRunner.Apply(const APlan: TXrtlDatabaseMigrationPlan; out AAppliedCount: Integer): TXrtlResult;
var
  I: Integer;
  FoundPending: Boolean;
  AppliedStates: array of Boolean;
  Applied: Boolean;
begin
  AAppliedCount := 0;
  if not Assigned(APlan) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_migration_plan',
      'Migration plan must not be nil'));

  Result := APlan.Validate;
  if Result.Failed then
    Exit;

  if Assigned(FConnection) and FConnection.InTransaction then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'migration_transaction_active',
      'Migrations cannot run inside an existing transaction'));

  Result := EnsureMetadataTable;
  if Result.Failed then
    Exit;

  SetLength(AppliedStates, APlan.Count);
  FoundPending := False;
  for I := 0 to APlan.Count - 1 do
  begin
    Result := MigrationApplied(APlan[I].Id, Applied);
    if Result.Failed then
      Exit;

    AppliedStates[I] := Applied;
    if Applied then
    begin
      if FoundPending then
        Exit(TXrtlResult.Fail(
          XRTL_DATABASE_ERROR_DOMAIN,
          'migration_out_of_order',
          'Migration is already applied after a pending migration: ' + APlan[I].Id));
    end
    else
      FoundPending := True;
  end;

  for I := 0 to APlan.Count - 1 do
    if not AppliedStates[I] then
    begin
      Result := ApplyMigration(APlan[I], AAppliedCount);
      if Result.Failed then
        Exit;
    end;

  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseSelectBuilder.GetColumnCount: Integer;
begin
  Result := Length(FColumns);
end;

function TXrtlDatabaseSelectBuilder.GetWhereCount: Integer;
begin
  Result := Length(FWhereClauses);
end;

function TXrtlDatabaseSelectBuilder.GetOrderByCount: Integer;
begin
  Result := Length(FOrderByClauses);
end;

function TXrtlDatabaseSelectBuilder.GetParameterCount: Integer;
begin
  Result := Length(FParameters);
end;

function TXrtlDatabaseSelectBuilder.IndexOfParameter(const AName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FParameters) do
    if SameText(FParameters[I].Name, AName) then
      Exit(I);
end;

procedure TXrtlDatabaseSelectBuilder.AddParameter(const AParameter: TXrtlDatabaseParameter);
begin
  SetLength(FParameters, Length(FParameters) + 1);
  FParameters[High(FParameters)] := AParameter;
end;

procedure TXrtlDatabaseSelectBuilder.Clear;
begin
  FTableName := '';
  SetLength(FColumns, 0);
  SetLength(FWhereClauses, 0);
  SetLength(FOrderByClauses, 0);
  SetLength(FParameters, 0);
  FHasLimit := False;
  FLimit := 0;
end;

function TXrtlDatabaseSelectBuilder.FromTable(const ATableName: string): TXrtlResult;
begin
  if not XrtlDatabaseIsValidIdentifierPath(ATableName) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_identifier',
      'Table identifier is invalid: ' + ATableName));

  FTableName := ATableName;
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseSelectBuilder.AddColumn(const AColumnName: string): TXrtlResult;
begin
  if not XrtlDatabaseIsValidIdentifierPath(AColumnName) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_identifier',
      'Column identifier is invalid: ' + AColumnName));

  SetLength(FColumns, Length(FColumns) + 1);
  FColumns[High(FColumns)] := AColumnName;
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseSelectBuilder.WhereTextEquals(const AColumnName, AParameterName, AValue: string): TXrtlResult;
begin
  if not XrtlDatabaseIsValidIdentifierPath(AColumnName) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_identifier',
      'Where column identifier is invalid: ' + AColumnName));
  if not XrtlDatabaseIsValidIdentifier(AParameterName) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_parameter',
      'Query parameter identifier is invalid: ' + AParameterName));
  if IndexOfParameter(AParameterName) >= 0 then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'duplicate_parameter',
      'Query parameter is duplicated: ' + AParameterName));

  SetLength(FWhereClauses, Length(FWhereClauses) + 1);
  FWhereClauses[High(FWhereClauses)] := AColumnName + ' = :' + AParameterName;
  AddParameter(TXrtlDatabaseParameter.Text(AParameterName, AValue));
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseSelectBuilder.WhereInt64Equals(const AColumnName, AParameterName: string; const AValue: Int64): TXrtlResult;
begin
  if not XrtlDatabaseIsValidIdentifierPath(AColumnName) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_identifier',
      'Where column identifier is invalid: ' + AColumnName));
  if not XrtlDatabaseIsValidIdentifier(AParameterName) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_parameter',
      'Query parameter identifier is invalid: ' + AParameterName));
  if IndexOfParameter(AParameterName) >= 0 then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'duplicate_parameter',
      'Query parameter is duplicated: ' + AParameterName));

  SetLength(FWhereClauses, Length(FWhereClauses) + 1);
  FWhereClauses[High(FWhereClauses)] := AColumnName + ' = :' + AParameterName;
  AddParameter(TXrtlDatabaseParameter.Int64Value(AParameterName, AValue));
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseSelectBuilder.AddOrderBy(const AColumnName: string; const ADirection: TXrtlDatabaseSortDirection): TXrtlResult;
var
  DirectionText: string;
begin
  if not XrtlDatabaseIsValidIdentifierPath(AColumnName) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_identifier',
      'Order column identifier is invalid: ' + AColumnName));

  case ADirection of
    xsdAscending:
      DirectionText := 'asc';
    xsdDescending:
      DirectionText := 'desc';
  else
    DirectionText := 'asc';
  end;

  SetLength(FOrderByClauses, Length(FOrderByClauses) + 1);
  FOrderByClauses[High(FOrderByClauses)] := AColumnName + ' ' + DirectionText;
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseSelectBuilder.SetLimit(const ARowLimit: Int64): TXrtlResult;
begin
  if ARowLimit < 0 then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_limit',
      'Query row limit must not be negative'));

  FHasLimit := True;
  FLimit := ARowLimit;
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseSelectBuilder.Build(out ASql: string; const AParams: TXrtlDatabaseParameters): TXrtlResult;
var
  I: Integer;
begin
  ASql := '';
  if not Assigned(AParams) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_parameters',
      'Query builder output parameters must not be nil'));
  if FTableName = '' then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_query',
      'Query builder table must be set before build'));

  AParams.Clear;
  if Length(FColumns) = 0 then
    ASql := 'select *'
  else
    ASql := 'select ' + XrtlDatabaseJoinStrings(FColumns, ', ');

  ASql := ASql + ' from ' + FTableName;
  if Length(FWhereClauses) > 0 then
    ASql := ASql + ' where ' + XrtlDatabaseJoinStrings(FWhereClauses, ' and ');
  if Length(FOrderByClauses) > 0 then
    ASql := ASql + ' order by ' + XrtlDatabaseJoinStrings(FOrderByClauses, ', ');
  if FHasLimit then
    ASql := ASql + ' limit ' + IntToStr(FLimit);

  for I := 0 to High(FParameters) do
    case FParameters[I].Kind of
      xspNull:
        AParams.AddNull(FParameters[I].Name);
      xspText:
        AParams.AddText(FParameters[I].Name, FParameters[I].TextValue);
      xspInt64:
        AParams.AddInt64(FParameters[I].Name, FParameters[I].Int64ValueData);
    end;

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
  OldFpuMask: TFPUExceptionMask;
begin
  Result := EnsureOpen;
  if Result.Failed then
    Exit;
  if Trim(ASql) = '' then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'empty_sql',
      'SQL text must not be empty'));

  if (not Assigned(AParams)) or (AParams.Count = 0) then
  begin
    EnsureTransactionStarted;
    try
      OldFpuMask := GetExceptionMask;
      SetExceptionMask(XrtlSqliteCallMask(OldFpuMask));
      try
        TSQLite3Connection(FConnection).ExecuteDirect(ASql);
        if not FExplicitTransaction then
          TSQLTransaction(FTransaction).Commit;
      finally
        SetExceptionMask(OldFpuMask);
      end;
      Result := TXrtlResult.Ok;
    except
      on E: Exception do
      begin
        if (not FExplicitTransaction) and TSQLTransaction(FTransaction).Active then
          TSQLTransaction(FTransaction).Rollback;
        Result := FailFromException('execute_failed', E.Message);
      end;
    end;
    Exit;
  end;

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
      OldFpuMask := GetExceptionMask;
      SetExceptionMask(XrtlSqliteCallMask(OldFpuMask));
      try
        Query.ExecSQL;
        if not FExplicitTransaction then
          TSQLTransaction(FTransaction).Commit;
      finally
        SetExceptionMask(OldFpuMask);
      end;
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
  OldFpuMask: TFPUExceptionMask;
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
      OldFpuMask := GetExceptionMask;
      SetExceptionMask(XrtlSqliteCallMask(OldFpuMask));
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
      finally
        SetExceptionMask(OldFpuMask);
      end;
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
  OldFpuMask: TFPUExceptionMask;
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
      OldFpuMask := GetExceptionMask;
      SetExceptionMask(XrtlSqliteCallMask(OldFpuMask));
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
      finally
        SetExceptionMask(OldFpuMask);
      end;
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

function TXrtlSqliteDatabase.QueryDataSet(const ASql: string; ADataSet: TXrtlSqliteDataSet): TXrtlResult;
begin
  Result := QueryDataSet(ASql, nil, ADataSet);
end;

function TXrtlSqliteDatabase.QueryDataSet(const ASql: string; const AParams: TXrtlSqliteParameters; ADataSet: TXrtlSqliteDataSet): TXrtlResult;
var
  Rows: TXrtlSqliteResultSet;
begin
  if not Assigned(ADataSet) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_dataset',
      'SQLite dataset target must not be nil'));

  Rows := TXrtlSqliteResultSet.Create;
  try
    Result := QueryRows(ASql, AParams, Rows);
    if Result.Failed then
      Exit;

    Result := ADataSet.LoadFromResultSet(Rows);
  finally
    Rows.Free;
  end;
end;

end.
