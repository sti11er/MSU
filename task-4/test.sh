#!/bin/bash

fpc -gv generator.pas
fpc -gv build_index.pas
fpc -gv matrix_editor.pas
fpc -gv index_mapping.pas
fpc -gv multiplier.pas

echo 
echo "test 1"
echo

valgrind ./generator 10 10 1 dmtr 0.4 1 A

echo 

valgrind ./generator 10 10 3 smtr 1 1 E

echo "build E"

valgrind ./build_index E smtr

echo "Index for E"

valgrind ./matrix_editor E smtr 3 4 1
valgrind ./matrix_editor E smtr 4 3 1
valgrind ./matrix_editor E smtr 4 4 0
valgrind ./matrix_editor E smtr 3 3 0

echo "E modified dot for E"


dot -Tpdf -o E.pdf  E.dot

echo "draw E in mode 1"

valgrind ./index_mapping 1 E

echo "draw E in mode 2"
valgrind ./index_mapping 2 E


echo "RES1 = A x E"
valgrind ./multiplier 3 dmtr RES1 A E

echo "RES2 = A x A x A x A x A"
valgrind ./multiplier 3 dmtr RES2 A A A A A

echo "dot for RES2"

dot -Tpdf -o RES2.pdf  RES2.dot

rm -r *.smtr *.dmtr *.dot 

echo "FIN"

echo
echo "test 2"
echo 

valgrind ./generator 15 9 2 dmtr 0.999 1 A

echo

valgrind ./generator 9 9 3 smtr 1 1 B

echo "build B"

valgrind ./build_index B smtr

echo 

valgrind ./matrix_editor A smtr 1 1 0 

echo "draw A in mode 1"

valgrind ./index_mapping 1 A

echo "draw A in mode 2"

valgrind ./index_mapping 2 A

echo "RES3 = A x B"

valgrind ./multiplier 1 smtr RES3 A B

echo "RES4 = B x B x B x B x B x B x B x B x B x B"

valgrind ./multiplier 0 dmtr RES4 B B B B B B B B B B 

echo "FIN"

rm -r *.smtr *.dmtr *.dot 

echo "test 3"
echo 

valgrind ./generator 50 50 1 smtr 1 1 A

valgrind ./generator 50 50 1 smtr 0 1 B

echo

echo "build A"

valgrind ./build_index A smtr

echo 

echo "draw A in mode 1"

valgrind ./index_mapping 1 A

echo "draw A in mode 2"

valgrind ./index_mapping 2 A

echo "RES5 = A x A x A x A x A x A x A x A x A x B"

valgrind ./multiplier 100000000 smtr RES5 A A A A A  A  A  A  A  B

echo "FIN"

rm -r *.smtr *.dmtr *.dot 

