program multiplier;

uses index, matrix, sysutils;

(* 
функция перемножитель, перемножает список матриц, на вход принимает eps все числа меньшие которого зануляются
format (smtr/dmtr) конечной матрицы. fname имя конечной матрицы и список matrixs из имен 
перемножаемых матриц *)

procedure Multiplier(eps: real; format, fname: string; matrixs: array of string);
	(* процедура печати дерева p *)
	procedure print_tree(p: tree);
	begin
		if p <> nil then
		begin
			write('|', p^.node_number, ' ', p^.row, ' ', p^.column, ' ', p^.element:3:3, '|  ');
			print_tree(p^.left);
			print_tree(p^.right);
		end;
	end;

	(* соритировка пузырьком *)
	procedure bubble_sort(var arr: tmp_type);
	var fg: boolean; i: longword; tmp: vec;
	begin
		if length(arr) > 1 then
		begin
			i := 0;
			fg := false;
			while true do
			begin
				if (i + 1) >= length(arr) then
				begin
					if fg = false then
						break;
					
					fg := false;
					i := 0;
				end;

				if (arr[i].i > arr[i+1].i) or ((arr[i].i = arr[i+1].i) and (arr[i].j > arr[i+1].j)) then
				begin
					tmp := arr[i]; 
					arr[i] := arr[i+1];
					arr[i+1] := tmp;
					fg := true
 				end;

 				i := i + 1;
			end;
		end;
	end;


	(* процедура удаляющая все элементы из массива arr, 
		которые больше или равны eps *)
	procedure check_on_eps(var arr: tmp_type);
	var i, j: longword; tmp: tmp_type;
	begin
		tmp := arr;
		SetLength(arr, 0);
		j := 0;
		if length(tmp) <> 0 then
			for i:=0 to length(tmp)-1 do
			begin
				if abs(tmp[i].val) >= eps then
				begin
					SetLength(arr, j+1);
					arr[j].val := tmp[i].val;
					arr[j].i := tmp[i].i; 
					arr[j].j := tmp[i].j;
					j := j + 1;
				end; 
			end;
	end;

	(* рекурсивная процедура перемножающая два дерева m1 и m2 
	   arr - массив, хранящий основные данные матрицы, 
	   нужный для создания дерева, которое является произведением деревьев m1 и m2 файла *)

	function multiply(m1, m2: tree; var arr: tmp_type): tree;
		(* процедура ищущая и добавляющая все произведения элемета с определенными
				i, j, val из дерева m1 и элемета из стб из дерева m2 *)
		procedure additional_func(i, j: integer; element: real; m: tree);
		var k, l: longword; flag: boolean;
		begin
			if m <> nil then
			begin
				if (m^.row = j) then
				begin
					flag := false;
					(* проверка что такой записи еще нету *)
					if length(arr) <> 0 then
					begin
						for k:=0 to length(arr)-1 do
						begin
							if (arr[k].i = i) and (arr[k].j = m^.column) then
							begin
								arr[k].val += element * m^.element;
								flag := true;
								break;
							end;
						end;
					end;

					if not flag then
					begin
						l := length(arr);
						SetLength(arr, l+1);
						arr[l].val := element * m^.element;
						arr[l].i := i;
						arr[l].j := m^.column;

					end;

					additional_func(i, j, element, m^.left);
					additional_func(i, j, element, m^.right);
				end
				else
				begin
					if (m^.row > j) then
						additional_func(i, j, element, m^.left)
					else 
						additional_func(i, j, element, m^.right);
				end;
			end;
		end;
	begin
		if m1 <> nil then
		begin
			multiply(m1^.left, m2, arr);
			additional_func(m1^.row, m1^.column, m1^.element, m2);
			multiply(m1^.right, m2, arr);
		end;
	end;

var number: longword; i,j: integer; res, cur_matrix: data; arr: tmp_type;
	dot_f, matrix_f: text; dmtr_flag, smtr_flag: boolean;
begin
	(* получить из индекс-файлов деревья *)
	if length(matrixs) <> 0 then
	begin
		if check_index(matrixs[0]) then
		begin
			res := Dot_parser(matrixs[0]);
		end
		else 
		begin
			writeln('error, in index-file of the matrix (',matrixs[0],') is impossible to construct');
			Exit
		end;

		for i:=1 to length(matrixs)-1 do
		begin
			if check_index(matrixs[i]) then
				cur_matrix := Dot_parser(matrixs[i])
			else 
			begin
				writeln('error, in index-file of the matrix (',matrixs[i],') is impossible to construct');
				Exit
			end;

			if res.m <> cur_matrix.n then
			begin
				writeln('error, incorrect dimensions ', res.n, ' ', cur_matrix.n);
			 	Exit;
			end;
			(* перемножить деревья и получить тем самым получив новое дерево *)
			multiply(res.t, cur_matrix.t, arr);

			res.n := res.m;
			res.m := cur_matrix.n;

			check_on_eps(arr);
			(* отсоритрум arr *)
			bubble_sort(arr);

			number := 1;
			free_tree(cur_matrix.t); free_tree(res.t);
			build_tree(arr, number, res.t);
			SetLength(arr, 0);
		end;

		assign(dot_f, fname+'.dot');
		rewrite(dot_f);

		(* создать файл нужого формата и индекс-файл *)

		write_in_dot_file(res.t, res.n, res.m, dot_f);

		assign(matrix_f, fname+'.'+format);
		rewrite(matrix_f);

		(* записываем в файл smtr/dmtr *)
		dmtr_flag := true; smtr_flag := true;

		if format = 'dmtr' then
			write_in_dmtr_file(res.t, matrix_f, res.n, res.m, dmtr_flag);
		if format = 'smtr' then
			write_in_smtr_file(res.t, matrix_f, res.n, res.m, smtr_flag);

		free_tree(res.t);
		close(matrix_f);
	end
	else 
	begin
		writeln('ERROR, no multiplicative matrices!');
		Exit;
	end;
end;

var eps: real; 
	format, fname: string;
	matrixs: array of string;
	i: integer;
begin
	if (paramCount() < 4) then
		writeln('program parameters not found')
	else 
	begin
		eps := StrToFloat(paramStr(1));
		format := paramStr(2); fname := paramStr(3);
		SetLength(matrixs, paramCount()-3);

		for i:=4 to paramCount() do
			matrixs[i-4] := paramStr(i);

		Multiplier(eps, format, fname, matrixs);
		SetLength(matrixs, 0);
	end;
end.
