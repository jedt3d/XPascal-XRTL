program database_smoke;

{$mode objfpc}{$H+}

uses
  xrtl_database;

procedure Expect(const Condition: Boolean; const Message: string);
begin
  if not Condition then
  begin
    WriteLn('fail: ', Message);
    Halt(1);
  end;
end;

var
  Config: TXrtlSqliteConnectionConfig;
begin
  Expect(XRTL_DATABASE_LIBRARY_NAME = 'XRTL.Database', 'library name');
  Expect(XRTL_DATABASE_CONTRACT_VERSION = 1, 'contract version');
  Expect(XRTL_DATABASE_ERROR_DOMAIN = 'xrtl.database', 'error domain');

  Config := TXrtlSqliteConnectionConfig.InMemory;
  Expect(Config.IsValid, 'memory config valid');
  Expect(Config.IsInMemory, 'memory config marker');
  Expect(Config.DatabasePath = ':memory:', 'memory database path');

  Config := TXrtlSqliteConnectionConfig.FileDatabase('local.sqlite');
  Expect(Config.IsValid, 'file config valid');
  Expect(not Config.IsInMemory, 'file config not memory');
  Expect(Config.DatabasePath = 'local.sqlite', 'file database path');

  Config := TXrtlSqliteConnectionConfig.FileDatabase('');
  Expect(not Config.IsValid, 'empty config invalid');

  WriteLn('ok: database_smoke');
end.
