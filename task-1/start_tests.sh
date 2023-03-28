#!/usr/bin/bash

# 1. correct
# 2. unrecognized command
# 3. error, comment recording error
# 4. error in the notation of the number system
# 5. error in the notation of the number system
# 6. error, invalid character in integer part
# 7. error, fraction part not found
# 8. error, invalid character in fraction part
# 9. error in the notation of the number system
# 10. error, trying to divide by zero
# 11. integer part too large
# 12. correct

# running tests

cd tests

path="$PWD"
files=()

for entry in "$path"/* 
do
	files=( "${files[@]}" "$entry" )
done

cd ..
for file in ${files[@]}; do
	name_file=$(basename ${file})
	echo "Run test file ${name_file}"
	./my_calculator 0.1 2 10 < $file
	echo "									"
done
