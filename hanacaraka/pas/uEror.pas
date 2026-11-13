unit uError;

{$mode objfpc}{$H+}

interface

var
  AdaError: Integer;
  PesanError: string;
  BarisError: Integer;
  KolomError: Integer;
  NamaFile: string;

procedure TampilError(Pesan: string; Baris, Kolom: Integer);
procedure CekToken(Harus, Dapat: Integer; Pesan: string; Baris, Kolom: Integer);
procedure ResetError;

implementation

procedure ResetError;
begin
  AdaError := 0;
  PesanError := '';
  BarisError := 0;
  KolomError := 0;
end;

procedure TampilError(Pesan: string; Baris, Kolom: Integer);
begin
  AdaError := 1;
  PesanError := Pesan;
  BarisError := Baris;
  KolomError := Kolom;
  WriteLn('=== ERROR ===');
  WriteLn('File: ', NamaFile);
  WriteLn('Baris: ', Baris);
  WriteLn('Kolom: ', Kolom);
  WriteLn('Pesan: ', Pesan);
end;

procedure CekToken(Harus, Dapat: Integer; Pesan: string; Baris, Kolom: Integer);
begin
  if Dapat <> Harus then
    TampilError(Pesan, Baris, Kolom);
end;

end.