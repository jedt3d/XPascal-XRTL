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

  TXrtlDatabaseOrmField = record
  private
    FName: string;
    FColumnName: string;
    FRequired: Boolean;
    FWritable: Boolean;
  public
    class function Create(
      const AName, AColumnName: string;
      const ARequired: Boolean = False;
      const AWritable: Boolean = True): TXrtlDatabaseOrmField; static;
    property Name: string read FName;
    property ColumnName: string read FColumnName;
    property Required: Boolean read FRequired;
    property Writable: Boolean read FWritable;
  end;

  TXrtlDatabaseOrmSchema = class
  private
    FTableName: string;
    FIdColumnName: string;
    FFields: array of TXrtlDatabaseOrmField;
    function GetFieldCount: Integer;
    function GetField(const AIndex: Integer): TXrtlDatabaseOrmField;
  public
    procedure Clear;
    function Configure(const ATableName, AIdColumnName: string): TXrtlResult;
    function AddField(
      const AName, AColumnName: string;
      const ARequired: Boolean = False;
      const AWritable: Boolean = True): TXrtlResult;
    function IndexOfField(const AName: string): Integer;
    function IndexOfColumn(const AColumnName: string): Integer;
    function Validate: TXrtlResult;
    property TableName: string read FTableName;
    property IdColumnName: string read FIdColumnName;
    property FieldCount: Integer read GetFieldCount;
    property Fields[const AIndex: Integer]: TXrtlDatabaseOrmField read GetField; default;
  end;

  TXrtlDatabaseOrmRecordValue = record
  private
    FName: string;
    FValue: TXrtlDatabaseValue;
  public
    class function Create(const AName: string; const AValue: TXrtlDatabaseValue): TXrtlDatabaseOrmRecordValue; static;
    property Name: string read FName;
    property Value: TXrtlDatabaseValue read FValue;
  end;

  TXrtlDatabaseOrmRecord = class
  private
    FValues: array of TXrtlDatabaseOrmRecordValue;
    function GetValueCount: Integer;
    function GetValue(const AIndex: Integer): TXrtlDatabaseOrmRecordValue;
  public
    procedure Clear;
    procedure SetValue(const AName: string; const AValue: TXrtlDatabaseValue);
    procedure SetNull(const AName: string);
    procedure SetText(const AName, AValue: string);
    procedure SetInt64(const AName: string; const AValue: Int64);
    procedure CopyFrom(const ASource: TXrtlDatabaseOrmRecord);
    function IndexOfValue(const AName: string): Integer;
    function ValueByName(const AName: string; out AValue: TXrtlDatabaseValue): TXrtlResult;
    property ValueCount: Integer read GetValueCount;
    property Values[const AIndex: Integer]: TXrtlDatabaseOrmRecordValue read GetValue; default;
  end;

  TXrtlDatabaseOrmSqlCache = class
  private
    FSelectByIdKey: string;
    FSelectByIdSql: string;
    FInsertKey: string;
    FInsertSql: string;
    FUpdateKey: string;
    FUpdateSql: string;
    FDeleteByIdKey: string;
    FDeleteByIdSql: string;
    FHitCount: Integer;
    FMissCount: Integer;
  public
    procedure Clear;
    function SelectByIdSql(const ASchema: TXrtlDatabaseOrmSchema; out ASql: string): TXrtlResult;
    function InsertSql(const ASchema: TXrtlDatabaseOrmSchema; out ASql: string): TXrtlResult;
    function UpdateSql(const ASchema: TXrtlDatabaseOrmSchema; out ASql: string): TXrtlResult;
    function DeleteByIdSql(const ASchema: TXrtlDatabaseOrmSchema; out ASql: string): TXrtlResult;
    property HitCount: Integer read FHitCount;
    property MissCount: Integer read FMissCount;
  end;

  TXrtlDatabaseOrmSchemaCache = class
  private
    FKeys: array of string;
    FHitCount: Integer;
    FMissCount: Integer;
    function GetCount: Integer;
  public
    procedure Clear;
    function IndexOfSchema(const ASchema: TXrtlDatabaseOrmSchema): Integer;
    function RegisterSchema(const ASchema: TXrtlDatabaseOrmSchema; out AIndex: Integer): TXrtlResult;
    property Count: Integer read GetCount;
    property HitCount: Integer read FHitCount;
    property MissCount: Integer read FMissCount;
  end;

  TXrtlDatabaseOrmMapper = class
  private
    FSqlCache: TXrtlDatabaseOrmSqlCache;
    function MapRow(const ASchema: TXrtlDatabaseOrmSchema; const ARow: TXrtlDatabaseRow; const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
    function ValidateWriteRecord(const ASchema: TXrtlDatabaseOrmSchema; const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
    function BindWriteParameters(const ASchema: TXrtlDatabaseOrmSchema; const ARecord: TXrtlDatabaseOrmRecord; const AParams: TXrtlDatabaseParameters): TXrtlResult;
    function BindIdParameter(const AParams: TXrtlDatabaseParameters; const AId: Int64): TXrtlResult;
    function EnsureRecordExists(const AConnection: TXrtlDatabaseConnection; const ASchema: TXrtlDatabaseOrmSchema; const AId: Int64): TXrtlResult;
  public
    constructor Create;
    destructor Destroy; override;
    function FindByInt64Id(
      const AConnection: TXrtlDatabaseConnection;
      const ASchema: TXrtlDatabaseOrmSchema;
      const AId: Int64;
      const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
    function Insert(
      const AConnection: TXrtlDatabaseConnection;
      const ASchema: TXrtlDatabaseOrmSchema;
      const ARecord: TXrtlDatabaseOrmRecord;
      out AId: Int64): TXrtlResult;
    function Update(
      const AConnection: TXrtlDatabaseConnection;
      const ASchema: TXrtlDatabaseOrmSchema;
      const AId: Int64;
      const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
    function DeleteByInt64Id(
      const AConnection: TXrtlDatabaseConnection;
      const ASchema: TXrtlDatabaseOrmSchema;
      const AId: Int64): TXrtlResult;
    property SqlCache: TXrtlDatabaseOrmSqlCache read FSqlCache;
  end;

  TXrtlDatabaseOrmIdentityMapEntry = record
  private
    FSchemaKey: string;
    FId: Int64;
    FRecord: TXrtlDatabaseOrmRecord;
  public
    property SchemaKey: string read FSchemaKey;
    property Id: Int64 read FId;
    property RecordData: TXrtlDatabaseOrmRecord read FRecord;
  end;

  TXrtlDatabaseOrmSession = class
  private
    FConnection: TXrtlDatabaseConnection;
    FMapper: TXrtlDatabaseOrmMapper;
    FSchemaCache: TXrtlDatabaseOrmSchemaCache;
    FIdentityMap: array of TXrtlDatabaseOrmIdentityMapEntry;
    FIdentityMapHitCount: Integer;
    function GetIdentityMapCount: Integer;
    function RequireConnection: TXrtlResult;
    function IndexOfIdentity(const ASchema: TXrtlDatabaseOrmSchema; const AId: Int64): Integer;
    procedure PutIdentity(const ASchema: TXrtlDatabaseOrmSchema; const AId: Int64; const ARecord: TXrtlDatabaseOrmRecord);
    procedure RemoveIdentity(const ASchema: TXrtlDatabaseOrmSchema; const AId: Int64);
  public
    constructor Create(const AConnection: TXrtlDatabaseConnection);
    destructor Destroy; override;
    procedure Clear;
    function BeginWork: TXrtlResult;
    function Commit: TXrtlResult;
    function Rollback: TXrtlResult;
    function FindByInt64Id(const ASchema: TXrtlDatabaseOrmSchema; const AId: Int64; const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
    function Insert(const ASchema: TXrtlDatabaseOrmSchema; const ARecord: TXrtlDatabaseOrmRecord; out AId: Int64): TXrtlResult;
    function Update(const ASchema: TXrtlDatabaseOrmSchema; const AId: Int64; const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
    function DeleteByInt64Id(const ASchema: TXrtlDatabaseOrmSchema; const AId: Int64): TXrtlResult;
    property Connection: TXrtlDatabaseConnection read FConnection;
    property Mapper: TXrtlDatabaseOrmMapper read FMapper;
    property SchemaCache: TXrtlDatabaseOrmSchemaCache read FSchemaCache;
    property IdentityMapCount: Integer read GetIdentityMapCount;
    property IdentityMapHitCount: Integer read FIdentityMapHitCount;
  end;

  TXrtlDatabaseOrmRepository = class
  private
    FSession: TXrtlDatabaseOrmSession;
    FSchema: TXrtlDatabaseOrmSchema;
  public
    constructor Create(const ASession: TXrtlDatabaseOrmSession; const ASchema: TXrtlDatabaseOrmSchema);
    function FindByInt64Id(const AId: Int64; const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
    function Insert(const ARecord: TXrtlDatabaseOrmRecord; out AId: Int64): TXrtlResult;
    function Update(const AId: Int64; const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
    function DeleteByInt64Id(const AId: Int64): TXrtlResult;
    property Session: TXrtlDatabaseOrmSession read FSession;
    property Schema: TXrtlDatabaseOrmSchema read FSchema;
  end;

  TXrtlDatabaseAttachmentMetadata = record
  private
    FId: Int64;
    FOwnerType: string;
    FOwnerId: Int64;
    FFileName: string;
    FMediaType: string;
    FSizeBytes: Int64;
    FSha256: string;
    FStorageUri: string;
    FState: string;
    FCreatedAtUtc: string;
  public
    class function Create(
      const AOwnerType: string;
      const AOwnerId: Int64;
      const AFileName, AMediaType: string;
      const ASizeBytes: Int64;
      const ASha256, AStorageUri, AState, ACreatedAtUtc: string): TXrtlDatabaseAttachmentMetadata; static;
    procedure Clear;
    property Id: Int64 read FId write FId;
    property OwnerType: string read FOwnerType write FOwnerType;
    property OwnerId: Int64 read FOwnerId write FOwnerId;
    property FileName: string read FFileName write FFileName;
    property MediaType: string read FMediaType write FMediaType;
    property SizeBytes: Int64 read FSizeBytes write FSizeBytes;
    property Sha256: string read FSha256 write FSha256;
    property StorageUri: string read FStorageUri write FStorageUri;
    property State: string read FState write FState;
    property CreatedAtUtc: string read FCreatedAtUtc write FCreatedAtUtc;
  end;

  TXrtlDatabaseAttachmentMetadataStore = class
  private
    FConnection: TXrtlDatabaseConnection;
    function RequireConnection: TXrtlResult;
    function ValidateMetadata(const AMetadata: TXrtlDatabaseAttachmentMetadata): TXrtlResult;
  public
    constructor Create(const AConnection: TXrtlDatabaseConnection);
    function EnsureSchema: TXrtlResult;
    function Insert(const AMetadata: TXrtlDatabaseAttachmentMetadata; out AId: Int64): TXrtlResult;
    function FindByInt64Id(const AId: Int64; out AMetadata: TXrtlDatabaseAttachmentMetadata): TXrtlResult;
    property Connection: TXrtlDatabaseConnection read FConnection;
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

function XrtlDatabaseOrmSchemaKey(const ASchema: TXrtlDatabaseOrmSchema): string;
var
  I: Integer;
  FieldFlags: string;
begin
  Result := '';
  if not Assigned(ASchema) then
    Exit;

  Result := LowerCase(ASchema.TableName) + '|' + LowerCase(ASchema.IdColumnName);
  for I := 0 to ASchema.FieldCount - 1 do
  begin
    FieldFlags := '';
    if ASchema[I].Required then
      FieldFlags := FieldFlags + 'r'
    else
      FieldFlags := FieldFlags + '-';
    if ASchema[I].Writable then
      FieldFlags := FieldFlags + 'w'
    else
      FieldFlags := FieldFlags + '-';
    Result := Result + '|' + LowerCase(ASchema[I].Name) + ':' +
      LowerCase(ASchema[I].ColumnName) + ':' + FieldFlags;
  end;
end;

function XrtlDatabaseOrmIsIdField(
  const ASchema: TXrtlDatabaseOrmSchema;
  const AField: TXrtlDatabaseOrmField): Boolean;
begin
  Result := Assigned(ASchema) and SameText(AField.ColumnName, ASchema.IdColumnName);
end;

function XrtlDatabaseOrmParameterName(const AFieldName: string): string;
begin
  Result := 'xrtl_orm_' + AFieldName;
end;

function XrtlDatabaseAddValueParameter(
  const AParams: TXrtlDatabaseParameters;
  const AName: string;
  const AValue: TXrtlDatabaseValue): TXrtlResult;
begin
  if not Assigned(AParams) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_parameters',
      'Database parameters must not be nil'));
  if not XrtlDatabaseIsValidIdentifier(AName) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_parameter',
      'Database parameter identifier is invalid: ' + AName));

  case AValue.Kind of
    xsvNull:
      AParams.AddNull(AName);
    xsvText:
      AParams.AddText(AName, AValue.TextValue);
    xsvInt64:
      AParams.AddInt64(AName, AValue.Int64ValueData);
  end;
  Result := TXrtlResult.Ok;
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

class function TXrtlDatabaseOrmField.Create(
  const AName, AColumnName: string;
  const ARequired: Boolean;
  const AWritable: Boolean): TXrtlDatabaseOrmField;
begin
  Result.FName := AName;
  Result.FColumnName := AColumnName;
  Result.FRequired := ARequired;
  Result.FWritable := AWritable;
end;

procedure TXrtlDatabaseOrmSchema.Clear;
begin
  FTableName := '';
  FIdColumnName := '';
  SetLength(FFields, 0);
end;

function TXrtlDatabaseOrmSchema.GetFieldCount: Integer;
begin
  Result := Length(FFields);
end;

function TXrtlDatabaseOrmSchema.GetField(const AIndex: Integer): TXrtlDatabaseOrmField;
begin
  if (AIndex < 0) or (AIndex >= Length(FFields)) then
    raise ERangeError.Create('Database ORM schema field index out of range');
  Result := FFields[AIndex];
end;

function TXrtlDatabaseOrmSchema.Configure(const ATableName, AIdColumnName: string): TXrtlResult;
begin
  if not XrtlDatabaseIsValidIdentifierPath(ATableName) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_schema',
      'ORM table identifier is invalid: ' + ATableName));
  if not XrtlDatabaseIsValidIdentifier(AIdColumnName) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_schema',
      'ORM id column identifier is invalid: ' + AIdColumnName));

  FTableName := ATableName;
  FIdColumnName := AIdColumnName;
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseOrmSchema.IndexOfField(const AName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FFields) do
    if SameText(FFields[I].Name, AName) then
      Exit(I);
