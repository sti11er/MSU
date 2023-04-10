include console.inc

.data
   TEXT1 db 512 dup (?)
   TEXT2 db 512 dup (?)
   finText db '-:fin:-', 0
   x db ?

c equ not 15
N equ 1024
; k equ 22 
k equ 23

.code

MemoryRecording proc
     ;ПРОЛОГ процедуры:
     push ebp
     mov ebp,esp; база стекового кадра
     ; сохранение регистров 
     push ebx
     push eax
     push ecx
     push esi 
     push edx

     ; конец ПРОЛОГА процедуры

     mov ebx, [ebp+8]; адрес i-го
     mov [ebx], al
     mov ecx, [ebp+12]; j := tmp
     sub esi, esi  
     dec edx 

     for_loop: 
     mov bl, byte ptr finText[esi]
     mov [ecx], bl; text[ecx] := finText[esi]
     inc esi
     add ecx, 1; i += 1 
     cmp esi, edx 
     jnz for_loop; if esi <> q

     pop edx
     pop esi 
     pop ecx 
     pop eax 
     pop ebx 
     pop ebp 

     ret 2*4 
MemoryRecording endp

; stack
; -16 ecx 
; -12 esi
; -8  edi
; -4  ebx  
; +0  ebp 
; +4  eip адрес возврата
; +8  eax где у нас флаг и текущий символ
; +12 текущий адрес i 
; +16 адреса начала конечной комманды 
; +20 адреса text

; надо передовать flag как var

CheckFinText proc
     ;ПРОЛОГ процедуры:
     push ebp
     mov ebp,esp; база стекового кадра
     ; сохранение регистров 
     push ebx 
     push ecx
     ; конец ПРОЛОГА процедуры
     mov eax, [ebp+8]; флаг (ah) и текущий символ (al)

     mov ecx, edx 
     sub ecx, 1

     mov bl, finText[ecx]; bl := finText[q] 
     cmp al, bl; if c <> finText[q] then
     jnz ld
     cmp ecx, 6 
     jnz ld1  
     inc edx  
     cmp ah, 1
     jnz epilogue1

     dec edx 
     ;push 
     push [ebp+16]; рег в которой хранится адрес начала fintext
     push [ebp+12]; текущий адрес (i)
     call MemoryRecording
     mov ebx, [ebp+12]
     mov [ebx], al 
     xor edx, edx  
     xor ah, ah
     jmp epilogue1
     
     ld1:
     inc edx 
     jmp epilogue1

     ld:
     ;push
     push [ebp+16]; рег в которой хранится адрес начала fintext
     push [ebp+12]; текущий адрес (i)
     call MemoryRecording
     xor edx, edx 
     xor ah, ah
     jmp epilogue1


     ; ЭПИЛОГ процедуры
     ; восстановление регистров 

     epilogue1: 
     pop ecx  
     pop ebx 
     pop ebp 
     
     ret 4*4; Возврат с очисткой стека от 4-x параметров
CheckFinText endp
     
; stack

; +4 eax
; +0 ebp
; +4 eip
; +8 текущий элемент

Convert proc
     ;ПРОЛОГ процедуры:
     push ebp
     mov ebp,esp; база стекового кадра
     ; сохранение регистров 
     push eax 
     ; конец ПРОЛОГА процедуры

     mov eax, [ebp+8]; (al) текущий элемент
     movzx edx, al

     check_on_urgent:
     cmp al, 'a'
     jl check_on_number; if al < 'a'
     cmp al, 'f'
     jg check_on_number; if al > 'f'
     sub edx, 'a'
     add edx, 10
     jmp epilogue2

     check_on_number:
     cmp al, '0'
     jl check_on_litter; if al < 0
     cmp al, '9'
     jg check_on_litter; if al > 9
     sub edx, '0'
     jmp epilogue2

     check_on_litter:
     cmp al, 'A'
     jl ERROR; if al < 'A'
     cmp al, 'F'
     jg ERROR; if al > 'F'
     movzx edx, al
     sub edx, 'A'
     add edx, 10
     jmp epilogue2

     ERROR:
     mov edx, -1 

     epilogue2:
     pop eax
     pop ebp
     
     ret 1*4; Возврат с очисткой стека от 4-x параметров
Convert endp

; stack
; -16 edx 
; -12 eax
; -8 ebx 
; -4  ecx 
; +0  ebp 
; +4  eip адрес возврата
; +8  N
; +12 адреса text

