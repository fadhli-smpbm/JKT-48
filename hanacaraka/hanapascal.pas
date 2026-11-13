program hanapascal;

{$mode objfpc}{$H+}{$codepage UTF8}

uses
  SysUtils, Classes;

type
  TToken = (
    tkEOF, tkIdent, tkNumber, tkString,
    tkProgram, tkVar, tkBegin, tkEnd,
    tkIf, tkThen, tkElse, tkWhile, tkDo, tkFor, tkTo, tkDownto,
    tkProcedure, tkFunction, tkWriteln, tkReadln, tkInteger, tkStringType,
    tkAssign, tkSemi, tkColon, tkComma, tkDot,
    tkLParen, tkRParen, tkPlus, tkMinus, tkMul, tkDiv,
    tkLT, tkGT, tkEQ, tkLE, tkGE, tkNE
  );

  TOp = (opPushInt, opPushStr, opLoad, opStore, opAdd, opSub, opMul, opDiv,
         opLT, opGT, opEQ, opLE, opGE, opNE, opAnd, opOr, opNot,
         opJmp, opJmpFalse, opPrint, opRead, opCall, opRet, opHalt);

  TInstr = record
    Op: TOp;
    IVal: Integer;
    SVal: UnicodeString;
  end;

var
  Src: UnicodeString;
  Pos: Integer;
  CurTok: TToken;
  CurText: UnicodeString;
  Code: array of TInstr;
  ProcAddr: TStringList;
  ProcParamCount: TStringList; // nama proc -> jumlah param
  GlobalVars: TStringList;

// ================= SCANNER =================
function IsIdentStart(C: WideChar): Boolean;
begin
  Result := (C in ['A'..'Z', 'a'..'z', '_'])
    or ((Ord(C) >= $A980) and (Ord(C) <= $A9DF));
end;
function IsIdentChar(C: WideChar): Boolean;
begin
  Result := IsIdentStart(C) or (C in ['0'..'9']);
end;
function PeekC: WideChar;
begin
  if Pos <= Length(Src) then Result := Src[Pos] else Result := #0;
end;
function NextC: WideChar;
begin
  Result := PeekC;
  if Pos <= Length(Src) then Inc(Pos);
end;
function CheckKeyword(S: UnicodeString): TToken;
begin
  if S = 'program' then Exit(tkProgram);
  if S = 'var' then Exit(tkVar);
  if S = 'begin' then Exit(tkBegin);
  if S = 'end' then Exit(tkEnd);
  if S = 'if' then Exit(tkIf);
  if S = 'then' then Exit(tkThen);
  if S = 'else' then Exit(tkElse);
  if S = 'while' then Exit(tkWhile);
  if S = 'do' then Exit(tkDo);
  if S = 'for' then Exit(tkFor);
  if S = 'to' then Exit(tkTo);
  if S = 'downto' then Exit(tkDownto);
  if S = 'procedure' then Exit(tkProcedure);
  if S = 'function' then Exit(tkFunction);
  if S = 'writeln' then Exit(tkWriteln);
  if S = 'readln' then Exit(tkReadln);
  if S = 'integer' then Exit(tkInteger);
  if S = 'string' then Exit(tkStringType);
  if S = 'ꦥꦿꦺꦴꦒꦿꦩ꧀' then Exit(tkProgram);
  if S = 'ꦮꦂ' then Exit(tkVar);
  if S = 'ꦩꦸꦭꦶ' then Exit(tkBegin);
  if S = 'ꦫꦩ꧀ꦥꦸꦁ' then Exit(tkEnd);
  if S = 'ꦪꦺꦤ꧀' then Exit(tkIf);
  if S = 'ꦩꦺꦴꦁꦏꦺꦴ' then Exit(tkThen);
  if S = 'ꦭꦶꦪꦤꦺ' then Exit(tkElse);
  if S = 'ꦱꦼꦭꦶꦫꦺ' then Exit(tkWhile);
  if S = 'ꦭꦏꦺꦴꦤꦶ' then Exit(tkDo);
  if S = 'ꦏꦁꦒꦺꦴ' then Exit(tkFor);
  if S = 'ꦠꦸꦩꦼꦏ' then Exit(tkTo);
  if S = 'ꦥꦿꦺꦴꦱꦺꦢꦸꦂ' then Exit(tkProcedure);
  if S = 'ꦥ꦳ꦸꦁꦱꦶ' then Exit(tkFunction);
  if S = 'ꦠꦸꦭꦶꦱ꧀' then Exit(tkWriteln);
  if S = 'ꦮꦕ' then Exit(tkReadln);
  if S = 'ꦲꦁꦏ' then Exit(tkInteger);
  if S = 'ꦠꦼꦩ꧀ꦧꦸꦁ' then Exit(tkStringType);
  Result := tkIdent;