end;

function TXrtlDatabaseOrmSchema.IndexOfColumn(const AColumnName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FFields) do
    if SameText(FFields[I].ColumnName, AColumnName) then
      Exit(I);
end;

function TXrtlDatabaseOrmSchema.AddField(
  const AName, AColumnName: string;
  const ARequired: Boolean;
  const AWritable: Boolean): TXrtlResult;
begin
  if not XrtlDatabaseIsValidIdentifier(AName) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_schema',
      'ORM field name is invalid: ' + AName));
  if not XrtlDatabaseIsValidIdentifier(AColumnName) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_schema',
      'ORM column identifier is invalid: ' + AColumnName));
  if IndexOfField(AName) >= 0 then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'duplicate_orm_field',
      'ORM field name is duplicated: ' + AName));
  if IndexOfColumn(AColumnName) >= 0 then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'duplicate_orm_column',
      'ORM column name is duplicated: ' + AColumnName));

  SetLength(FFields, Length(FFields) + 1);
  FFields[High(FFields)] := TXrtlDatabaseOrmField.Create(AName, AColumnName, ARequired, AWritable);
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseOrmSchema.Validate: TXrtlResult;
begin
  if FTableName = '' then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_schema',
      'ORM schema table must be configured'));
  if FIdColumnName = '' then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_schema',
      'ORM schema id column must be configured'));
  if Length(FFields) = 0 then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_schema',
      'ORM schema must include at least one mapped field'));

  Result := TXrtlResult.Ok;
