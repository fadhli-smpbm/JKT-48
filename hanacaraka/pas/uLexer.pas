unit uLexer;

{$mode objfpc}{$H+}

interface

var
  Kode: string;
  I: Integer;
  Panjang: Integer;
  Baris: Integer;
  Kolom: Integer;
  CurToken: Integer;
  CurText: string;

function ApaHuruf(H: string): Integer;
function ApaAngka(H: string): Integer;
function KeywordKeToken(K: string): Integer;
procedure NextToken;
procedure InitLexer(AKode: string);

implementation

uses uError;

procedure InitLexer(AKode: string);
begin
  Kode := AKode;
  Panjang := Length(Kode);
  I := 1;
  Baris := 1;
  Kolom := 1;
  CurToken := 0;
  CurText := '';
end;

function ApaHuruf(H: string): Integer;
var C: Integer;
begin
  if H = '' then Exit(0);
  C := Ord(H[1]);
  if ((C >= 65) and (C <= 90)) or ((C >= 97) and (C <= 122)) or (C = 95) then
    Result := 1
  else
    Result := 0;
  // Hanacaraka 43008-43135 di-handle sebagai UTF-8 multi-byte,
  // di FPC kita anggap huruf kalau bukan spasi / simbol
  if (C > 127) then Result := 1;
end;

function ApaAngka(H: string): Integer;
var C: Integer;
begin
  if H = '' then Exit(0);
  C := Ord(H[1]);
  if (C >= 48) and (C <= 57) then Result := 1 else Result := 0;
end;

function KeywordKeToken(K: string): Integer;
begin
  if K = 'ꦩꦸꦭꦶ' then Result := 10
else if K = 'ꦒꦸꦤꦏꦏꦺ' then Result := 60
else if K = 'gunakan' then Result := 60; // biar yang ngetik latin juga jalan
  else if K = 'ꦫꦩ꧀ꦥꦸꦁ' then Result := 11
  else if K = 'ꦠꦸꦭꦶꦱ꧀' then Result := 20
  else if K = 'ꦪꦺꦤ꧀' then Result := 12
  else if K = 'ꦩꦺꦴꦁꦏꦺꦴ' then Result := 13
  else if K = 'ꦭꦶꦪꦤꦺ' then Result := 14
  else if K = 'ꦱꦼꦭꦶꦫꦺ' then Result := 15
  else if K = 'ꦭꦏꦺꦴꦤꦶ' then Result := 16
  else if K = 'ꦏꦁꦒꦺꦴ' then Result := 17
  else if K = 'ꦠꦸꦩꦼꦏ' then Result := 18
  else if K = 'ꦥꦿꦺꦴꦒꦿꦩ꧀' then Result := 1
  else if K = 'ꦮꦂ' then Result := 2
  else if K = 'ꦥꦿꦺꦴꦱꦺꦢꦸꦂ' then Result := 3
  else if K = 'ꦥ꦳ꦸꦁꦱꦶ' then Result := 4
  else Result := 99; // identifier
end;

procedure NextToken;
var
  Huruf: string;
  Kata: string;
begin
  while I <= Panjang do
  begin
    Huruf := Copy(Kode, I, 1);
    if Huruf = ' ' then
    begin
      Inc(I); Inc(Kolom); Continue;
    end;
    if Huruf = #10 then
    begin
      Inc(I); Inc(Baris); Kolom := 1; Continue;
    end;
    if Huruf = #13 then
    begin
      Inc(I); Continue;
    end;

    // Angka
    if ApaAngka(Huruf) = 1 then
    begin
      Kata := '';
      while (I <= Panjang) and (ApaAngka(Copy(Kode, I, 1)) = 1) do
      begin
        Kata := Kata + Copy(Kode, I, 1);
        Inc(I); Inc(Kolom);
      end;
      CurToken := 30;
      CurText := Kata;
      Exit;
    end;

    // Huruf / Keyword Hanacaraka (UTF-8 bisa 3 byte, kita baca per karakter visual)
    // Sederhana: baca sampai ketemu spasi / simbol
    if (ApaHuruf(Huruf) = 1) or (Ord(Huruf[1]) > 127) then
    begin
      Kata := '';
      while I <= Panjang do
      begin
        Huruf := Copy(Kode, I, 1);
        if (Huruf = ' ') or (Huruf = ';') or (Huruf = '(') or (Huruf = ')') or (Huruf = ':') or (Huruf = #10) or (Huruf = #13) then Break;
        Kata := Kata + Huruf;
        Inc(I); Inc(Kolom);
        // Hanacaraka 1 huruf = 3 byte UTF-8, tapi di FPC Length hitung byte,
        // jadi kita lanjut sampai delimiter
        if Length(Kata) > 200 then Break;
      end;
      CurToken := KeywordKeToken(Kata);
      CurText := Kata;
      Exit;
    end;

    // :=
    if Huruf = ':' then
    begin
      if Copy(Kode, I + 1, 1) = '=' then
      begin
        CurToken := 40; CurText := ':=';
        Inc(I, 2); Inc(Kolom, 2);
        Exit;
      end
      else
      begin
        TampilError('Ditemukan : tapi bukan :=, mungkin lupa =', Baris, Kolom);
        CurToken := 0; Exit;
      end;
    end;

    if Huruf = ';' then begin CurToken := 41; CurText := ';'; Inc(I); Inc(Kolom); Exit; end;
    if Huruf = '.' then begin CurToken := 44; CurText := '.'; Inc(I); Inc(Kolom); Exit; end;
    if Huruf = '(' then begin CurToken := 45; CurText := '('; Inc(I); Inc(Kolom); Exit; end;
    if Huruf = ')' then begin CurToken := 46; CurText := ')'; Inc(I); Inc(Kolom); Exit; end;
    if Huruf = '+' then begin CurToken := 50; CurText := '+'; Inc(I); Inc(Kolom); Exit; end;
    if Huruf = '-' then begin CurToken := 51; CurText := '-'; Inc(I); Inc(Kolom); Exit; end;
    if Huruf = '*' then begin CurToken := 52; CurText := '*'; Inc(I); Inc(Kolom); Exit; end;
    if Huruf = '/' then begin CurToken := 53; CurText := '/'; Inc(I); Inc(Kolom); Exit; end;
    if Huruf = '=' then begin CurToken := 54; CurText := '='; Inc(I); Inc(Kolom); Exit; end;

// String '...'
if Huruf = '''' then
begin
  Kata := '';
  Inc(I); Inc(Kolom);
  while (I <= Panjang) and (Copy(Kode, I, 1) <> '''') do
  begin
    Kata := Kata + Copy(Kode, I, 1);
    Inc(I); Inc(Kolom);
  end;
  Inc(I); Inc(Kolom); // skip penutup '
  CurToken := 31; // token string
  CurText := Kata;
  Exit;
end;
// tambahan

    // Karakter gak dikenal
    TampilError('Karakter tidak dikenal: ' + Huruf, Baris, Kolom);
    CurToken := 0; Inc(I); Inc(Kolom); Exit;
  end;
  CurToken := 0;
  CurText := '';
end;

end.