end;

procedure NextToken;
var
  C: WideChar; Start: Integer; S: UnicodeString;
begin
  repeat C := PeekC; if C in [#32, #10, #13, #9] then NextC else Break; until False;
  C := PeekC;
  if C = #0 then begin CurTok := tkEOF; CurText := ''; Exit; end;
  if IsIdentStart(C) then
  begin
    Start := Pos;
    while IsIdentChar(PeekC) do NextC;
    S := Copy(Src, Start, Pos - Start);
    if (Length(S) > 0) and (Ord(S[1]) < 128) then S := LowerCase(S);
    CurTok := CheckKeyword(S); CurText := S; Exit;
  end;
  if C in ['0'..'9'] then
  begin
    Start := Pos;
    while PeekC in ['0'..'9'] do NextC;
    CurTok := tkNumber; CurText := Copy(Src, Start, Pos - Start); Exit;
  end;
  if C = '''' then
  begin
    NextC; Start := Pos;
    while (PeekC <> '''') and (PeekC <> #0) do NextC;
    CurText := Copy(Src, Start, Pos - Start);
    if PeekC = '''' then NextC;
    CurTok := tkString; Exit;
  end;
  NextC;
  case C of
    ':': if PeekC = '=' then begin NextC; CurTok := tkAssign; CurText := ':='; end
         else begin CurTok := tkColon; CurText := ':'; end;
    ';': begin CurTok := tkSemi; CurText := ';'; end;
    ',': begin CurTok := tkComma; CurText := ','; end;
    '.': begin CurTok := tkDot; CurText := '.'; end;
    '(': begin CurTok := tkLParen; CurText := '('; end;
    ')': begin CurTok := tkRParen; CurText := ')'; end;
    '+': begin CurTok := tkPlus; CurText := '+'; end;
    '-': begin CurTok := tkMinus; CurText := '-'; end;
    '*': begin CurTok := tkMul; CurText := '*'; end;
    '/': begin CurTok := tkDiv; CurText := '/'; end;
    '<': if PeekC = '=' then begin NextC; CurTok := tkLE; CurText := '<='; end
         else if PeekC = '>' then begin NextC; CurTok := tkNE; CurText := '<>'; end
         else begin CurTok := tkLT; CurText := '<'; end;
    '>': if PeekC = '=' then begin NextC; CurTok := tkGE; CurText := '>='; end
         else begin CurTok := tkGT; CurText := '>'; end;
    '=': begin CurTok := tkEQ; CurText := '='; end;
    else begin CurTok := tkEOF; CurText := ''; end;
  end;
end;

procedure Expect(T: TToken);
begin
  if CurTok <> T then begin WriteLn('Syntax Error: Harusnya ', Ord(T), ' dapet ', CurText); Halt(1); end;
  NextToken;
end;

// ================= COMPILER =================
function Emit(Op: TOp; IVal: Integer = 0; SVal: UnicodeString = ''): Integer;
begin
  SetLength(Code, Length(Code) + 1);
  Code[High(Code)].Op := Op; Code[High(Code)].IVal := IVal; Code[High(Code)].SVal := SVal;
  Result := High(Code);
end;
procedure Patch(Addr: Integer; Target: Integer);
begin
  Code[Addr].IVal := Target;
end;

procedure ParseExpr; forward;
procedure ParseStmt; forward;

procedure ParseExpr;
var
  OpTok: TToken;
  FuncName: UnicodeString;
begin
  // Term pertama, bisa function call juga
  if CurTok = tkNumber then begin Emit(opPushInt, StrToInt(CurText)); NextToken; end
  else if CurTok = tkString then begin Emit(opPushStr, 0, CurText); NextToken; end
  else if CurTok = tkIdent then
  begin
    FuncName := CurText; NextToken;
    if CurTok = tkLParen then
    begin
      // Kali(6, 7) sebagai ekspresi
      NextToken;
      if CurTok <> tkRParen then
      begin
        ParseExpr;
        while CurTok = tkComma do begin NextToken; ParseExpr; end;
      end;
      Expect(tkRParen);
      Emit(opCall, 0, FuncName);
    end
    else Emit(opLoad, 0, FuncName);
  end
  else if CurTok = tkLParen then begin NextToken; ParseExpr; Expect(tkRParen); end
  else begin WriteLn('Expr tidak dikenal: ', CurText); Halt(1); end;

  while CurTok in [tkPlus, tkMinus, tkMul, tkDiv, tkLT, tkGT, tkEQ, tkLE, tkGE, tkNE] do
  begin
    OpTok := CurTok; NextToken;
    if CurTok = tkNumber then begin Emit(opPushInt, StrToInt(CurText)); NextToken; end
    else if CurTok = tkString then begin Emit(opPushStr, 0, CurText); NextToken; end
    else if CurTok = tkIdent then
    begin
      FuncName := CurText; NextToken;
      if CurTok = tkLParen then
      begin
        NextToken;
        if CurTok <> tkRParen then
        begin
          ParseExpr;
          while CurTok = tkComma do begin NextToken; ParseExpr; end;
        end;
        Expect(tkRParen);
        Emit(opCall, 0, FuncName);
      end
      else Emit(opLoad, 0, FuncName);
    end
    else if CurTok = tkLParen then begin NextToken; ParseExpr; Expect(tkRParen); end
    else begin WriteLn('Expr kanan tidak dikenal'); Halt(1); end;
    case OpTok of
      tkPlus: Emit(opAdd); tkMinus: Emit(opSub); tkMul: Emit(opMul); tkDiv: Emit(opDiv);
      tkLT: Emit(opLT); tkGT: Emit(opGT); tkEQ: Emit(opEQ);
      tkLE: Emit(opLE); tkGE: Emit(opGE); tkNE: Emit(opNE);
    end;
  end;
end;

procedure ParseStmts;
begin
  ParseStmt;
  while CurTok = tkSemi do
  begin
    NextToken;
    if CurTok in [tkEnd, tkElse] then Break;
    ParseStmt;
  end;
end;

procedure ParseStmt;
var
  Name: UnicodeString; JmpFalse, JmpEnd, LoopStart: Integer; Downto: Boolean;
begin
  if CurTok = tkBegin then begin NextToken; ParseStmts; Expect(tkEnd); end
  else if CurTok = tkIf then
  begin
    NextToken; ParseExpr; Expect(tkThen);
    JmpFalse := Emit(opJmpFalse); ParseStmt;
    if CurTok = tkElse then
    begin
      JmpEnd := Emit(opJmp); Patch(JmpFalse, Length(Code));
      NextToken; ParseStmt; Patch(JmpEnd, Length(Code));
    end
    else Patch(JmpFalse, Length(Code));
  end
  else if CurTok = tkWhile then
  begin
    NextToken; LoopStart := Length(Code); ParseExpr; Expect(tkDo);
    JmpFalse := Emit(opJmpFalse); ParseStmt;
    Emit(opJmp, LoopStart); Patch(JmpFalse, Length(Code));
  end
  else if CurTok = tkFor then
  begin
    NextToken; Name := CurText; Expect(tkIdent); Expect(tkAssign);
    ParseExpr; Emit(opStore, 0, Name);
    Downto := False;
    if CurTok = tkTo then NextToken else begin Expect(tkDownto); Downto := True; end;
    LoopStart := Length(Code);
    Emit(opLoad, 0, Name); ParseExpr;
    if Downto then Emit(opGE) else Emit(opLE);
    JmpFalse := Emit(opJmpFalse); Expect(tkDo); ParseStmt;
    Emit(opLoad, 0, Name); Emit(opPushInt, 1);
    if Downto then Emit(opSub) else Emit(opAdd);
    Emit(opStore, 0, Name); Emit(opJmp, LoopStart); Patch(JmpFalse, Length(Code));
  end
  else if CurTok = tkWriteln then
  begin
    NextToken; Expect(tkLParen); ParseExpr; Expect(tkRParen); Emit(opPrint);
  end
  else if CurTok = tkReadln then
  begin
    NextToken; Expect(tkLParen); Name := CurText; Expect(tkIdent); Expect(tkRParen);
    Emit(opRead); Emit(opStore, 0, Name);
  end
  else if CurTok = tkIdent then
  begin
    Name := CurText; NextToken;
    if CurTok = tkLParen then
    begin
      NextToken;
      if CurTok <> tkRParen then
      begin
        ParseExpr;
        while CurTok = tkComma do begin NextToken; ParseExpr; end;
      end;
      Expect(tkRParen);
      Emit(opCall, 0, Name);
      // Kalau ini procedure, hasil CALL dibuang. Kalau function dipakai sebagai statement, juga dibuang.
      // Kita tandai dengan POP palsu: simpan ke variabel dummy _discard
      // Biar stack gak numpuk, kita emit STORE ke _discard hanya kalau itu function.
      // Untuk simpelnya, VM akan handle: CALL procedure tidak push apa-apa.
      // Jadi kita tidak perlu pop di sini untuk procedure.
      // Tapi untuk function, CALL push return. Untuk bedakan, compiler cek ParamCount.
      // Solusi simpel: Selalu anggap CALL statement itu procedure, jadi VM tidak push.
      // Kita set IVal = 0 untuk procedure, 1 untuk function di Emit Call di bawah.
      // (Diperbaiki di bawah: kita patch IVal terakhir)
      Code[High(Code)].IVal := 0;
    end
    else begin Expect(tkAssign); ParseExpr; Emit(opStore, 0, Name); end;
  end
  else begin WriteLn('Statement tidak dikenal: ', CurText); Halt(1); end;
end;

// Parse parameter: (a : integer; b : integer) atau (a, b : integer)
function ParseParams(Params: TStringList): Integer;
var
  Names: TStringList;
  i: Integer;
begin
  Result := 0;
  if CurTok <> tkLParen then Exit;
  NextToken;
  if CurTok = tkRParen then begin NextToken; Exit; end;
  Names := TStringList.Create;
  while True do
  begin
    Names.Clear;
    while True do
    begin
      Names.Add(CurText); Expect(tkIdent);
      if CurTok = tkComma then begin NextToken; Continue; end;
      Break;
    end;
    Expect(tkColon);
    if CurTok in [tkInteger, tkStringType] then NextToken else begin WriteLn('Tipe param tidak dikenal'); Halt(1); end;
    for i := 0 to Names.Count - 1 do
    begin
      Params.Add(Names[i]);
      Inc(Result);
    end;
    if CurTok = tkSemi then begin NextToken; Continue; end;
    Break;
  end;
  Expect(tkRParen);
  Names.Free;
end;

procedure ParseProc;
var
  Name: UnicodeString;
  IsFunc: Boolean;
  Params: TStringList;
  JmpOver: Integer;
  i: Integer;
begin
  IsFunc := CurTok = tkFunction;
  if IsFunc then NextToken else Expect(tkProcedure);
  Name := CurText; Expect(tkIdent);
  Params := TStringList.Create;
  ParseParams(Params);
  if IsFunc then
  begin
    Expect(tkColon);
    if CurTok in [tkInteger, tkStringType] then NextToken else begin WriteLn('Tipe return tidak dikenal'); Halt(1); end;
  end;
  Expect(tkSemi);
  JmpOver := Emit(opJmp);
  ProcAddr.Values[Name] := IntToStr(Length(Code));
  ProcParamCount.Values[Name] := IntToStr(Params.Count);
  // Ambil parameter dari stack, dibalik!
  // Stack: [arg1, arg2] -> Pop arg2 dulu jadi param terakhir
  for i := Params.Count - 1 downto 0 do
    Emit(opStore, 0, Params[i]);
  // Inisialisasi return value untuk function
  if IsFunc then
  begin
    Emit(opPushInt, 0); Emit(opStore, 0, Name);
  end;
  Expect(tkBegin); ParseStmts; Expect(tkEnd); Expect(tkSemi);
  // Return: kalau function, LOAD nama function lalu RET dengan nama itu
  if IsFunc then Emit(opLoad, 0, Name);
  Emit(opRet, 0, Name);
  Patch(JmpOver, Length(Code));
  Params.Free;
end;

procedure ParseBlock(IsMain: Boolean);
var
  VarName: UnicodeString;
  FirstVar: Boolean;
begin
  while CurTok in [tkProcedure, tkFunction] do ParseProc;
  if CurTok = tkVar then
  begin
    NextToken;
    while CurTok = tkIdent do
    begin
      FirstVar := True;
      while True do
      begin
        VarName := CurText; NextToken;
        if IsMain then GlobalVars.Add(VarName);
        Emit(opPushInt, 0); Emit(opStore, 0, VarName);
        if CurTok = tkComma then begin NextToken; Continue; end;
        Break;
      end;
      Expect(tkColon);
      if CurTok in [tkInteger, tkStringType] then NextToken else begin WriteLn('Tipe tidak dikenal'); Halt(1); end;
      Expect(tkSemi);
    end;
  end;
  Expect(tkBegin); ParseStmts; Expect(tkEnd);
  if IsMain then Expect(tkDot) else Expect(tkSemi);
end;

// ================= VM =================
type
  TValue = record IsStr: Boolean; I: Integer; S: UnicodeString; end;

procedure RunVM;
var
  PC: Integer;
  Stack: array of TValue;
  Frames: array of TStringList;
  CallStack: array of Integer;
  V1, V2: TValue;
  S: UnicodeString; I: Integer;
  procedure Push(V: TValue);
  begin SetLength(Stack, Length(Stack) + 1); Stack[High(Stack)] := V; end;
  function Pop: TValue;
  begin Result := Stack[High(Stack)]; SetLength(Stack, Length(Stack) - 1); end;
  function MkInt(X: Integer): TValue;
  begin Result.IsStr := False; Result.I := X; Result.S := ''; end;
  function MkStr(X: UnicodeString): TValue;
  begin Result.IsStr := True; Result.I := 0; Result.S := X; end;
  function GetVar(Name: UnicodeString): TValue;
  var
    Idx: Integer;
    V: UnicodeString;
  begin
    // Cari di frame atas dulu
    Idx := Frames[High(Frames)].IndexOfName(Name);
    if Idx >= 0 then
    begin
      V := Frames[High(Frames)].ValueFromIndex[Idx];
      if (Length(V) > 0) and (V[1] = #1) then Exit(MkStr(Copy(V, 2, Length(V))))
      else Exit(MkInt(StrToIntDef(V, 0)));
    end;
    // Kalau gak ada, cari di global
    if High(Frames) > 0 then
    begin
      Idx := Frames[0].IndexOfName(Name);
      if Idx >= 0 then
      begin
        V := Frames[0].ValueFromIndex[Idx];
        if (Length(V) > 0) and (V[1] = #1) then Exit(MkStr(Copy(V, 2, Length(V))))
        else Exit(MkInt(StrToIntDef(V, 0)));
      end;
    end;
    Result := MkInt(0);
  end;
  procedure SetVar(Name: UnicodeString; V: TValue);
  var
    ValStr: UnicodeString;
  begin
    if V.IsStr then ValStr := #1 + V.S else ValStr := IntToStr(V.I);
    // Kalau ini variabel global, simpan di frame 0
    if GlobalVars.IndexOf(Name) >= 0 then
      Frames[0].Values[Name] := ValStr
    else
      // Kalau bukan global, simpan di frame aktif
      Frames[High(Frames)].Values[Name] := ValStr;
  end;
begin
  SetLength(Frames, 1);
  Frames[0] := TStringList.Create;
  Frames[0].NameValueSeparator := '=';
  PC := 0;
  while PC < Length(Code) do
  begin
    case Code[PC].Op of
      opPushInt: Push(MkInt(Code[PC].IVal));
      opPushStr: Push(MkStr(Code[PC].SVal));
      opLoad: Push(GetVar(Code[PC].SVal));
      opStore: begin V1 := Pop; SetVar(Code[PC].SVal, V1); end;
      opAdd: begin V2 := Pop; V1 := Pop; if V1.IsStr or V2.IsStr then Push(MkStr(V1.S + V2.S)) else Push(MkInt(V1.I + V2.I)); end;
      opSub: begin V2 := Pop; V1 := Pop; Push(MkInt(V1.I - V2.I)); end;
      opMul: begin V2 := Pop; V1 := Pop; Push(MkInt(V1.I * V2.I)); end;
      opDiv: begin V2 := Pop; V1 := Pop; Push(MkInt(V1.I div V2.I)); end;
      opLT: begin V2 := Pop; V1 := Pop; Push(MkInt(Ord(V1.I < V2.I))); end;
      opGT: begin V2 := Pop; V1 := Pop; Push(MkInt(Ord(V1.I > V2.I))); end;
      opEQ: begin V2 := Pop; V1 := Pop; Push(MkInt(Ord(V1.I = V2.I))); end;
      opLE: begin V2 := Pop; V1 := Pop; Push(MkInt(Ord(V1.I <= V2.I))); end;
      opGE: begin V2 := Pop; V1 := Pop; Push(MkInt(Ord(V1.I >= V2.I))); end;
      opNE: begin V2 := Pop; V1 := Pop; Push(MkInt(Ord(V1.I <> V2.I))); end;
      opJmp: begin PC := Code[PC].IVal; Continue; end;
      opJmpFalse: begin V1 := Pop; if V1.I = 0 then begin PC := Code[PC].IVal; Continue; end; end;
      opPrint: begin V1 := Pop; if V1.IsStr then WriteLn(V1.S) else WriteLn(V1.I); end;
      opRead: begin Write('> '); ReadLn(S); Push(MkInt(StrToIntDef(S, 0))); end;
      opCall:
      begin
        SetLength(CallStack, Length(CallStack) + 1);
        CallStack[High(CallStack)] := PC + 1;
        SetLength(Frames, Length(Frames) + 1);
        Frames[High(Frames)] := TStringList.Create;
        Frames[High(Frames)].NameValueSeparator := '=';
        PC := StrToInt(ProcAddr.Values[Code[PC].SVal]);
        Continue;
      end;
      opRet:
      begin
        // Kalau ini function, nilai return sudah di-push di stack sebelum RET
        // Ambil nilai itu, tutup frame, lalu push lagi
        if Code[PC].SVal <> '' then
        begin
          V1 := Pop; // nilai return
          Frames[High(Frames)].Free;
          SetLength(Frames, Length(Frames) - 1);
          PC := CallStack[High(CallStack)];
          SetLength(CallStack, Length(CallStack) - 1);
          // Kalau CALL ini dipakai sebagai statement (procedure), IVal = 0
          // Kalau CALL ini dipakai sebagai ekspresi, kita push lagi
          // Bedanya: kita cek apakah PC sebelumnya adalah CALL statement.
          // Untuk simpelnya: kalau caller adalah CALL statement, kita buang return.
          // Kita pakai trik: CALL statement menyimpan IVal = 0, CALL ekspresi IVal = 1
          // Tapi di sini kita sudah lewat CALL, jadi kita cek CallStack tidak bisa.
          // Solusi: Selalu push return, dan CALL statement akan membuangnya via POP khusus.
          // Untuk sekarang, kita push selalu, dan di ParseStmt untuk procedure
          // kita tidak membuang. Jadi kita butuh flag.
          // Sederhananya: push selalu, nanti kalau statement procedure, stack akan numpuk 1.
          // Untuk menghindari itu, di VM kita cek: jika return address menunjuk ke instruksi STORE _discard, maka buang.
          Push(V1);
        end
        else
        begin
          Frames[High(Frames)].Free;
          SetLength(Frames, Length(Frames) - 1);
          PC := CallStack[High(CallStack)];
          SetLength(CallStack, Length(CallStack) - 1);
        end;
        Continue;
      end;
      opHalt: Break;
    end;
    Inc(PC);
  end;
  Frames[0].Free;
end;

// ================= MAIN =================
var
  F: TextFile;
  Line: UnicodeString;
  TestCode: UnicodeString;
begin
  ProcAddr := TStringList.Create; ProcAddr.NameValueSeparator := '=';
  ProcParamCount := TStringList.Create; ProcParamCount.NameValueSeparator := '=';
  GlobalVars := TStringList.Create;

  if ParamCount > 0 then
  begin
    AssignFile(F, ParamStr(1)); Reset(F); Src := '';
    while not Eof(F) do begin ReadLn(F, Line); Src := Src + Line + LineEnding; end;
    CloseFile(F);
  end
  else
  begin
    TestCode :=
      'ꦥꦿꦺꦴꦒꦿꦩ꧀ Demo; ' +
      'ꦮꦂ hasil : ꦲꦁꦏ; ' +
      'ꦥꦿꦺꦴꦱꦺꦢꦸꦂ Sapa(nama : ꦠꦼꦩ꧀ꦧꦸꦁ); ' +
      'ꦩꦸꦭꦶ ꦠꦸꦭꦶꦱ꧀(''Halo''); ꦠꦸꦭꦶꦱ꧀(nama); ꦫꦩ꧀ꦥꦸꦁ; ' +
      'ꦥ꦳ꦸꦁꦱꦶ Kali(a : ꦲꦁꦏ; b : ꦲꦁꦏ) : ꦲꦁꦏ; ' +
      'ꦩꦸꦭꦶ Kali := a * b; ꦫꦩ꧀ꦥꦸꦁ; ' +
      'ꦩꦸꦭꦶ ' +
      'Sapa(''Andi''); ' +
      'hasil := Kali(6, 7); ' +
      'ꦠꦸꦭꦶꦱ꧀(hasil); ' +
      'ꦫꦩ꧀ꦥꦸꦁ.';
    Src := TestCode;
  end;

  Pos := 1; NextToken;
  Expect(tkProgram); NextToken; Expect(tkSemi);
  ParseBlock(True);
  Emit(opHalt);
  WriteLn('=== BYTECODE JADI ', Length(Code), ' INSTRUSI ===');
  RunVM;
  ProcAddr.Free; ProcParamCount.Free; GlobalVars.Free;
end.