end;

class function TXrtlDatabaseOrmRecordValue.Create(const AName: string; const AValue: TXrtlDatabaseValue): TXrtlDatabaseOrmRecordValue;
begin
  Result.FName := AName;
  Result.FValue := AValue;
end;

function TXrtlDatabaseOrmRecord.GetValueCount: Integer;
begin
  Result := Length(FValues);
end;

function TXrtlDatabaseOrmRecord.GetValue(const AIndex: Integer): TXrtlDatabaseOrmRecordValue;
begin
  if (AIndex < 0) or (AIndex >= Length(FValues)) then
    raise ERangeError.Create('Database ORM record value index out of range');
  Result := FValues[AIndex];
end;

procedure TXrtlDatabaseOrmRecord.Clear;
begin
  SetLength(FValues, 0);
end;

function TXrtlDatabaseOrmRecord.IndexOfValue(const AName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FValues) do
    if SameText(FValues[I].Name, AName) then
      Exit(I);
end;

procedure TXrtlDatabaseOrmRecord.SetValue(const AName: string; const AValue: TXrtlDatabaseValue);
var
  Index: Integer;
begin
  Index := IndexOfValue(AName);
  if Index >= 0 then
    FValues[Index] := TXrtlDatabaseOrmRecordValue.Create(AName, AValue)
  else
  begin
    SetLength(FValues, Length(FValues) + 1);
    FValues[High(FValues)] := TXrtlDatabaseOrmRecordValue.Create(AName, AValue);
  end;
end;

procedure TXrtlDatabaseOrmRecord.SetNull(const AName: string);
begin
  SetValue(AName, TXrtlDatabaseValue.Null);
end;

procedure TXrtlDatabaseOrmRecord.SetText(const AName, AValue: string);
begin
  SetValue(AName, TXrtlDatabaseValue.Text(AValue));
end;

procedure TXrtlDatabaseOrmRecord.SetInt64(const AName: string; const AValue: Int64);
begin
  SetValue(AName, TXrtlDatabaseValue.Int64Value(AValue));
end;

procedure TXrtlDatabaseOrmRecord.CopyFrom(const ASource: TXrtlDatabaseOrmRecord);
var
  I: Integer;
begin
  Clear;
  if not Assigned(ASource) then
    Exit;
  for I := 0 to ASource.ValueCount - 1 do
    SetValue(ASource[I].Name, ASource[I].Value);
end;

function TXrtlDatabaseOrmRecord.ValueByName(const AName: string; out AValue: TXrtlDatabaseValue): TXrtlResult;
var
  Index: Integer;
begin
  Index := IndexOfValue(AName);
  if Index < 0 then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'orm_field_not_found',
      'ORM record field was not found: ' + AName));

  AValue := FValues[Index].Value;
  Result := TXrtlResult.Ok;
end;

procedure TXrtlDatabaseOrmSqlCache.Clear;
begin
  FSelectByIdKey := '';
  FSelectByIdSql := '';
  FInsertKey := '';
  FInsertSql := '';
  FUpdateKey := '';
  FUpdateSql := '';
  FDeleteByIdKey := '';
  FDeleteByIdSql := '';
  FHitCount := 0;
  FMissCount := 0;
end;

function TXrtlDatabaseOrmSqlCache.SelectByIdSql(const ASchema: TXrtlDatabaseOrmSchema; out ASql: string): TXrtlResult;
var
  I: Integer;
  Key: string;
  Columns: array of string;