SaveText proc  
     ; ПРОЛОГ процедуры:
     push ebp
     mov ebp,esp; база стекового кадра
     ; сохранение регистров 
     push edi
     push ebx
     push eax
     push edx 
     ;конец ПРОЛОГА процедуры
     xor ebx, ebx; ebx = tmp = 0
     xor edx, edx; edx = q = 0
     mov edi,[ebp+12]; адрес массива X
     xor esi, esi; число переведенное из 16 с.и -> 10 с.и
     xor ah, ah; flag = 0

     mov ecx,1; i 

     @@:
     inchar al; current val = c 

     ; outchar al 
     ; outchar ' ' 
     ; outintln edx 

     state_slash:
     cmp edx, 0;
     jnz fin_shielding_check; if q <> 0 then
     mov bl, '\'; tmp := '\'
     cmp al, bl
     jnz fin_shielding_check; if c <> '\' then 
     mov edx, 1; q = 1
     dec edi ; i := i - 1
     dec ecx ; ecx := ecx - 1
     jmp marker1

     fin_shielding_check:
     cmp edx, 1;
     jnz fin_not_shielding_check; if q <> 1 then
     mov bl, '-'; tmp := '-'
     cmp al, bl
     jnz fin_not_shielding_check; if c <> '-' then 
     mov edx, 2; q = 2
     mov ah, 1; flag = 1          
     mov ebx, edi; tmp = i !!!
     jmp marker1
     
     fin_not_shielding_check: ;state 1
     cmp edx, 0;
     jnz state_9; if q <> 0 then
     mov bl, '-'; tmp := '-'
     cmp al, bl
     jnz state_9; if c <> '-' then 
     mov edx, 2; q = 2
     mov ebx, edi; tmp = i !!!
     jmp marker1

     state_9:
     cmp edx, 1;
     jnz state_10; if flag <> 1 then
     
     mov [edi], al; text[i] := c 
     push eax; текуший элемент
     call Convert; переводим букву в число 
     cmp edx, -1; 
     je exception

     mov esi, edx; в edx у нас число al в дест. с.и
     dec edi; i -= 1
     dec ecx; ecx := ecx - 1
     mov edx, 10
     jmp marker1

     ;если у нас не получилось перевести, значит это просто символ
     exception:
     mov edx, 0; q:=0 
     jmp marker1

     state_10:
     cmp edx, 10
     jnz state_2; if q <> 10 then

     shl esi, 4
     push eax; текуший элемент
     call Convert; переводим букву в число
     cmp edx, -1; 
     je exception1 

     add esi, edx
     mov [edi], esi; text[i] := число \ff

     mov edx, 0 
     jmp marker1

     ; если у нас не получилось перевести, значит это просто число
     exception1:
     inc edi; i += 1
     inc ecx ; ecx := ecx + 1
     mov [edi], al; text[i] := c
     mov edx, 0; q:=0  
     jmp marker1

     state_2:
     cmp edx, 2
     jnz state_3; if q <> 2 then 
     ; push in steck
     push [ebp+12]; text адрес
     push ebx; рег в которой хранится адрес начала fintext
     push edi; текущий адрес (i)
     push eax; flag и c
     call CheckFinText; CheckFinText(text, tmp, i, flag, c, q);
     jmp marker1

     state_3:
     cmp edx, 3
     jnz state_4; if q <> 3 then 
     ; push in steck
     push [ebp+12]; text адрес
     push ebx; рег в которой хранится адрес начала fintext
     push edi; текущий адрес (i)
     push eax; flag и c
     call CheckFinText; CheckFinText(text, tmp, i, flag, c, q);
     jmp marker1

     state_4:
     cmp edx, 4
     jnz state_5; if q <> 4 then 
     ; push in steck
     push [ebp+12]; text адрес
     push ebx; рег в которой хранится адрес начала fintext
     push edi; текущий адрес (i)
     push eax; flag и c
     call CheckFinText; CheckFinText(text, tmp, i, flag, c, q);
     jmp marker1

     state_5:
     cmp edx, 5
     jnz state_6; if q <> 5 then 
     ; push in steck
     push [ebp+12]; text адрес
     push ebx; рег в которой хранится адрес начала fintext
     push edi; текущий адрес (i)
     push eax; flag и c
     call CheckFinText; CheckFinText(text, tmp, i, flag, c, q);
     jmp marker1

     state_6:
     cmp edx, 6
     jnz state_7; if q <> 6 then 
     ;push in steck
     push [ebp+12]; text адрес
     push ebx; рег в которой хранится адрес начала fintext
     push edi; текущий адрес (i)
     push eax; flag и c
     call CheckFinText; CheckFinText(text, tmp, i, flag, c, q);
     jmp marker1

     state_7:
     cmp edx, 7
     jnz text_character; if q <> 7 then 
     ;push in steck
     push [ebp+12]; text адрес
     push ebx; рег в которой хранится адрес начала fintext
     push edi; текущий адрес (i)
     push eax; flag и c
     call CheckFinText; CheckFinText(text, tmp, i, flag, c, q);
     cmp edx, 0
     jnz epilogue3  
     jmp marker1

     text_character:
     mov edx, 0; q := 0
     mov [edi], al; text[i] := c;

     marker1:
     inc edi
     inc ecx
     cmp ecx, [ebp+8]
     jnz @b 

     ;ЭПИЛОГ процедуры
     ;восстановление регистров 

     epilogue3:  
     ; outintln ebx 
     cmp ah, 1
     jz marker13; if flag = 1
     sub ecx, 7 
     marker13: 

     add edi, 1
     mov al, 0 
     mov [edi], al; text[i] := 0;

     check_for_empty:
     cmp ecx, 0
     jnz check_on_512; if lenght text <> 0
     mov esi, -1
     jmp marker12

     check_on_512:
     cmp ecx, 512
     jbe marker12; if ecx <= 512 байт
     mov esi, -1

     marker12: 
     pop edx 
     pop eax
     pop ebx
     pop edi 
     pop ebp 
 
     ret 2*4; Возврат с очисткой стека от 2-x параметров   
