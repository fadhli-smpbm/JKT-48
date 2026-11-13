unit uVM;

{$mode objfpc}{$H+}

interface

var
  VarSimpan: string;

procedure SimpanVar(N: string; V: Integer);
function AmbilVar(N: string): Integer;
function StrKeAngka(S: string): Integer;
procedure ResetVM;

implementation

uses uError;

procedure ResetVM;
begin
  VarSimpan := '';
end;

procedure SimpanVar(N: string; V: Integer);
begin
  if N = '' then
  begin
    TampilError('Nama variabel kosong', 0, 0);
    Exit;
  end;
  // Sederhana: simpan sebagai "nama=nilai;"
  VarSimpan := VarSimpan + N + '=' + IntToStr(V) + ';';
end;

function AmbilVar(N: string): Integer;
var
  P: Integer;
  Sisa: string;
  Nama: string;
  NilaiStr: string;
begin
  Result := 0;
  Sisa := VarSimpan;
  while Sisa <> '' do
  begin
    P := Pos(';', Sisa);
    if P = 0 then Break;
    Nama := Copy(Sisa, 1, Pos('=', Sisa) - 1);
    NilaiStr := Copy(Sisa, Pos('=', Sisa) + 1, P - Pos('=', Sisa) - 1);
    if Nama = N then
    begin
      Result := StrToIntDef(NilaiStr, 0);
      Exit;
    end;
    Delete(Sisa, 1, P);
  end;
  TampilError('Variabel tidak ditemukan: ' + N, 0, 0);
end;

function StrKeAngka(S: string): Integer;
begin
  Result := StrToIntDef(S, 0);
end;

end.