begin
  ASql := '';
  Result := ASchema.Validate;
  if Result.Failed then
    Exit;

  Key := XrtlDatabaseOrmSchemaKey(ASchema) + '|select_by_id';
  if (Key = FSelectByIdKey) and (FSelectByIdSql <> '') then
  begin
    Inc(FHitCount);
    ASql := FSelectByIdSql;
    Exit(TXrtlResult.Ok);
  end;

  SetLength(Columns, ASchema.FieldCount);
  for I := 0 to ASchema.FieldCount - 1 do
    Columns[I] := ASchema[I].ColumnName;

  FSelectByIdKey := Key;
  FSelectByIdSql := 'select ' + XrtlDatabaseJoinStrings(Columns, ', ') +
    ' from ' + ASchema.TableName +
    ' where ' + ASchema.IdColumnName + ' = :xrtl_orm_id limit 1';
  Inc(FMissCount);
  ASql := FSelectByIdSql;
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseOrmSqlCache.InsertSql(const ASchema: TXrtlDatabaseOrmSchema; out ASql: string): TXrtlResult;
var
  I: Integer;
  Key: string;
  Columns: array of string;
  Parameters: array of string;
begin
  ASql := '';
  Result := ASchema.Validate;
  if Result.Failed then
    Exit;

  Key := XrtlDatabaseOrmSchemaKey(ASchema) + '|insert';
  if (Key = FInsertKey) and (FInsertSql <> '') then
  begin
    Inc(FHitCount);
    ASql := FInsertSql;
    Exit(TXrtlResult.Ok);
  end;

  for I := 0 to ASchema.FieldCount - 1 do
  begin
    if XrtlDatabaseOrmIsIdField(ASchema, ASchema[I]) or (not ASchema[I].Writable) then
      Continue;
    SetLength(Columns, Length(Columns) + 1);
    SetLength(Parameters, Length(Parameters) + 1);
    Columns[High(Columns)] := ASchema[I].ColumnName;
    Parameters[High(Parameters)] := ':' + XrtlDatabaseOrmParameterName(ASchema[I].Name);
  end;

  if Length(Columns) = 0 then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_schema',
      'ORM schema must include at least one writable non-id field'));

  FInsertKey := Key;
  FInsertSql := 'insert into ' + ASchema.TableName + '(' +
    XrtlDatabaseJoinStrings(Columns, ', ') + ') values (' +
    XrtlDatabaseJoinStrings(Parameters, ', ') + ')';
  Inc(FMissCount);
  ASql := FInsertSql;
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseOrmSqlCache.UpdateSql(const ASchema: TXrtlDatabaseOrmSchema; out ASql: string): TXrtlResult;
var
  I: Integer;
  Key: string;
  Assignments: array of string;
begin
  ASql := '';
  Result := ASchema.Validate;
  if Result.Failed then
    Exit;

  Key := XrtlDatabaseOrmSchemaKey(ASchema) + '|update';
  if (Key = FUpdateKey) and (FUpdateSql <> '') then
  begin
    Inc(FHitCount);
    ASql := FUpdateSql;
    Exit(TXrtlResult.Ok);
  end;

  for I := 0 to ASchema.FieldCount - 1 do
  begin
    if XrtlDatabaseOrmIsIdField(ASchema, ASchema[I]) or (not ASchema[I].Writable) then
      Continue;
    SetLength(Assignments, Length(Assignments) + 1);
    Assignments[High(Assignments)] := ASchema[I].ColumnName + ' = :' +
      XrtlDatabaseOrmParameterName(ASchema[I].Name);
  end;

  if Length(Assignments) = 0 then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_schema',
      'ORM schema must include at least one writable non-id field'));

  FUpdateKey := Key;
  FUpdateSql := 'update ' + ASchema.TableName + ' set ' +
    XrtlDatabaseJoinStrings(Assignments, ', ') +
    ' where ' + ASchema.IdColumnName + ' = :xrtl_orm_id';
  Inc(FMissCount);
  ASql := FUpdateSql;
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseOrmSqlCache.DeleteByIdSql(const ASchema: TXrtlDatabaseOrmSchema; out ASql: string): TXrtlResult;
var
  Key: string;
begin
  ASql := '';
  Result := ASchema.Validate;
  if Result.Failed then
    Exit;

  Key := XrtlDatabaseOrmSchemaKey(ASchema) + '|delete_by_id';
  if (Key = FDeleteByIdKey) and (FDeleteByIdSql <> '') then
  begin
    Inc(FHitCount);
    ASql := FDeleteByIdSql;
    Exit(TXrtlResult.Ok);
  end;

  FDeleteByIdKey := Key;
  FDeleteByIdSql := 'delete from ' + ASchema.TableName +
    ' where ' + ASchema.IdColumnName + ' = :xrtl_orm_id';
  Inc(FMissCount);
  ASql := FDeleteByIdSql;
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseOrmSchemaCache.GetCount: Integer;
begin
  Result := Length(FKeys);
end;

procedure TXrtlDatabaseOrmSchemaCache.Clear;
begin
  SetLength(FKeys, 0);
  FHitCount := 0;
  FMissCount := 0;
end;

function TXrtlDatabaseOrmSchemaCache.IndexOfSchema(const ASchema: TXrtlDatabaseOrmSchema): Integer;
var
  I: Integer;
  Key: string;
begin
  Result := -1;
  Key := XrtlDatabaseOrmSchemaKey(ASchema);
  if Key = '' then
    Exit;
  for I := 0 to High(FKeys) do
    if FKeys[I] = Key then
      Exit(I);
end;

function TXrtlDatabaseOrmSchemaCache.RegisterSchema(const ASchema: TXrtlDatabaseOrmSchema; out AIndex: Integer): TXrtlResult;
var
  Key: string;
