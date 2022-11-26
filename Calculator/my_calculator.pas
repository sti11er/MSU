program my_calulator;

{$mode objfpc}{$H+}

Uses sysutils,
	{$IFDEF UNIX}{$IFDEF UseCThreads}
	cthreads,
	{$ENDIF}{$ENDIF}
	Classes, 
	Math;


const 
	OPERATIONS = ['+', '-', '*', '/'];
	ALPHABET = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@#$%^&*';
	FINISH_WORD = 'finish';


type states = (operation, base, int_part, fraction_part, finish, comment);

var result: real; infile: textfile; j: integer; 
	precisionExp: real; error_log: string; 


(* function for checks that char is in string, return boolean *)
function charInString(ch: char; str: string): boolean;
var i: integer; res: boolean;
begin
	res := false;
	for i := 1 to length(str) do 
	begin
		if ch = str[i] then 
			res := true;
	end;
	charInString := res;
end;

(* ASCII number values  *)
(* 
32 - blank
13 - Tab
10 - line feed
9 - carriage return  
26 - substitution 
*)

(* function implements the processing of user file or shell input *)
function parser(): real;
var flag, base_is_read, int_part_is_read, fraction_part_is_read, comment_is_read: boolean; 
	state: states; 
	el: char;
	curr_operation: char; 
	curr_base: integer;
	pos_el: integer;
	curr_int_part: int64;
	curr_fraction_part: real; 
	index: integer;
	sign: integer;
	spliced_recording: real;
	i: integer;
	separator_oper_base: boolean;
	degree_of_two_el: integer;
	flag2 : integer;
begin
	result := 0.0;
	curr_base := 0;
	flag := true;
	base_is_read := false;
	int_part_is_read := false;
	fraction_part_is_read := false;
	comment_is_read := false;
	state := operation;
	curr_int_part := 0;
	curr_fraction_part := 0;
	index := -1;
	sign := 1;
	spliced_recording := 0;
	i := 0;
	separator_oper_base := false;
	degree_of_two_el := 0;
	flag2 := 0;


	while flag do 
	begin
		(*  if end line or end file *)
		if eoln() or eof() then
		begin
			(* if fraction part not found *)
			if (fraction_part_is_read = false) and (int_part_is_read = true) then 
			begin
				error_log := 'error, fraction part not found';
				flag := false;
			end;
			spliced_recording := sign * (curr_int_part+curr_fraction_part);
			if (curr_operation = '/') and (Round(spliced_recording) = 0) then
			begin
				error_log := 'error, trying to divide by zero';
				flag := False;
			end
			else 
			begin
				case curr_operation of
					'+': result := result + spliced_recording;
					'-': result := result - spliced_recording;
					'*': result := result * spliced_recording;
					'/': result := result / spliced_recording;
				end;

				int_part_is_read := false; fraction_part_is_read := false;
				base_is_read := false;	comment_is_read := false;
				flag := true;
				curr_base := 0;
				curr_int_part := 0;
				curr_operation := ' ';
				curr_fraction_part := 0;
				index := -1;
				sign := 1;
				spliced_recording := 0;
				separator_oper_base := false;
				i := 0;
				degree_of_two_el := 0;
				flag2 := 0;
				state := operation;
				readln();
			end;
		end;    
		(*  if end file *)
		if eof() then flag := False;

		case state of
			operation: 
				begin
					read(el);
					if el in OPERATIONS then
					begin
						state := base;
						curr_operation := el;
					end
					else if (ord(el) <> 32) and (ord(el) <> 13) 
						and (ord(el) <> 10) and (ord(el) <> 9)  
						and (ord(el) <> 26) then 
					begin
						if el = FINISH_WORD[1] then state := finish
						else if el = ';' then readln()
						else 
						begin
							error_log := 'such an operation does not exist';
							flag := false;
						end; 
					end
				end;
			base:
				begin
					read(el);
					if (ord(el) = 32) or (ord(el) = 9) then 
						separator_oper_base := true;

					if (el >= '0') and (el <= '9') and separator_oper_base then 
					begin
						curr_base := curr_base*10 + StrToInt(el);
						base_is_read := true;
					end
					else if el = ':' then
					begin
						if (curr_base = 0) or (curr_base = 1) then
						begin
							error_log := 'you did not enter a non-existent number system';
							flag := false;
						end
						else if base_is_read then
						begin
							state := int_part;
							base_is_read := false;
						end;
					end
					else if ((ord(el) = 32) or (ord(el) = 9)) and (base_is_read) then
					begin
						error_log := 'you did not enter the number system';
						flag := false;
					end
					else if (ord(el) <> 32) and (ord(el) <> 9) then  
					begin
						error_log := 'error in the notation of the number system';
						flag := false;
					end; 
				end;
			int_part:
				begin 
					read(el);
					pos_el := pos(el, ALPHABET) - 1;

					if charInString(el, ALPHABET) then
					begin
						(* the number represents the degree of two (upward) *)
						if curr_int_part <> 0 then
						begin
							if Frac(Logn(2, curr_int_part)) = 0 then flag2 := 0
							else flag2 := 1;
							degree_of_two_el := trunc(Logn(2, curr_int_part)) + flag2;
						end;

						(* check that the current_char we entered valid in the numeral system we entered *)
						if pos_el >= curr_base then 
						begin
							error_log := 'error, invalid character in integer part';
							flag := false;
						end
						(*  overflow exit check int_part *)
						else if (degree_of_two_el > 31) then 
						begin 
							error_log := 'integer part too large';
							flag := false;
						end 
						else (* write in integer_part number in decimal notation *)
						begin
							curr_int_part := curr_int_part * curr_base + pos_el;
							int_part_is_read := true;
						end;
					end
					(*  situation with "-" operation *)
					else if el = '-' then sign := -1
					else if el = '.' then 
					begin
						if int_part_is_read then begin
							state := fraction_part;
							int_part_is_read := false;
						end
						else begin
							error_log := 'integer part number not found';
							flag := false;
						end;
					end
					else begin
						error_log := 'incorrect integer part number';
						flag := false;
					end;
				end;
			fraction_part:
				begin 
					read(el); 
					pos_el := pos(el, ALPHABET) - 1;

					if (el = ';') or (ord(el) = 32) or (ord(el) = 9) or (ord(el) = 13) or (ord(el) = 10) then 
						fraction_part_is_read := false
					else if charInString(el, ALPHABET) then
					begin
						if pos_el >= curr_base then 
						begin
							error_log := 'error, an invalid character in the fractional part in this number system';
							flag := false;
						end
						else
						begin
							curr_fraction_part := curr_fraction_part + (pos(el, ALPHABET)-1) * Power(curr_base, index);
							index := index - 1;
							fraction_part_is_read := true;
						end;
					end
					else 
					begin
						error_log := 'error, invalid character in fraction part';
						flag := false;
					end; 
					(*  if blank or Tab then check valid comment *)
					if (ord(el) = 32) or (ord(el) = 9) then state := comment;
					(*  if line feed then comment not found go into the new operation*)
					if (ord(el) = 10) then state := operation;
				end;
			comment:
				begin
					read(el);
					if ord(el) = 10 then state := operation 
					else 
					begin
						if el = ';' then comment_is_read := true;
						if (ord(el) <> 32) and (ord(el) <> 9) and (ord(el) <> 13) then 
						begin
							if not comment_is_read then
							begin
								error_log := 'error, comment recording error';
								flag := false;
							end
							else 
							begin
								state := operation;
								comment_is_read := false;
							end
						end;
					end;
				end;
			finish:
				begin
					i := 1;
					while i <= length(FINISH_WORD) do 
					begin 
						if el <> FINISH_WORD[i] then
						begin
							error_log := 'unrecognized command';
							flag := false;
						end;
						read(el);
						i := i + 1;
					end;
					flag := false;
				end;
		end;
	end;

	writeln(error_log);
	parser := result;
