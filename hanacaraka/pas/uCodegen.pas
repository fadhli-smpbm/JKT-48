unit uCodegen;

{$mode objfpc}{$H+}

interface

function GenCode(AKode: string): string;

implementation

uses uLexer, uParser, uError, uVM, SysUtils;

function GenCode(AKode: string): string;
var
  OutKode: string;
begin
  // Versi simpel: untuk sekarang codegen pakai jalur interpreter
  // Nanti kamu kembangin jadi full: ꦠꦸꦭꦶꦱ꧀ -> writeln
  OutKode := 'program Out;' + LineEnding + 'begin' + LineEnding;
  OutKode := OutKode + '  writeln(''Codegen belum full, pakai VM dulu'');' + LineEnding;
  OutKode := OutKode + 'end.' + LineEnding;
  Result := OutKode;
end;

end.