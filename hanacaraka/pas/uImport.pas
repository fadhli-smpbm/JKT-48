unit uImport;

{$mode objfpc}{$H+}

interface

function SudahDiImport(Nama: string): Boolean;
procedure TandaiDiImport(Nama: string);
function CariFileModul(Nama: string): string;
procedure ResetImport;

implementation

uses SysUtils, Classes;

var
  ListImport: TStringList;

procedure ResetImport;
begin
  if ListImport = nil then
    ListImport := TStringList.Create;
  ListImport.Clear;
end;

function SudahDiImport(Nama: string): Boolean;
begin
  if ListImport = nil then ResetImport;
  Result := ListImport.IndexOf(Nama) >= 0;
end;

procedure TandaiDiImport(Nama: string);
begin
  if ListImport = nil then ResetImport;
  if not SudahDiImport(Nama) then
    ListImport.Add(Nama);
end;

function CariFileModul(Nama: string): string;
begin
  // 1. Kalau udah ada path lengkap, pakai itu
  if FileExists(Nama) then Exit(Nama);
  // 2. Coba src/Nama.jkf
  if FileExists('src/' + Nama + '.jkf') then Exit('src/' + Nama + '.jkf');
  // 3. Coba src/Nama
  if FileExists('src/' + Nama) then Exit('src/' + Nama);
  // 4. Coba Nama.jkf di folder sekarang
  if FileExists(Nama + '.jkf') then Exit(Nama + '.jkf');
  // 5. Coba Nama aja
  if FileExists(Nama) then Exit(Nama);
  Result := '';
end;

initialization
  ListImport := TStringList.Create;
finalization
  ListImport.Free;
end.