SaveText endp

PrintText proc
     ; ПРОЛОГ процедуры:
     push ebp
     mov ebp,esp; база стекового кадра
     ; сохранение регистров 
     push ecx
     push edi
     push ebx 
     push eax 

     ; конец ПРОЛОГА процедуры
     mov ecx,1 
     mov edi,[ebp+12]; адрес массива X

     outstrln '"""'
     mov ah, '"'
     @@:
     mov al, [edi]
     ; outintln ecx 
     cmp al, ah 
     jnz marker11; if al <> "

     ; проверка на выход за границы
     mov ebx, ecx
     add ebx, 1 
     cmp ebx, [ebp+8]
     ja epilogue7; if i+1 > N

     cmp [edi+1], ah 
     jnz marker11; if al+1 <> "

     ; проверка на выход за границы
     mov ebx, ecx
     add ebx, 2
     cmp ebx, [ebp+8]
     ja epilogue7; if i+2 > N

     cmp [edi+2], ah 
     jnz marker11; if al+2 <> "

     ;значит у нас """
     outchar '\' 
     outstr '"""'
     add edi, 2
     jmp next 

     marker11:
     outchar al

     next:
     inc edi
     inc ecx

     cmp ecx, [ebp+8]
     jbe @b
     outstrln '"""'

     ; ЭПИЛОГ процедуры
     ; восстановление регистров 

     epilogue7:
     pop eax
     pop ebx 
     pop edi
     pop ecx
     pop ebp
     
     ret 2*4; Возврат с очисткой стека от 2-x параметров
PrintText endp

GetTheLength proc 
     ; ПРОЛОГ процедуры:
     push ebp
     mov ebp,esp; база стекового кадра
     ; сохранение регистров 
     push ecx
     push edi
     push ebx 
     ; конец ПРОЛОГА процедуры
     mov ecx,[ebp+8]; длина массивов N
     mov edi,[ebp+12]; адрес массива X
     xor eax, eax

     ;основной цикл
     @@:
     mov bl, [edi] 
     cmp bl, 9
     jz marker2; if bl is tab
     cmp bl, 32
     jz marker2; if bl is blank
     cmp bl, 13; if bl is carriage return
     jz marker2
     cmp bl, 10; if bl is line feed
     jz marker2

     jmp marker3

     marker2:
     inc eax
     
     marker3:  
     add edi, 1
     dec ecx
     cmp ecx, 0
     jnz @b 

     ; ЭПИЛОГ процедуры
     ; восстановление регистров 

     pop ebx 
     pop edi
     pop ecx
     pop ebp
     
     ret 2*4; Возврат с очисткой стека от 2-x параметров
