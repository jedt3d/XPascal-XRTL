unit xrtl_core;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

const
  XRTL_CORE_LIBRARY_NAME = 'XRTL.Core';
  XRTL_CORE_CONTRACT_VERSION = 1;
  XRTL_CORE_ERROR_DOMAIN = 'xrtl.core';

type
  TXrtlStatus = (xsOk, xsError);
  TXrtlPresence = (xpMissing, xpPresent);

  TXrtlError = record
  private
    FDomain: string;
    FCode: string;
    FMessage: string;
  public
    class function Create(const ADomain, ACode, AMessage: string): TXrtlError; static;
    class function None: TXrtlError; static;
    function IsEmpty: Boolean;
    function SameIdentity(const AOther: TXrtlError): Boolean;
    property Domain: string read FDomain;
    property Code: string read FCode;
    property Message: string read FMessage;
  end;

  TXrtlResult = record
  private
    FStatus: TXrtlStatus;
    FError: TXrtlError;
  public
    class function Ok: TXrtlResult; static;
    class function Fail(const AError: TXrtlError): TXrtlResult; static; overload;
    class function Fail(const ADomain, ACode, AMessage: string): TXrtlResult; static; overload;
    function Succeeded: Boolean;
    function Failed: Boolean;
    property Status: TXrtlStatus read FStatus;
    property Error: TXrtlError read FError;
  end;

  generic TXrtlOption<T> = record
  private
    FPresence: TXrtlPresence;
    FValue: T;
  public
    class function Some(const AValue: T): TXrtlOption; static;
    class function None: TXrtlOption; static;
    function HasValue: Boolean;
    function IsMissing: Boolean;
    property Presence: TXrtlPresence read FPresence;
    property Value: T read FValue;
  end;

  generic TXrtlValueResult<T> = record
  private
    FResult: TXrtlResult;
    FValue: T;
  public
    class function Ok(const AValue: T): TXrtlValueResult; static;
    class function Fail(const AError: TXrtlError): TXrtlValueResult; static; overload;
    class function Fail(const ADomain, ACode, AMessage: string): TXrtlValueResult; static; overload;
    function Succeeded: Boolean;
    function Failed: Boolean;
    property ResultInfo: TXrtlResult read FResult;
    property Value: T read FValue;
  end;

  TXrtlCapability = record
  private
    FName: string;
    FSupported: Boolean;
    FDetailPresence: TXrtlPresence;
    FDetail: string;
  public
    class function Supported(const AName: string): TXrtlCapability; static; overload;
    class function Supported(const AName, ADetail: string): TXrtlCapability; static; overload;
    class function Unsupported(const AName: string): TXrtlCapability; static; overload;
    class function Unsupported(const AName, ADetail: string): TXrtlCapability; static; overload;
    function HasDetail: Boolean;
    property Name: string read FName;
    property IsSupported: Boolean read FSupported;
    property DetailPresence: TXrtlPresence read FDetailPresence;
    property Detail: string read FDetail;
  end;

function XrtlStatusOk(const AStatus: TXrtlStatus): Boolean;
function XrtlStatusFailed(const AStatus: TXrtlStatus): Boolean;
function XrtlPresenceHasValue(const APresence: TXrtlPresence): Boolean;

implementation

function XrtlStatusOk(const AStatus: TXrtlStatus): Boolean;
begin
  Result := AStatus = xsOk;
end;

function XrtlStatusFailed(const AStatus: TXrtlStatus): Boolean;
begin
  Result := AStatus = xsError;
end;

function XrtlPresenceHasValue(const APresence: TXrtlPresence): Boolean;
begin
  Result := APresence = xpPresent;
end;

class function TXrtlError.Create(const ADomain, ACode, AMessage: string): TXrtlError;
begin
  Result.FDomain := ADomain;
  Result.FCode := ACode;
  Result.FMessage := AMessage;
end;

class function TXrtlError.None: TXrtlError;
begin
  Result := TXrtlError.Create('', '', '');
end;

function TXrtlError.IsEmpty: Boolean;
begin
  Result := (FDomain = '') and (FCode = '') and (FMessage = '');
end;

function TXrtlError.SameIdentity(const AOther: TXrtlError): Boolean;
begin
  Result := (FDomain = AOther.FDomain) and (FCode = AOther.FCode);
end;

class function TXrtlResult.Ok: TXrtlResult;
begin
  Result.FStatus := xsOk;
  Result.FError := TXrtlError.None;
end;

class function TXrtlResult.Fail(const AError: TXrtlError): TXrtlResult;
begin
  Result.FStatus := xsError;
  Result.FError := AError;
end;

class function TXrtlResult.Fail(const ADomain, ACode, AMessage: string): TXrtlResult;
begin
  Result := TXrtlResult.Fail(TXrtlError.Create(ADomain, ACode, AMessage));
end;

function TXrtlResult.Succeeded: Boolean;
begin
  Result := XrtlStatusOk(FStatus);
end;

function TXrtlResult.Failed: Boolean;
begin
  Result := XrtlStatusFailed(FStatus);
end;

class function TXrtlOption.Some(const AValue: T): TXrtlOption;
begin
  Result.FPresence := xpPresent;
  Result.FValue := AValue;
end;

class function TXrtlOption.None: TXrtlOption;
begin
  Result.FPresence := xpMissing;
end;

function TXrtlOption.HasValue: Boolean;
begin
  Result := XrtlPresenceHasValue(FPresence);
end;

function TXrtlOption.IsMissing: Boolean;
begin
  Result := FPresence = xpMissing;
end;

class function TXrtlValueResult.Ok(const AValue: T): TXrtlValueResult;
begin
  Result.FResult := TXrtlResult.Ok;
  Result.FValue := AValue;
end;

class function TXrtlValueResult.Fail(const AError: TXrtlError): TXrtlValueResult;
begin
  Result.FResult := TXrtlResult.Fail(AError);
end;

class function TXrtlValueResult.Fail(const ADomain, ACode, AMessage: string): TXrtlValueResult;
begin
  Result := TXrtlValueResult.Fail(TXrtlError.Create(ADomain, ACode, AMessage));
end;

function TXrtlValueResult.Succeeded: Boolean;
begin
  Result := FResult.Succeeded;
end;

function TXrtlValueResult.Failed: Boolean;
begin
  Result := FResult.Failed;
end;

class function TXrtlCapability.Supported(const AName: string): TXrtlCapability;
begin
  Result.FName := AName;
  Result.FSupported := True;
  Result.FDetailPresence := xpMissing;
  Result.FDetail := '';
end;

class function TXrtlCapability.Supported(const AName, ADetail: string): TXrtlCapability;
begin
  Result := TXrtlCapability.Supported(AName);
  Result.FDetailPresence := xpPresent;
  Result.FDetail := ADetail;
end;

class function TXrtlCapability.Unsupported(const AName: string): TXrtlCapability;
begin
  Result.FName := AName;
  Result.FSupported := False;
  Result.FDetailPresence := xpMissing;
  Result.FDetail := '';
end;

class function TXrtlCapability.Unsupported(const AName, ADetail: string): TXrtlCapability;
begin
  Result := TXrtlCapability.Unsupported(AName);
  Result.FDetailPresence := xpPresent;
  Result.FDetail := ADetail;
end;

function TXrtlCapability.HasDetail: Boolean;
begin
  Result := XrtlPresenceHasValue(FDetailPresence);
end;

end.
