program generator;

Uses SysUtils;

(* 
генератор матрицы, в аргументах программы должны быть заданы размерность матрицы n, m 
режим генерации 1, 2, 3 из условия задачи, format (smtr/dmtr), eps разряженность, число от 0 до 1
flag - флаг печати в консоль (1,0) fname имя сохр матрицы *)

procedure Generation(m, n, mode: integer; format:string; eps: real; flag: integer; fname: string);
var x, a: real;
	i, j: integer;
	f: text;
	int_frac: integer;
	mantis: real;
	sgn: integer;
begin
	if (eps < 0) or (eps > 1) then
	begin
		writeln('error, incorrect eps');
		Exit;
	end;
	randomize;
	(* объявлем название файла, и передаем дискриптор *)
	case format of
		'dmtr': 
		begin
			assign(f, fname+'.dmtr');
			rewrite(f);

			writeln(f, 'sparse_matrix ', m, ' ', n);
			writeln(f);

			for i:=1 to m do
			begin
				for j:=1 to n do
				begin
					x := random(100) + 1;
					if x <= (eps*100) then 
					begin
						a := 0.0;
						if (mode = 1) then a := 1.0;
						if (mode = 2) then 
						begin 
							int_frac := random(100000);
							mantis := random();
							sgn := random(1);
							if sgn = 0 then sgn := -1;
							a := (int_frac + mantis) * sgn;
						end;
						if (mode = 3) and (i=j) then a := 1.0;

						if flag = 1 then write(a:4:4, ' ');
						if a <> 0 then writeln(f, i,' ', j,' ',' ',a:4:4);
					end
					else if flag = 1 then write(0.0:4:4, ' '); 
				end;
				if flag = 1 then writeln();
			end;
		end;
		'smtr':
		begin 
			assign(f, fname+'.smtr');
			rewrite(f);

			writeln(f, 'dence_matrix ', m, ' ', n);
			writeln(f);

			for i:=1 to m do
			begin
				for j:=1 to n do
				begin
					x := random(100)+1;
					a := 0.0;
					if x <= (eps*100) then 
					begin
						if (mode = 1) then a := 1.0;
						if (mode = 2) then
						begin 
							int_frac := random(100000);
							mantis := random();
							sgn := random(1);
							if sgn = 0 then sgn := -1;
							a := (int_frac + mantis) * sgn;
						end;
						if (mode = 3) and (i=j) then a := 1.0;
					end;
					if flag = 1 then write(a:4:4, ' ');
					write(f, a:4:4, ' ');
				end;
				if flag = 1 then writeln();
				writeln(f);
			end;

			writeln(f);
		end;
	end;

	close(f);
end;

var m, n, mode: integer; 
	format, fname:string; 
	eps: real; 
	flag: integer;
begin
	if (paramCount() <> 7) then
		writeln('program parameters not found')
	else 
	begin
		m := StrToInt(paramStr(1)); n := StrToInt(paramStr(2)); mode := StrToInt(paramStr(3));
		format := paramStr(4); fname := paramStr(7);
		eps := StrToFloat(paramStr(5)); 
		flag := StrToInt(paramStr(6));
		Generation(m,n,mode,format,eps,flag,fname);
	end;
end.