GetTheLength endp

Convert1 proc 
     ; ПРОЛОГ процедуры:
     push ebp
     mov ebp,esp; база стекового кадра
     ; сохранение регистров 
     push ecx
     push edi
     push ebx
     push eax 
     push edx 

     ; конец ПРОЛОГА процедуры
     mov ecx,[ebp+8]; длина массивов N
     mov edi,[ebp+12]; адрес массива X
     xor eax, eax 

     @@: 
     mov dl, [edi] 
     cmp dl, 'b'
     jnz marker4

     ; заносим адрес следующей за b ячейки
     mov ebx, edi
     mov eax, ecx

     marker4:
     add edi, 1
     dec ecx
     cmp ecx, 0
     jnz @b    

     cmp eax, 0
     jz epilogue4; if b not found 

     mov ecx, eax
     mov edi, ebx 

     @@: 
     add edi, 1
     dec ecx
     cmp ecx, 0
     jz epilogue4
     mov al, '#'
     mov [edi], al 
     jmp @b  

     ; ЭПИЛОГ процедуры
     ; восстановление регистров 

     epilogue4:
     pop edx 
     pop eax 
     pop ebx 
     pop edi
     pop ecx
     pop ebp
     
     ret 2*4; Возврат с очисткой стека от 2-x параметров
Convert1 endp

CheckLetter proc
     ; ПРОЛОГ процедуры:
     push ebp
     mov ebp,esp; база стекового кадра
     ; сохранение регистров 
     push eax 

     mov eax, [ebp+8]
     ;ebx - flag (0) если это не лат буква (1) иначе
     xor ebx, ebx; flag (0) 

     check_on_urgent1: 
     cmp al, 'a' 
     jl check_on_litter1; if al < 'a'
     cmp al, 'z'
     jg check_on_litter1; if al > 'z'
     jmp marker9

     check_on_litter1:
     cmp al, 'A' 
     jl epilogue5; if al < 'A'
     cmp al, 'Z'
     jg epilogue5; if al > 'Z'
     mov ebx, 1; flag (1)

     marker9:
     mov ebx, 1
     
     epilogue5:
     pop eax 
     pop ebp
     ret 1*4; Возврат с очисткой стека от 1-го параметров
CheckLetter endp

Convert2 proc 
     ; ПРОЛОГ процедуры:
     push ebp
     mov ebp,esp; база стекового кадра
     ; сохранение регистров 
     push ecx
     push edi
     push ebx
     push eax 
     push edx; tmp адрес
     push esi 

     ; конец ПРОЛОГА процедуры
     xor ecx,ecx; i
     inc ecx 
     mov edi,[ebp+12]; адрес массива X 
     mov edx, -1; адрес начала палиндрома
     mov esi, k; сохр сдвиг
     dec esi

     @@: 
     ; outchar byte ptr [edi]
     ; outchar ' '
     ; outint esi 
     ; outchar ' '
     ; outintln ecx 
     ; если мы долшли до середины палиндрома
     overwrite_palindrome: 
     cmp esi, 0 
     jnz marker7; if esi <> 0

     ; проверяем, что символ по середине это лат буква
     mov al, [edi]
     push eax; текущий символ (al) 
     call CheckLetter 

     cmp ebx, 0 
     jz incorrect_palindrome; if flag = 0 then это не лат буква

     mov ebx, 1; 

     mov al, '*'
     ; заменяем все символы палиндрома на *
     cycle: 
     mov [edx], al 
     cmp ebx, k 
     jz marker8
     inc edx 
     inc ebx
     jmp cycle 

     marker8:
     ; восстановление регистров
     mov edi, edx
     mov edx, -1
     mov esi, k 
     dec esi  

     jmp marker6

     marker7:
     mov al, [edi]
     push eax; текущий символ (al) 
     call CheckLetter 
     
     cmp ebx, 0 
     jz incorrect_palindrome; if flag = 0 then это не лат буква

     ; проверка на выход за пределы массива 
     mov ebx, ecx 
     add ebx, esi   

     cmp ebx, [ebp+8]
     ja epilogue6

     mov ah, [edi+esi]
     push eax; символ сдвинутый на +k от текущего
     call CheckLetter 

     cmp ebx, 0 
     jz incorrect_palindrome; if flag = 0 then это не лат буква, идем дальше 

     ; проверка совпадение первой и последней буквы палиндрома
     check_symmetry:
     cmp al, ah 
     jnz incorrect_palindrome; if al <> ah

     sub esi, 2 ; уменьшаем сдвиг
     ; если это начало палиндрома, надо записать его адрес
     check_start:
     cmp edx, -1
     jnz marker6 
     ; если полиндром только начался
     mov edx, edi; сохр адрес начала
     jmp marker6

     incorrect_palindrome:
     ; восстановление регистров
     mov edx, -1
     mov esi, k 
     dec esi

     marker6:
     inc edi
     inc ecx
     cmp ecx, [ebp+8]
     jnz @b    

     ; ЭПИЛОГ процедуры
     ; восстановление регистров 

     epilogue6:
     pop esi 
     pop edx 
     pop eax 
     pop ebx 
     pop edi
     pop ecx
     pop ebp
     
     ret 2*4; Возврат с очисткой стека от 2-x параметров