begin
  AIndex := -1;
  if not Assigned(ASchema) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_schema',
      'ORM schema cache requires a schema'));

  Result := ASchema.Validate;
  if Result.Failed then
    Exit;

  AIndex := IndexOfSchema(ASchema);
  if AIndex >= 0 then
  begin
    Inc(FHitCount);
    Exit(TXrtlResult.Ok);
  end;

  Key := XrtlDatabaseOrmSchemaKey(ASchema);
  SetLength(FKeys, Length(FKeys) + 1);
  FKeys[High(FKeys)] := Key;
  AIndex := High(FKeys);
  Inc(FMissCount);
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseOrmMapper.MapRow(const ASchema: TXrtlDatabaseOrmSchema; const ARow: TXrtlDatabaseRow; const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
var
  I: Integer;
  Value: TXrtlDatabaseValue;
begin
  ARecord.Clear;
  for I := 0 to ASchema.FieldCount - 1 do
  begin
    Result := ARow.ValueByName(ASchema[I].ColumnName, Value);
    if Result.Failed then
    begin
      ARecord.Clear;
      Exit(TXrtlResult.Fail(
        XRTL_DATABASE_ERROR_DOMAIN,
        'orm_map_failed',
        'Failed to map ORM column ' + ASchema[I].ColumnName + ': ' + Result.Error.Code + ': ' + Result.Error.Message));
    end;

    ARecord.SetValue(ASchema[I].Name, Value);
  end;

  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseOrmMapper.ValidateWriteRecord(const ASchema: TXrtlDatabaseOrmSchema; const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
var
  I: Integer;
  WritableCount: Integer;
  Value: TXrtlDatabaseValue;
begin
  if not Assigned(ASchema) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_schema',
      'ORM mapper requires a schema'));
  if not Assigned(ARecord) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_record',
      'ORM mapper requires a record'));

  Result := ASchema.Validate;
  if Result.Failed then
    Exit;

  WritableCount := 0;
  for I := 0 to ASchema.FieldCount - 1 do
  begin
    if XrtlDatabaseOrmIsIdField(ASchema, ASchema[I]) or (not ASchema[I].Writable) then
      Continue;
    Inc(WritableCount);
    Result := ARecord.ValueByName(ASchema[I].Name, Value);
    if Result.Failed then
    begin
      if ASchema[I].Required then
        Exit(TXrtlResult.Fail(
          XRTL_DATABASE_ERROR_DOMAIN,
          'orm_required_field_missing',
          'Required ORM field is missing: ' + ASchema[I].Name));
      Continue;
    end;
    if ASchema[I].Required and Value.IsNull then
      Exit(TXrtlResult.Fail(
        XRTL_DATABASE_ERROR_DOMAIN,
        'orm_required_field_missing',
        'Required ORM field is null: ' + ASchema[I].Name));
  end;

  if WritableCount = 0 then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_schema',
      'ORM schema must include at least one writable non-id field'));

  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseOrmMapper.BindWriteParameters(
  const ASchema: TXrtlDatabaseOrmSchema;
  const ARecord: TXrtlDatabaseOrmRecord;
  const AParams: TXrtlDatabaseParameters): TXrtlResult;
var
  I: Integer;
  Value: TXrtlDatabaseValue;
  ParameterName: string;
begin
  if not Assigned(AParams) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_parameters',
      'ORM mapper requires parameters'));

  AParams.Clear;
  for I := 0 to ASchema.FieldCount - 1 do
  begin
    if XrtlDatabaseOrmIsIdField(ASchema, ASchema[I]) or (not ASchema[I].Writable) then
      Continue;
    Result := ARecord.ValueByName(ASchema[I].Name, Value);
    if Result.Failed then
      Value := TXrtlDatabaseValue.Null;
    ParameterName := XrtlDatabaseOrmParameterName(ASchema[I].Name);
    Result := XrtlDatabaseAddValueParameter(AParams, ParameterName, Value);
    if Result.Failed then
      Exit;
  end;

  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseOrmMapper.BindIdParameter(const AParams: TXrtlDatabaseParameters; const AId: Int64): TXrtlResult;
begin
  if not Assigned(AParams) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_parameters',
      'ORM mapper requires parameters'));
  AParams.AddInt64('xrtl_orm_id', AId);
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseOrmMapper.EnsureRecordExists(
  const AConnection: TXrtlDatabaseConnection;
  const ASchema: TXrtlDatabaseOrmSchema;
  const AId: Int64): TXrtlResult;
var
  Params: TXrtlDatabaseParameters;
  Count: Int64;
begin
  Params := TXrtlDatabaseParameters.Create;
  try
    Params.AddInt64('xrtl_orm_id', AId);
    Result := AConnection.QueryInt64(
      'select count(*) from ' + ASchema.TableName +
      ' where ' + ASchema.IdColumnName + ' = :xrtl_orm_id',
      Params,
      Count);
    if Result.Failed then
      Exit;
    if Count = 0 then
      Exit(TXrtlResult.Fail(
        XRTL_DATABASE_ERROR_DOMAIN,
        'orm_record_not_found',
        'ORM record was not found'));
    Result := TXrtlResult.Ok;
  finally
    Params.Free;
  end;
end;

constructor TXrtlDatabaseOrmMapper.Create;
begin
  inherited Create;
  FSqlCache := TXrtlDatabaseOrmSqlCache.Create;
end;

destructor TXrtlDatabaseOrmMapper.Destroy;
begin
  FSqlCache.Free;
  inherited Destroy;
end;

function TXrtlDatabaseOrmMapper.FindByInt64Id(
  const AConnection: TXrtlDatabaseConnection;
  const ASchema: TXrtlDatabaseOrmSchema;
  const AId: Int64;
  const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
var
  Params: TXrtlDatabaseParameters;
  Rows: TXrtlDatabaseResultSet;
  Row: TXrtlDatabaseRow;
  Sql: string;
begin
  if not Assigned(AConnection) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_connection',
      'ORM mapper requires a database connection'));
  if not Assigned(ASchema) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_schema',
      'ORM mapper requires a schema'));
  if not Assigned(ARecord) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_record',
      'ORM mapper requires an output record'));

  Result := ASchema.Validate;
  if Result.Failed then
    Exit;

  Params := TXrtlDatabaseParameters.Create;
  Rows := TXrtlDatabaseResultSet.Create;
  try
    Result := FSqlCache.SelectByIdSql(ASchema, Sql);
    if Result.Failed then
      Exit;
    Params.AddInt64('xrtl_orm_id', AId);

    Result := AConnection.QueryRows(Sql, Params, Rows);
    if Result.Failed then
      Exit;
    if Rows.RowCount = 0 then
      Exit(TXrtlResult.Fail(
        XRTL_DATABASE_ERROR_DOMAIN,
        'orm_record_not_found',
        'ORM record was not found'));

    Result := Rows.RowByIndex(0, Row);
    if Result.Failed then
      Exit;

    Result := MapRow(ASchema, Row, ARecord);
  finally
    Rows.Free;
    Params.Free;
  end;
end;

function TXrtlDatabaseOrmMapper.Insert(
  const AConnection: TXrtlDatabaseConnection;
  const ASchema: TXrtlDatabaseOrmSchema;
  const ARecord: TXrtlDatabaseOrmRecord;
  out AId: Int64): TXrtlResult;
var
  Params: TXrtlDatabaseParameters;
  Sql: string;
  IdFieldIndex: Integer;
begin
  AId := 0;
  if not Assigned(AConnection) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_connection',
      'ORM mapper requires a database connection'));

  Result := ValidateWriteRecord(ASchema, ARecord);
  if Result.Failed then
    Exit;

  Params := TXrtlDatabaseParameters.Create;
  try
    Result := FSqlCache.InsertSql(ASchema, Sql);
    if Result.Failed then
      Exit;
    Result := BindWriteParameters(ASchema, ARecord, Params);
    if Result.Failed then
      Exit;
    Result := AConnection.Execute(Sql, Params);
    if Result.Failed then
      Exit;
    Result := AConnection.QueryInt64('select last_insert_rowid()', AId);
    if Result.Failed then
      Exit;
    IdFieldIndex := ASchema.IndexOfColumn(ASchema.IdColumnName);
    if IdFieldIndex >= 0 then
      ARecord.SetInt64(ASchema[IdFieldIndex].Name, AId);
  finally
    Params.Free;
  end;
