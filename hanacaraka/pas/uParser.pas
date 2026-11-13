unit uParser;

{$mode objfpc}{$H+}

interface

procedure EvalExpr;
procedure ExecStmt;

implementation

uses uLexer, uVM, uError, SysUtils;

var
  HasilExpr: Integer;

procedure EvalExpr;
begin
  if AdaError = 1 then Exit;
  if CurToken = 30 then
  begin
    HasilExpr := StrKeAngka(CurText);
    NextToken;
  end
  else if CurToken = 99 then
  begin
    HasilExpr := AmbilVar(CurText);
    NextToken;
  end
  else
    TampilError('Diharapkan angka atau variabel, tapi ketemu: ' + CurText, Baris, Kolom);
end;

procedure ExecStmt;
var
  NamaVar: string;
begin
  if AdaError = 1 then Exit;

  if CurToken = 10 then // ꦩꦸꦭꦶ
  begin
    NextToken;
    ExecStmt;
    if CurToken = 41 then NextToken;
    ExecStmt;
  end
  else if CurToken = 20 then // ꦠꦸꦭꦶꦱ꧀
  begin
    NextToken;
    CekToken(45, CurToken, 'Setelah ꦠꦸꦭꦶꦱ꧀ harus ada (, contoh: ꦠꦸꦭꦶꦱ꧀(x)', Baris, Kolom);
    if AdaError = 1 then Exit;
    NextToken;
    EvalExpr;
    CekToken(46, CurToken, 'Setelah ekspresi di ꦠꦸꦭꦶꦱ꧀ harus ada ), contoh: ꦠꦸꦭꦶꦱ꧀(x)', Baris, Kolom);
    if AdaError = 1 then Exit;
    NextToken;
    WriteLn(HasilExpr);
  end
  else if CurToken = 99 then // variabel := expr
  begin
    NamaVar := CurText;
    NextToken;
    CekToken(40, CurToken, 'Setelah nama variabel harus ada :=, contoh: x := 10', Baris, Kolom);
    if AdaError = 1 then Exit;
    NextToken;
    EvalExpr;
    SimpanVar(NamaVar, HasilExpr);
  end
  else if CurToken = 11 then // ꦫꦩ꧀ꦥꦸꦁ
  begin
    // berhenti, jangan error
  end
  else if CurToken = 0 then
  begin
    // EOF
  end
  else
    TampilError('Statement tidak dikenal, mungkin lupa ꦩꦸꦭꦶ atau salah ketik keyword', Baris, Kolom);
end;

end.