#!/usr/bin/bash

export RAKULIB="./lib"

F1=../SingleCheck

./bin/dlint $F1

cp $F1/new-META6.json .
cp $F1/LintNotes.txt  .

echo "See files 'new-META6.json' and 'LintNotes.txt'"

