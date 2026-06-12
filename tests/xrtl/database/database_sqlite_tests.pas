program database_sqlite_tests;

{$mode objfpc}{$H+}

uses
  SysUtils, xrtl_core, xrtl_database;

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

function BuildDatabasePath: string;
begin
  Result := IncludeTrailingPathDelimiter(GetCurrentDir) + 'build' + DirectorySeparator + 'xrtl_database_sqlite_test.sqlite';
end;

var
  DatabasePath: string;
  Database: TXrtlSqliteDatabase;
  ResultInfo: TXrtlResult;
  Count: Int64;
begin
  DatabasePath := BuildDatabasePath;
  DeleteFile(DatabasePath);

  Database := TXrtlSqliteDatabase.Create;
  try
    ResultInfo := Database.Execute('create table should_fail(id integer)');
    ExpectFailCode(ResultInfo, 'not_open', 'execute before open');

    ResultInfo := Database.Open(TXrtlSqliteConnectionConfig.FileDatabase(''));
    ExpectFailCode(ResultInfo, 'invalid_config', 'empty database path');

    ExpectOk(Database.Open(TXrtlSqliteConnectionConfig.FileDatabase(DatabasePath)), 'open sqlite file');
    Expect(Database.IsOpen, 'database is open');
    Expect(Database.DatabasePath = DatabasePath, 'database path retained');

    ResultInfo := Database.Open(TXrtlSqliteConnectionConfig.FileDatabase(DatabasePath));
    ExpectFailCode(ResultInfo, 'already_open', 'double open');

    ExpectOk(Database.Execute(
      'create table notes (' +
      'id integer primary key autoincrement, ' +
      'title text not null)'), 'create notes table');
    ExpectOk(Database.Execute('insert into notes(title) values (''alpha'')'), 'insert alpha');
    ExpectOk(Database.Execute('insert into notes(title) values (''beta'')'), 'insert beta');
    ExpectOk(Database.QueryInt64('select count(*) from notes', Count), 'query note count');
    Expect(Count = 2, 'note count');

    ExpectOk(Database.Close, 'close sqlite file');
    Expect(not Database.IsOpen, 'database closed');
    Expect(FileExists(DatabasePath), 'sqlite file created');
  finally
    Database.Free;
    DeleteFile(DatabasePath);
  end;

  WriteLn('ok: database_sqlite_tests');
end.