end;

function TXrtlDatabaseOrmMapper.Update(
  const AConnection: TXrtlDatabaseConnection;
  const ASchema: TXrtlDatabaseOrmSchema;
  const AId: Int64;
  const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
var
  Params: TXrtlDatabaseParameters;
  Sql: string;
begin
  if not Assigned(AConnection) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_connection',
      'ORM mapper requires a database connection'));

  Result := ValidateWriteRecord(ASchema, ARecord);
  if Result.Failed then
    Exit;

  Result := EnsureRecordExists(AConnection, ASchema, AId);
  if Result.Failed then
    Exit;

  Params := TXrtlDatabaseParameters.Create;
  try
    Result := FSqlCache.UpdateSql(ASchema, Sql);
    if Result.Failed then
      Exit;
    Result := BindWriteParameters(ASchema, ARecord, Params);
    if Result.Failed then
      Exit;
    Result := BindIdParameter(Params, AId);
    if Result.Failed then
      Exit;
    Result := AConnection.Execute(Sql, Params);
  finally
    Params.Free;
  end;
end;

function TXrtlDatabaseOrmMapper.DeleteByInt64Id(
  const AConnection: TXrtlDatabaseConnection;
  const ASchema: TXrtlDatabaseOrmSchema;
  const AId: Int64): TXrtlResult;
var
  Params: TXrtlDatabaseParameters;
  Sql: string;
begin
  if not Assigned(AConnection) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_connection',
      'ORM mapper requires a database connection'));
  if not Assigned(ASchema) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_schema',
      'ORM mapper requires a schema'));

  Result := ASchema.Validate;
  if Result.Failed then
    Exit;

  Result := EnsureRecordExists(AConnection, ASchema, AId);
  if Result.Failed then
    Exit;

  Params := TXrtlDatabaseParameters.Create;
  try
    Result := FSqlCache.DeleteByIdSql(ASchema, Sql);
    if Result.Failed then
      Exit;
    Result := BindIdParameter(Params, AId);
    if Result.Failed then
      Exit;
    Result := AConnection.Execute(Sql, Params);
  finally
    Params.Free;
  end;
end;

function TXrtlDatabaseOrmSession.GetIdentityMapCount: Integer;
begin
  Result := Length(FIdentityMap);
end;

function TXrtlDatabaseOrmSession.RequireConnection: TXrtlResult;
begin
  if not Assigned(FConnection) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_connection',
      'ORM session requires a database connection'));
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseOrmSession.IndexOfIdentity(const ASchema: TXrtlDatabaseOrmSchema; const AId: Int64): Integer;
var
  I: Integer;
  Key: string;
begin
  Result := -1;
  Key := XrtlDatabaseOrmSchemaKey(ASchema);
  if Key = '' then
    Exit;
  for I := 0 to High(FIdentityMap) do
    if (FIdentityMap[I].FSchemaKey = Key) and (FIdentityMap[I].FId = AId) then
      Exit(I);
end;

procedure TXrtlDatabaseOrmSession.PutIdentity(
  const ASchema: TXrtlDatabaseOrmSchema;
  const AId: Int64;
  const ARecord: TXrtlDatabaseOrmRecord);
var
  Index: Integer;
begin
  if not Assigned(ARecord) then
    Exit;

  Index := IndexOfIdentity(ASchema, AId);
  if Index < 0 then
  begin
    SetLength(FIdentityMap, Length(FIdentityMap) + 1);
    Index := High(FIdentityMap);
    FIdentityMap[Index].FSchemaKey := XrtlDatabaseOrmSchemaKey(ASchema);
    FIdentityMap[Index].FId := AId;
    FIdentityMap[Index].FRecord := TXrtlDatabaseOrmRecord.Create;
  end;
  FIdentityMap[Index].FRecord.CopyFrom(ARecord);
end;

procedure TXrtlDatabaseOrmSession.RemoveIdentity(const ASchema: TXrtlDatabaseOrmSchema; const AId: Int64);
var
  Index: Integer;
  I: Integer;
begin
  Index := IndexOfIdentity(ASchema, AId);
  if Index < 0 then
    Exit;

  FIdentityMap[Index].FRecord.Free;
  for I := Index to High(FIdentityMap) - 1 do
    FIdentityMap[I] := FIdentityMap[I + 1];
  SetLength(FIdentityMap, Length(FIdentityMap) - 1);
end;

constructor TXrtlDatabaseOrmSession.Create(const AConnection: TXrtlDatabaseConnection);
begin
  inherited Create;
  FConnection := AConnection;
  FMapper := TXrtlDatabaseOrmMapper.Create;
  FSchemaCache := TXrtlDatabaseOrmSchemaCache.Create;
end;

destructor TXrtlDatabaseOrmSession.Destroy;
begin
  Clear;
  FSchemaCache.Free;
  FMapper.Free;
  inherited Destroy;
end;

procedure TXrtlDatabaseOrmSession.Clear;
var
  I: Integer;
begin
  for I := 0 to High(FIdentityMap) do
    FIdentityMap[I].FRecord.Free;
  SetLength(FIdentityMap, 0);
  FIdentityMapHitCount := 0;
end;

function TXrtlDatabaseOrmSession.BeginWork: TXrtlResult;
begin
  Result := RequireConnection;
  if Result.Failed then
    Exit;
  Result := FConnection.BeginTransaction;
end;

function TXrtlDatabaseOrmSession.Commit: TXrtlResult;
begin
  Result := RequireConnection;
  if Result.Failed then
    Exit;
  Result := FConnection.Commit;
end;

function TXrtlDatabaseOrmSession.Rollback: TXrtlResult;
begin
  Result := RequireConnection;
  if Result.Failed then
    Exit;
  Result := FConnection.Rollback;
  if Result.Succeeded then
    Clear;
end;

function TXrtlDatabaseOrmSession.FindByInt64Id(
  const ASchema: TXrtlDatabaseOrmSchema;
  const AId: Int64;
  const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
var
  Index: Integer;
  SchemaIndex: Integer;
begin
  Result := RequireConnection;
  if Result.Failed then
    Exit;
  if not Assigned(ARecord) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_record',
      'ORM session requires an output record'));

  Result := FSchemaCache.RegisterSchema(ASchema, SchemaIndex);
  if Result.Failed then
    Exit;

  Index := IndexOfIdentity(ASchema, AId);
  if Index >= 0 then
  begin
    Inc(FIdentityMapHitCount);
    ARecord.CopyFrom(FIdentityMap[Index].FRecord);
    Exit(TXrtlResult.Ok);
  end;

  Result := FMapper.FindByInt64Id(FConnection, ASchema, AId, ARecord);
  if Result.Succeeded then
    PutIdentity(ASchema, AId, ARecord);