end;

(* function for translation number from decimal notation to n notation *)
function translator(num: real; base: integer): string;
var 
	integer_part: longint;
	fraction_part: real;
	precisionTran: integer;
	new_integer_part: string;
	new_fraction_part: string;
	sign: string;
	translator_res: string;	
	point: string;
	i: integer;
	frac_tmp: real;
begin
	point := '.';
	i := 0;

	precisionTran := 1;

	if paramCount() <> 0 then 
		precisionTran := trunc(-Logn(base, StrToFloat(paramStr(1)))) + 1;

	if base = 10 then 
	begin
		(* FloatToStrF(Value; Format; Precision, Digits) *)
		(* ffFixed its represent number as fixed point format *)
		translator := FloatToStrF(num, ffFixed, precisionTran-1, precisionTran-1);
	end
	else 
	begin
		if num < 0 then 
		begin
			sign := '-'; 
			num := -1 * num;
		end;  

		integer_part := trunc(num);
		fraction_part := frac(num);

		new_integer_part := '0';
		while integer_part > 0 do 
		begin
			new_integer_part := ALPHABET[integer_part mod base + 1] + new_integer_part;
			integer_part := integer_part div base;
		end;

		i := 0;
		while i < precisionTran do 
		begin
			frac_tmp := fraction_part * base;
			new_fraction_part := new_fraction_part + ALPHABET[trunc(frac_tmp)+1];
			fraction_part := frac(frac_tmp);
			i := i + 1;
		end;

		translator_res := sign + new_integer_part + point + new_fraction_part;
		translator := translator_res;
	end;
end;

begin
	if (paramCount() = 0) then
		writeln('program parameters not found')
	else if (paramCount() <> 0) and (StrToFloat(paramStr(1)) = 0) then 
		writeln('the accuracy you entered is not valid')
	else begin    
		error_log := '';
		precisionExp := StrToFloat(paramStr(1));
		result := parser();
		result := Round(result / precisionExp) * precisionExp;
		if error_log = '' then
		begin
			for j := 2 to paramCount() do 
				writeln(paramStr(j), '    ', translator(result, StrToInt(paramStr(j))));
		end;
	end;
end.
