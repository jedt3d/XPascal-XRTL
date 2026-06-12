program database_attachment_tests;

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

procedure RunAttachmentMetadataStore;
var
  Connection: TXrtlDatabaseConnection;
  Store: TXrtlDatabaseAttachmentMetadataStore;
  NilStore: TXrtlDatabaseAttachmentMetadataStore;
  Metadata: TXrtlDatabaseAttachmentMetadata;
  Loaded: TXrtlDatabaseAttachmentMetadata;
  Id: Int64;
  ResultInfo: TXrtlResult;
begin
  Connection := TXrtlDatabaseConnection.Create;
  Store := TXrtlDatabaseAttachmentMetadataStore.Create(Connection);
  NilStore := TXrtlDatabaseAttachmentMetadataStore.Create(nil);
  try
    ResultInfo := NilStore.EnsureSchema;
    ExpectFailCode(ResultInfo, 'invalid_connection', 'nil attachment connection');

    ExpectOk(Connection.Open(TXrtlDatabaseConnectionConfig.SQLiteInMemory), 'open attachment connection');
    ExpectOk(Store.EnsureSchema, 'ensure attachment schema');

    Metadata := TXrtlDatabaseAttachmentMetadata.Create(
      'note',
      42,
      'invoice.pdf',
      'application/pdf',
      4096,
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      'local://attachments/42/invoice.pdf',
      'ready',
      '2026-06-12T00:00:00Z');

    ExpectOk(Store.Insert(Metadata, Id), 'insert attachment metadata');
    Expect(Id = 1, 'attachment id');
    ExpectOk(Store.FindByInt64Id(Id, Loaded), 'load attachment metadata');
    Expect(Loaded.Id = Id, 'loaded id');
    Expect(Loaded.OwnerType = 'note', 'loaded owner type');
    Expect(Loaded.OwnerId = 42, 'loaded owner id');
    Expect(Loaded.FileName = 'invoice.pdf', 'loaded file name');
    Expect(Loaded.MediaType = 'application/pdf', 'loaded media type');
    Expect(Loaded.SizeBytes = 4096, 'loaded size');
    Expect(Loaded.Sha256 = Metadata.Sha256, 'loaded sha256');
    Expect(Loaded.StorageUri = Metadata.StorageUri, 'loaded storage uri');
    Expect(Loaded.State = 'ready', 'loaded state');
    Expect(Loaded.CreatedAtUtc = Metadata.CreatedAtUtc, 'loaded timestamp');

    Metadata.FileName := '';
    ResultInfo := Store.Insert(Metadata, Id);
    ExpectFailCode(ResultInfo, 'invalid_attachment_metadata', 'missing attachment file name');

    ResultInfo := Store.FindByInt64Id(99, Loaded);
    ExpectFailCode(ResultInfo, 'attachment_not_found', 'missing attachment metadata');

    ExpectOk(Connection.Close, 'close attachment connection');
  finally
    NilStore.Free;
    Store.Free;
    Connection.Free;
  end;
end;

begin
  RunAttachmentMetadataStore;
  WriteLn('ok: database_attachment_tests');
end.
