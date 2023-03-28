program matrix_editor;

uses matrix, index, sysutils;

(* редактор матрицы, изменяем значение i, j элемента в матрице
изменяем dot файл, smtr/dmtr файл *)

procedure Matrix_editor(name_matrix: string; mode: string; i,j: integer; val: real);
	(* процедура перестройки дерева *) 
	procedure tree_rebuild(i,j: integer; val: real; t: tree);
	var p: tree;
	begin
		if t <> nil then
		begin
			if (t^.row = i) and (t^.column = j) then
				t^.element := val
			else if (t^.row < i) or ((t^.row = i) and (t^.column < j)) then
			begin
				if t^.right = nil then
				begin
					new(p); 
					p^.row := i; 
					p^.column := j; 
					p^.element := val;
					p^.left := nil; p^.right := nil;
					t^.right := p;
				end
				else 
					tree_rebuild(i,j,val,t^.right)
			end
			else if (t^.row > i) or ((t^.row = i) and (t^.column > j)) then
			begin
				if t^.left = nil then
				begin
					new(p); 
					p^.row := i;
					p^.column := j; 
					p^.element := val;
					p^.left := nil; p^.right := nil;
					t^.left := p;
				end
				else
					tree_rebuild(i,j,val,t^.left)
			end;
		end;
	end;

	(* перестройка индексов узлов в дереве *)
	procedure node_number_rebuild(var n: longword; t: tree);
	begin
		if (t <> nil) then
		begin
			t^.node_number := n;
			n := n + 1;
			node_number_rebuild(n, t^.left);
			node_number_rebuild(n, t^.right);
		end;
	end;

	procedure print_tree(p: tree);
	begin
		if p <> nil then
		begin
			write('|', p^.node_number, ' ', p^.row, ' ', p^.column, ' ', p^.element:3:2, '|  ');
			print_tree(p^.left);
			print_tree(p^.right);
		end;
	end;

var dot_f, matrix_f: text; k: longword;
	dmtr_flag, smtr_flag: boolean; 
	d: data; t: tree;
begin
	(* проверка если индекса нет, то нужно создать *)
	if not check_index(name_matrix) then
	begin
		writeln('error, in index-file of the matrix (',name_matrix,') is impossible to construct');
		Exit
	end;

	d := Dot_parser(name_matrix);
	t := d.t;

	assign(dot_f, name_matrix+'.dot');
	reset(dot_f);

	assign(matrix_f, name_matrix+'.'+mode);

	rewrite(dot_f); 
	rewrite(matrix_f);
	(* изменяем граф через функцию tree_rebuild *)
	k := 1;

	tree_rebuild(i, j, val, t);
	node_number_rebuild(k, t);

	// (* строим заново файл dot по этому переделанному дереву *)
	write_in_dot_file(t, d.n, d.m, dot_f);

	// (* строим заново файл .dmtr или .smtr по переделанному дереву *)
	dmtr_flag := true; smtr_flag := true;

	if mode = 'dmtr' then
	begin
		write_in_dmtr_file(t, matrix_f, d.n,d.m, dmtr_flag);
	end;
	if mode = 'smtr' then
		write_in_smtr_file(t, matrix_f, d.n, d.m, smtr_flag);

	free_tree(t);
	close(matrix_f);
end;

var name_matrix, mode: string; 
	i,j: integer; val: reals; 

begin
	if (paramCount() <> 5) then
		writeln('program parameters not found')
	else 
	begin
		name_matrix := paramStr(1); mode := paramStr(2);
		i := StrToInt(paramStr(3)); j := StrToInt(paramStr(4));
		val := StrToFloat(paramStr(5)); 

		Matrix_editor(name_matrix, mode, i,j, val);
	end;
end.