end;

function TXrtlDatabaseOrmSession.Insert(
  const ASchema: TXrtlDatabaseOrmSchema;
  const ARecord: TXrtlDatabaseOrmRecord;
  out AId: Int64): TXrtlResult;
var
  SchemaIndex: Integer;
begin
  AId := 0;
  Result := RequireConnection;
  if Result.Failed then
    Exit;
  Result := FSchemaCache.RegisterSchema(ASchema, SchemaIndex);
  if Result.Failed then
    Exit;
  Result := FMapper.Insert(FConnection, ASchema, ARecord, AId);
  if Result.Succeeded then
    PutIdentity(ASchema, AId, ARecord);
end;

function TXrtlDatabaseOrmSession.Update(
  const ASchema: TXrtlDatabaseOrmSchema;
  const AId: Int64;
  const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
var
  SchemaIndex: Integer;
  IdFieldIndex: Integer;
begin
  Result := RequireConnection;
  if Result.Failed then
    Exit;
  Result := FSchemaCache.RegisterSchema(ASchema, SchemaIndex);
  if Result.Failed then
    Exit;
  Result := FMapper.Update(FConnection, ASchema, AId, ARecord);
  if Result.Succeeded then
  begin
    IdFieldIndex := ASchema.IndexOfColumn(ASchema.IdColumnName);
    if IdFieldIndex >= 0 then
      ARecord.SetInt64(ASchema[IdFieldIndex].Name, AId);
    PutIdentity(ASchema, AId, ARecord);
  end;
end;

function TXrtlDatabaseOrmSession.DeleteByInt64Id(const ASchema: TXrtlDatabaseOrmSchema; const AId: Int64): TXrtlResult;
var
  SchemaIndex: Integer;
begin
  Result := RequireConnection;
  if Result.Failed then
    Exit;
  Result := FSchemaCache.RegisterSchema(ASchema, SchemaIndex);
  if Result.Failed then
    Exit;
  Result := FMapper.DeleteByInt64Id(FConnection, ASchema, AId);
  if Result.Succeeded then
    RemoveIdentity(ASchema, AId);
end;

constructor TXrtlDatabaseOrmRepository.Create(
  const ASession: TXrtlDatabaseOrmSession;
  const ASchema: TXrtlDatabaseOrmSchema);
begin
  inherited Create;
  FSession := ASession;
  FSchema := ASchema;
end;

function TXrtlDatabaseOrmRepository.FindByInt64Id(
  const AId: Int64;
  const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
begin
  if not Assigned(FSession) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_session',
      'ORM repository requires a session'));
  Result := FSession.FindByInt64Id(FSchema, AId, ARecord);
end;

function TXrtlDatabaseOrmRepository.Insert(const ARecord: TXrtlDatabaseOrmRecord; out AId: Int64): TXrtlResult;
begin
  AId := 0;
  if not Assigned(FSession) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_session',
      'ORM repository requires a session'));
  Result := FSession.Insert(FSchema, ARecord, AId);
end;

function TXrtlDatabaseOrmRepository.Update(const AId: Int64; const ARecord: TXrtlDatabaseOrmRecord): TXrtlResult;
begin
  if not Assigned(FSession) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_session',
      'ORM repository requires a session'));
  Result := FSession.Update(FSchema, AId, ARecord);
end;

function TXrtlDatabaseOrmRepository.DeleteByInt64Id(const AId: Int64): TXrtlResult;
begin
  if not Assigned(FSession) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_orm_session',
      'ORM repository requires a session'));
  Result := FSession.DeleteByInt64Id(FSchema, AId);
end;

class function TXrtlDatabaseAttachmentMetadata.Create(
  const AOwnerType: string;
  const AOwnerId: Int64;
  const AFileName, AMediaType: string;
  const ASizeBytes: Int64;
  const ASha256, AStorageUri, AState, ACreatedAtUtc: string): TXrtlDatabaseAttachmentMetadata;
begin
  Result.Clear;
  Result.FOwnerType := AOwnerType;
  Result.FOwnerId := AOwnerId;
  Result.FFileName := AFileName;
  Result.FMediaType := AMediaType;
  Result.FSizeBytes := ASizeBytes;
  Result.FSha256 := ASha256;
  Result.FStorageUri := AStorageUri;
  Result.FState := AState;
  Result.FCreatedAtUtc := ACreatedAtUtc;
end;

procedure TXrtlDatabaseAttachmentMetadata.Clear;
begin
  FId := 0;
  FOwnerType := '';
  FOwnerId := 0;
  FFileName := '';
  FMediaType := '';
  FSizeBytes := 0;
  FSha256 := '';
  FStorageUri := '';
  FState := '';
  FCreatedAtUtc := '';
end;

constructor TXrtlDatabaseAttachmentMetadataStore.Create(const AConnection: TXrtlDatabaseConnection);
begin
  inherited Create;
  FConnection := AConnection;
end;

function TXrtlDatabaseAttachmentMetadataStore.RequireConnection: TXrtlResult;
begin
  if not Assigned(FConnection) then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_connection',
      'Attachment metadata store requires a database connection'));
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseAttachmentMetadataStore.ValidateMetadata(
  const AMetadata: TXrtlDatabaseAttachmentMetadata): TXrtlResult;
begin
  if AMetadata.OwnerType = '' then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_attachment_metadata',
      'Attachment owner type is required'));
  if AMetadata.OwnerId <= 0 then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_attachment_metadata',
      'Attachment owner id must be positive'));
  if AMetadata.FileName = '' then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_attachment_metadata',
      'Attachment file name is required'));
  if AMetadata.MediaType = '' then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_attachment_metadata',
      'Attachment media type is required'));
  if AMetadata.SizeBytes < 0 then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_attachment_metadata',
      'Attachment size must not be negative'));
  if AMetadata.Sha256 = '' then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_attachment_metadata',
      'Attachment SHA256 is required'));
  if AMetadata.StorageUri = '' then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_attachment_metadata',
      'Attachment storage URI is required'));
  if AMetadata.State = '' then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_attachment_metadata',
      'Attachment state is required'));
  if AMetadata.CreatedAtUtc = '' then
    Exit(TXrtlResult.Fail(
      XRTL_DATABASE_ERROR_DOMAIN,
      'invalid_attachment_metadata',
      'Attachment created timestamp is required'));
  Result := TXrtlResult.Ok;
end;

function TXrtlDatabaseAttachmentMetadataStore.EnsureSchema: TXrtlResult;
begin
  Result := RequireConnection;
  if Result.Failed then
    Exit;

  Result := FConnection.Execute(
    'create table if not exists xrtl_attachments (' +
    'id integer primary key autoincrement, ' +
    'owner_type text not null, ' +
    'owner_id integer not null, ' +
    'file_name text not null, ' +
    'media_type text not null, ' +
    'size_bytes integer not null, ' +
    'sha256 text not null, ' +
    'storage_uri text not null, ' +
    'state text not null, ' +
    'created_at_utc text not null)');
