unit matrix; 

interface 

uses index, sysutils, Math;


procedure smtr_parser(var f: text; var tmp_smtr_matrix: tmp_type; var n, m: integer);	
procedure dmtr_parser(var f: text; var tmp_dmtr_matrix: tmp_type; var n, m: integer);
procedure write_in_dmtr_file(t: tree; var f: text; n, m: integer; var dmtr_flag: boolean);
procedure write_in_smtr_file(t: tree; var f: text; n, m: integer; var smtr_flag: boolean);

implementation

(* парсер данных из .dmtr файла 
   f - dmtr файл, tmp_dmtr_matrix - временный 
   массив состоящий из рекордов в котором лежит i, j, val  *)

procedure dmtr_parser(var f: text; var tmp_dmtr_matrix: tmp_type; var n, m: integer);
var c: char; text_dmtr: string;

	count, e, i, sgn: integer;
    flag, dig, mat, cor: boolean;
    sep: set of byte;
    index: longword;
    number: real;

begin
	text_dmtr := 'sparse_matrix';

	flag := false;
    dig := false;
    mat := false;
    cor := false;
    
    index := 0;
    sgn := 1;
    e := 0;
    count := 0;
    number := 0.0;
    n := 0;
    m := 0;
    sep := [10, 9, 13, 32];

	while not eof(f) do
	begin
		read(f, c);
		case c of
			'#': 
				if (count = 0) or cor then 
				begin
					readln(f);
					count := 0;
					cor := false;
				end
				else  
					flag := true;
			's':
				if not mat then 
				begin
					i := 2;
					while (not eof(f)) do
					begin
						read(f, c);
						if i = (length(text_dmtr)+1) then
						begin
							if not (ord(c) in sep) then
								flag := true;
							break;
						end
						else if c <> text_dmtr[i] then
						begin	
							flag := true;
							break;
						end;

						i := i + 1;
					end;
	
					if not flag then
						mat := true;
				end 
				else 
					flag := true;   
			'-': 
				if mat and (not dig) then 
				begin
					dig := true;
					sgn := -1;
				end 
				else
					flag := true;
			'0' .. '9': 
				if mat then begin
					dig := true;
					if e > 0 then 
					begin
						number := number + (ord(c) - ord('0'))/Power(10, e);
						e += 1;
					end
					else 
					begin
						number := number * 10 + (ord(c) - ord('0'));
					end;
				end 
				else
					flag := true;
			'.': 
				if dig then 
					e := 1
				else
					flag := true;
			else
				if not (ord(c) in sep) then
                    flag := true
                else begin
                    if dig then
                        if ((count = 2) and not cor) or ((count < 2) and (e = 0) and (sgn = 1)) then begin
                            count += 1;
                            if not (n > 0) then
                                n := round(number)
                            else 
                                if not (m > 0) then 
                                    begin
                                        m := round(number);
                                        cor := true;
                                    end
                                else
                                    if count = 3 then begin
                                        cor := true;
                                    end;

                            dig := false;
                            if e > 0 then
                            begin
                                tmp_dmtr_matrix[index].val := sgn*(number);
                            	index := index + 1;
                            end
                            else if count = 1 then
                            	if (number > n) or (number = 0) then 
                            	begin
                            		flag := true;
                            		break
                            	end
                            	else
                            	begin
                            		SetLength(tmp_dmtr_matrix, index+1);
                            		tmp_dmtr_matrix[index].i := round(number);
                            	end
                            else 
                            	if (number > m) or (number = 0) then 
                            	begin
                            		flag := true;
                            		break
                            	end
                            	else
                            		tmp_dmtr_matrix[index].j := round(number);

                            number := 0.0;
                            e := 0;
                            sgn := 1;
                        end else
                            flag := true;
                        if (ord(c) = 10) then 
                            if cor or (count = 0) then begin
                               count := 0;
                               cor := false;
                            end
                            else
                               flag := true
                end;
        end;
        if flag then
        begin
            writeln('ERROR!!!');
            break;
        end;
	end;
end;

(* парсер данных из .smtr файла 
   f - dmtr файл, tmp_smtr_matrix - временный 
   массив состоящий из рекордов в котором лежит i, j, val  *)

procedure smtr_parser(var f: text; var tmp_smtr_matrix: tmp_type; var n, m: integer);
var c: char; text_dmtr: string;

	count, e, i, sgn: integer;
    flag, dig, mat, cor: boolean;
    sep: set of byte;
    index: longword;
    tmp: integer;
    number: real;