Convert2 endp

start:
     ConsoleTitle "words processor"
     clrscr

     outstrln " "
     outstrln "Hi, this is an Asembler application for word processing"
     outstrln " "
     outstrln "-------------------------------------------------------------------------------------"
     outstrln "This program determines the length of the text"
     outstrln "as the number of spaces in the text"
     outstrln "(including tab, carriage return, line break)"
     outstrln "Smaller, by length metric, text is handled by the rule: "
     outstrln "all characters following the last occurrence of 'b' in the text"
     outstrln "replace on #"
     outstrln "Larger, according to the length metric, the text is processed according to the rule :"
     outstrln "find polynomials of words of length k in the text,"
     outstrln "consisting of Latin characters and replace them with asterisks"
     outstrln "-------------------------------------------------------------------------------------"
     outstrln " "
     

     outstrln "enter texts:"

     push offset TEXT1; Адрес TEXT1
     push N;  Максимальная длина массива TEXT1
     call SaveText
     mov edx, ecx 

     ; проверка флага ошибки для текста1
     cmp esi, -1
     je log_error

     push offset TEXT1; Адрес TEXT1
     push ecx; длина массива TEXT1
     call GetTheLength
     mov ebx, eax       

     push offset TEXT2; Адрес TEXT2
     push N;  Максимальная длина массива TEXT2
     call SaveText
     mov edi, ecx 

     ; проверка флага ошибки для текста2
     cmp esi, -1
     je log_error

     push offset TEXT2; Адрес TEXT2
     push ecx;  длина массива TEXT2
     call GetTheLength

     outstrln " "
     outstrln "for small length text:"
     outstrln "all characters following the last occurrence of 'b' in the text"
     outstrln "replace on # (its 7 rule)"

     outstrln " "
     outstrln "for larger length text:"
     outstrln "find polynomials of words of length k in the text,"
     outstrln "consisting of Latin characters and replace them with asterisks (its 4 rule)"

     outstrln " "
     outstrln "This program determines the length of the text"
     outstrln "as the number of spaces in the text"
     outstrln "(including tab, carriage return, line break) (its 3 rule)"

     outstrln " "
     outstr "length TEXT1: "
     outintln ebx 
     outstr "length TEXT2: "
     outintln eax

     cmp ebx, eax; 
     jbe convertions1 

     ; if len text1 > len text2
     convertions2:
     ;push text2
     push offset TEXT2; адрес массива text2
     push edi; длина массива text2
     call Convert1

     ;push text1
     push offset TEXT1; адрес массива text1
     push edx; длина массива text1
     call Convert2 

     outstrln " "
     push offset TEXT2; Адрес TEXT2
     push edi; длина массива TEXT2
     call PrintText

     outstrln " "
     push offset TEXT1; Адрес TEXT1
     push edx;  длина массива TEXT1
     call PrintText
     jmp marker10

     ; if len text1 <= len text2
     convertions1:
     ;push text1
     push offset TEXT1; адрес массива text1
     push edx; длина массива text1
     call Convert1
     
     ; push text2
     push offset TEXT2; адрес массива text2
     push edi; длина массива text2
     call Convert2 

     outstrln " "
     push offset TEXT1; Адрес TEXT1
     push edx;  длина массива TEXT1
     call PrintText

     outstrln " "
     push offset TEXT2; Адрес TEXT2
     push edi;  длина массива TEXT2
     call PrintText

     marker10:
     exit
     
     log_error:
     outstrln 'error, incorrect text'
     exit

     end start