end;

function TXrtlDatabaseAttachmentMetadataStore.Insert(
  const AMetadata: TXrtlDatabaseAttachmentMetadata;
  out AId: Int64): TXrtlResult;
var
  Params: TXrtlDatabaseParameters;
begin
  AId := 0;
  Result := RequireConnection;
  if Result.Failed then
    Exit;
  Result := ValidateMetadata(AMetadata);
  if Result.Failed then
    Exit;

  Params := TXrtlDatabaseParameters.Create;
  try
    Params.AddText('owner_type', AMetadata.OwnerType);
    Params.AddInt64('owner_id', AMetadata.OwnerId);
    Params.AddText('file_name', AMetadata.FileName);
    Params.AddText('media_type', AMetadata.MediaType);
    Params.AddInt64('size_bytes', AMetadata.SizeBytes);
    Params.AddText('sha256', AMetadata.Sha256);
    Params.AddText('storage_uri', AMetadata.StorageUri);
    Params.AddText('state', AMetadata.State);
    Params.AddText('created_at_utc', AMetadata.CreatedAtUtc);
    Result := FConnection.Execute(
      'insert into xrtl_attachments(' +
      'owner_type, owner_id, file_name, media_type, size_bytes, sha256, storage_uri, state, created_at_utc) ' +
      'values (:owner_type, :owner_id, :file_name, :media_type, :size_bytes, :sha256, :storage_uri, :state, :created_at_utc)',
      Params);
    if Result.Failed then
      Exit;
    Result := FConnection.QueryInt64('select last_insert_rowid()', AId);
  finally
    Params.Free;
  end;
end;

function TXrtlDatabaseAttachmentMetadataStore.FindByInt64Id(
  const AId: Int64;
  out AMetadata: TXrtlDatabaseAttachmentMetadata): TXrtlResult;
var
  Params: TXrtlDatabaseParameters;
  Rows: TXrtlDatabaseResultSet;
  Row: TXrtlDatabaseRow;
  Value: TXrtlDatabaseValue;
begin
  AMetadata.Clear;
  Result := RequireConnection;
  if Result.Failed then
    Exit;

  Params := TXrtlDatabaseParameters.Create;
  Rows := TXrtlDatabaseResultSet.Create;
  try
    Params.AddInt64('id', AId);
    Result := FConnection.QueryRows(
      'select id, owner_type, owner_id, file_name, media_type, size_bytes, sha256, storage_uri, state, created_at_utc ' +
      'from xrtl_attachments where id = :id limit 1',
      Params,
      Rows);
    if Result.Failed then
      Exit;
    if Rows.RowCount = 0 then
      Exit(TXrtlResult.Fail(
        XRTL_DATABASE_ERROR_DOMAIN,
        'attachment_not_found',
        'Attachment metadata was not found'));

    Result := Rows.RowByIndex(0, Row);
    if Result.Failed then
      Exit;

    Result := Row.ValueByName('id', Value);
    if Result.Failed then
      Exit;
    if Value.Kind <> xsvInt64 then
      Exit(TXrtlResult.Fail(XRTL_DATABASE_ERROR_DOMAIN, 'attachment_map_failed', 'Attachment id is not int64'));
    AMetadata.Id := Value.Int64ValueData;

    Result := Row.ValueByName('owner_type', Value);
    if Result.Failed then
      Exit;
    if Value.Kind <> xsvText then
      Exit(TXrtlResult.Fail(XRTL_DATABASE_ERROR_DOMAIN, 'attachment_map_failed', 'Attachment owner type is not text'));
    AMetadata.OwnerType := Value.TextValue;

    Result := Row.ValueByName('owner_id', Value);
    if Result.Failed then
      Exit;
    if Value.Kind <> xsvInt64 then
      Exit(TXrtlResult.Fail(XRTL_DATABASE_ERROR_DOMAIN, 'attachment_map_failed', 'Attachment owner id is not int64'));
    AMetadata.OwnerId := Value.Int64ValueData;

    Result := Row.ValueByName('file_name', Value);
    if Result.Failed then
      Exit;
    if Value.Kind <> xsvText then
      Exit(TXrtlResult.Fail(XRTL_DATABASE_ERROR_DOMAIN, 'attachment_map_failed', 'Attachment file name is not text'));
    AMetadata.FileName := Value.TextValue;

    Result := Row.ValueByName('media_type', Value);
    if Result.Failed then
      Exit;
    if Value.Kind <> xsvText then
      Exit(TXrtlResult.Fail(XRTL_DATABASE_ERROR_DOMAIN, 'attachment_map_failed', 'Attachment media type is not text'));
    AMetadata.MediaType := Value.TextValue;

    Result := Row.ValueByName('size_bytes', Value);
    if Result.Failed then
      Exit;
    if Value.Kind <> xsvInt64 then
      Exit(TXrtlResult.Fail(XRTL_DATABASE_ERROR_DOMAIN, 'attachment_map_failed', 'Attachment size is not int64'));
    AMetadata.SizeBytes := Value.Int64ValueData;

    Result := Row.ValueByName('sha256', Value);
    if Result.Failed then
      Exit;
    if Value.Kind <> xsvText then
      Exit(TXrtlResult.Fail(XRTL_DATABASE_ERROR_DOMAIN, 'attachment_map_failed', 'Attachment SHA256 is not text'));
    AMetadata.Sha256 := Value.TextValue;

    Result := Row.ValueByName('storage_uri', Value);
    if Result.Failed then
      Exit;
    if Value.Kind <> xsvText then
      Exit(TXrtlResult.Fail(XRTL_DATABASE_ERROR_DOMAIN, 'attachment_map_failed', 'Attachment storage URI is not text'));
    AMetadata.StorageUri := Value.TextValue;

    Result := Row.ValueByName('state', Value);
    if Result.Failed then
      Exit;
    if Value.Kind <> xsvText then
      Exit(TXrtlResult.Fail(XRTL_DATABASE_ERROR_DOMAIN, 'attachment_map_failed', 'Attachment state is not text'));
    AMetadata.State := Value.TextValue;

    Result := Row.ValueByName('created_at_utc', Value);
    if Result.Failed then
      Exit;
    if Value.Kind <> xsvText then
      Exit(TXrtlResult.Fail(XRTL_DATABASE_ERROR_DOMAIN, 'attachment_map_failed', 'Attachment timestamp is not text'));
    AMetadata.CreatedAtUtc := Value.TextValue;
  finally
    Rows.Free;
    Params.Free;
  end;
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