begin
	text_dmtr := 'dence_matrix';

	flag := false;
    dig := false;
    mat := false;
    cor := false;
    
    tmp := 0;
    index := 0;
    sgn := 1;
    e := 0;
    count := 0;
    number := 0.0;
    n := 0;
    m := 0;
    sep := [10, 9, 13, 32];

	while not eof(f) do
	begin
		read(f, c);
		case c of
			'#': 
				if (count = 0) or cor then 
				begin
					readln(f);
					count := 0;
					cor := false;
				end
				else  
					flag := true;
			'd':
				if not mat then 
				begin
					i := 2;
					while (not eof(f)) do
					begin
						read(f, c);
						if i = (length(text_dmtr)+1) then
						begin
							if not (ord(c) in sep) then
								flag := true;
							break;
						end
						else if c <> text_dmtr[i] then
						begin	
							flag := true;
							break;
						end;

						i := i + 1;
					end;
	
					if not flag then
						mat := true;
				end 
				else 
					flag := true;   
			'-': 
				if mat and (not dig) then 
				begin
					dig := true;
					sgn := -1;
				end 
				else
					flag := true;
			'0' .. '9': 
				if mat then 
				begin
					dig := true;
					if e > 0 then 
					begin
						number := number + (ord(c) - ord('0'))/Power(10, e);
						e += 1;
					end
					else 
					begin
						number := number * 10 + (ord(c) - ord('0'));
					end;
				end 
				else
					flag := true;
			'.': 
				if dig then 
					e := 1
				else
					flag := true;
			else
				if not (ord(c) in sep) then
                    flag := true
                else 
                begin
                    if dig then
                        if not cor then begin
                            count += 1;
                            dig := false;
                            if (number <> 0.0) and (e > 0) then
                            begin
                            	SetLength(tmp_smtr_matrix, index+1);
                            	tmp_smtr_matrix[index].i := tmp + 1; 
                            	tmp_smtr_matrix[index].j := count; 
                                tmp_smtr_matrix[index].val := sgn*(number);
                            	index := index + 1;
                            end;

                            if not (n > 0) then
                            begin
                            	if (e = 0) and (sgn = 1) then
                                	n := round(number)
                                else 
                                	flag := true
                            end
                            else 
                                if not (m > 0) then 
                                begin
	                            	if (e = 0) and (sgn = 1) then
	                                begin
                                        m := round(number);
                                        cor := true;
                                        tmp := 0;
                                    end
	                                else 
	                                	flag := true
	                            end 
                                else
                                    if count = m then 
                                    begin
                                        cor := true;
                                        tmp += 1;
                                        if tmp = n then 
                                        begin
                                        	mat := false;
                                        end;
                                    end;

                            number := 0.0;
                            e := 0;
                            sgn := 1;
                        end else
                        begin
                            flag := true;
                        end;
                        if (ord(c) = 10) then 
                            if cor or (count = 0) then begin
                               count := 0;
                               cor := false;
                            end
                            else
                               flag := true;
                end;
        end;

        if flag then
        begin
            writeln('ERROR!!!');
            break;
        end;
	end;
	if mat then
	begin
		writeln('ERROR!!!');
	end;

end;

(* процедура формирующая файл dmtr по переданному в виде аргумента, дереву t, 
dmtr_flag - флаг нужный для определения начала данных матрицы *)

procedure write_in_dmtr_file(t: tree; var f: text; n, m: integer; var dmtr_flag: boolean);
begin
	if dmtr_flag then
	begin
		writeln(f, 'sparse_matrix', ' ', n, ' ', m);
		writeln(f);
		dmtr_flag := false;
	end;

	if t <> nil then
	begin
		write_in_dmtr_file(t^.left, f, n, m, dmtr_flag);
		writeln(f, t^.row, ' ', t^.column, ' ', t^.element:4:4);
		write_in_dmtr_file(t^.right, f, n, m, dmtr_flag);
	end;
end;


(* процедура формирующая файл smtr по переданному в виде аргумента, дереву t, 
smtr_flag - флаг нужный для определения начала данных матрицы *)
procedure write_in_smtr_file(t: tree; var f: text; n, m: integer; var smtr_flag: boolean);
	procedure write_node(t: tree; var f: text; n, m: integer; var smtr_flag: boolean; var i, j: integer);
	begin
		if smtr_flag then
		begin
			writeln(f, 'dance_matrix', ' ', n, ' ', m);
			writeln(f);
			smtr_flag := false;
		end;
		if t <> nil then
		begin
			write_node(t^.left, f, n, m, smtr_flag, i, j);
		
			while (i < t^.row) do
			begin
				if (j = m) then
				begin
					j := 0; i := i + 1;
					writeln(f);
				end
				else begin
					write(f, 0.0, ' ');
					j := j + 1;
				end;
			end;

			while (j < t^.column - 1) do
			begin
				write(f, 0.0, ' ');
				j := j + 1;
			end;

			write(f, t^.element:4:4, ' ');
			j := j + 1;

			write_node(t^.right, f, n, m, smtr_flag, i, j);
		end;
	end;
var i, j: integer;
begin
	i := 1; j := 0;
	write_node(t, f, n, m, smtr_flag, i, j);
	(* рассматриваем случай, когда последний элемент находится не в позиции (n, m) *)
	
	while (i <= n) do
	begin
		if (j = m) then
		begin
			j := 0; i := i + 1;
			writeln(f);
		end
		else begin
			write(f, 0, ' ');
			j := j + 1;
			// writeln(i, ' ', j);
		end;
	end;
end;

begin
end.