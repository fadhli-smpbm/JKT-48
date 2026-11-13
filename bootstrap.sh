#!/bin/bash
set -e
echo "=== Hanacaraka Bootstrap (.jkf) ==="

echo "[1/5] Compile kompiler FPC..."
fpc hanapascal.pas -o hanapascal_bin

echo "[2/5] Codegen codegen3 pakai interpreter..."
./hanapascal_bin hanapascal_hana_codegen3.jkf hanapascal_hana_codegen3.jkf out_codegen.pas

echo "[3/5] Compile codegen jadi binary..."
fpc out_codegen.pas -o out_codegen_bin

echo "[4/5] Test codegen binary..."
./out_codegen_bin contoh/01_hello.jkf out_test.pas
fpc out_test.pas -o out_test_bin
./out_test_bin

echo "[5/5] Test semua contoh .jkf..."
for f in contoh/*.jkf; do
  echo "--- $f ---"
  ./hanapascal_bin "$f"
done

echo "Bootstrap berhasil!"