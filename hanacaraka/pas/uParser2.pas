unit uParser;

{$mode objfpc}{$H+}

interface

procedure EvalExpr;
procedure ExecStmt;
procedure ExecGunakan; // baru

implementation

uses uLexer, uVM, uError, uImport, SysUtils, Classes;

var
  HasilExpr: Integer;

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

procedure ExecGunakan;
var
  NamaModul: string;
  PathFile: string;
  KodeImport: string;
  SimpanKode: string;
  SimpanI, SimpanPanjang, SimpanBaris, SimpanKolom: Integer;
begin
  // CurToken sekarang = 60 (ꦒꦸꦤꦏꦏꦺ)
  NextToken;

  // Bisa 2 bentuk: 'src/lexer.jkf' (31) atau lexer (99)
  if (CurToken = 31) or (CurToken = 99) then
    NamaModul := CurText
  else
  begin
    TampilError('Setelah ꦒꦸꦤꦏꦏꦺ harus ada nama file, contoh: ꦒꦸꦤꦏꦏꦺ ''src/lexer.jkf'';', Baris, Kolom);
    Exit;
  end;

  NextToken;
  CekToken(41, CurToken, 'Setelah ꦒꦸꦤꦏꦏꦺ harus ada ;, contoh: ꦒꦸꦤꦏꦏꦺ ''src/lexer.jkf'';', Baris, Kolom);
  if AdaError = 1 then Exit;
  NextToken;

  // Kalau udah pernah di-import, skip
  if SudahDiImport(NamaModul) then Exit;

  PathFile := CariFileModul(NamaModul);
  if PathFile = '' then
  begin
    TampilError('File modul tidak ditemukan: ' + NamaModul, Baris, Kolom);
    Exit;
  end;

  TandaiDiImport(NamaModul);

  // Simpan state lexer sekarang
  SimpanKode := Kode;
  SimpanI := I;
  SimpanPanjang := Panjang;
  SimpanBaris := Baris;
  SimpanKolom := Kolom;

  // Load file import, jalanin isinya (fungsi-fungsinya)
  KodeImport := BacaFile(PathFile);
  InitLexer(KodeImport);
  NextToken;
  // Jalanin semua statement di file import sampai habis
  while (CurToken <> 0) and (AdaError = 0) do
  begin
    ExecStmt;
    if CurToken = 41 then NextToken;
    if CurToken = 0 then Break;
    // Kalau ExecStmt udah maju, lanjut. Kalau stuck, paksa maju biar gak infinite loop
  end;

  // Balikin state lexer ke file utama
  Kode := SimpanKode;
  I := SimpanI;
  Panjang := SimpanPanjang;
  Baris := SimpanBaris;
  Kolom := SimpanKolom;
  // NextToken akan dipanggil lagi sama ExecStmt utama
end;

procedure EvalExpr;
begin
  // ... sama kayak sebelumnya ...
end;

procedure ExecStmt;
begin
  if AdaError = 1 then Exit;

  // Handle gunakan duluan
  if CurToken = 60 then
  begin
    ExecGunakan;
    // Setelah import, lanjut ke statement berikutnya
    ExecStmt;
    Exit;
  end;

  if CurToken = 10 then // ꦩꦸꦭꦶ
  // ... sisanya sama ...
end;

end.