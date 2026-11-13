program hanapascal;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  uError, uLexer, uParser, uVM, uCodegen, uImport;

var
  Kode: string;
  SL: TStringList;
  NamaFile: string;
  Mode: string;

function BacaFile(FN: string): string;
var L: TStringList;
begin
  L := TStringList.Create;
  try
    if FileExists(FN) then L.LoadFromFile(FN);
    Result := L.Text;
  finally
    L.Free;
  end;
end;

begin
  if ParamCount >= 1 then
    NamaFile := ParamStr(1)
  else
    NamaFile := 'contoh/01_hello.jkf';

  uError.NamaFile := NamaFile;
  uError.ResetError;
  uVM.ResetVM;

  Kode := BacaFile(NamaFile);
  if Kode = '' then
  begin
    WriteLn('File tidak ketemu atau kosong: ', NamaFile);
    Halt(1);
  end;

// di begin, sebelum InitLexer:
uImport.ResetImport;

  InitLexer(Kode);
  NextToken;
  ExecStmt;

  if AdaError = 0 then
    WriteLn('Selesai, tidak ada error')
  else
    WriteLn('Program berhenti karena error di atas');
end.