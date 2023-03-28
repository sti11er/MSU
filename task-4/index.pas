unit index;

interface 

Uses SysUtils, Math, Dos;

type
	tree = ^tree_node_t;
	tree_node_t = record
		node_number: longword;
		row,column: longword;
		element: double;
		left, right: tree;
	end;
	states = (dim, row, column, val, comment, save_data, input_node, output_node, direction);
	vec = record
			i: longword;
			j: longword;
			val: real;
		end;
	tmp_type = array of vec;
	data = record 
			t: tree;
			n, m: integer;
		end;

function Dot_parser(fname: string): data;
procedure build_tree(arr: tmp_type; var number: longword; var p: tree);
procedure write_in_dot_file(p: tree; n,m: integer; var f: text);
function check_index(matrix: string): boolean;
procedure free_tree(var t: tree);

implementation


(* функция для парсинга данных их файла index 
принимает имя индекс-файла возвращает, сформированное из 
данных файла, дерево  *)

function Dot_parser(fname: string): data;
	
var i, k, q, tmp: integer;
	index, l, cur_row, cur_column, number_in_node, number_to_node: longword;
	f: text; flag_data: boolean;
	el: char; 
	flag_I_node, flag_O_node, flag_row, 
	flag_column, flag_val, flag_comment, flag_point, flag_root: boolean;
	cur_val: real;
	state: states;
	tmp_matrix: tmp_type;
	t, p, root: tree; 
	paths: array of string;
	comment_text: string;
	n_flag, m_flag: boolean;
	res: data;
	n, m: integer;

begin
	assign(f, fname+'.dot');
	reset(f);

	readln(f); 
	readln(f);

	n := 0; m := 0;
	n_flag := false; m_flag := false;
	comment_text := '';
	state := comment;
	index := 0;
	cur_row := 0; cur_column:= 0; cur_val := 0.0;
	flag_row := false; flag_row := false; flag_val := false;
	flag_point := false; flag_data := false; flag_comment := false;
	flag_I_node := false; flag_O_node := false;
	number_in_node := 0; number_to_node := 0; 
	flag_root := true;
	SetLength(tmp_matrix, 0);
	p := nil; t := nil; root := nil;

	l := 1;
	SetLength(tmp_matrix,l);
	q := 0;
	tmp := 1;
	k := -1;

	(* парсим данные *)
	while not eof(f) do
	begin

		if not eoln(f) then
		begin
			read(f, el);
			case state of
				comment:
					begin
						// writeln(n_flag, ' ', m_flag, ' ', n, ' ', m);
						if el = '/' then 
						begin
							flag_comment := true;
						end		
						else if flag_comment and (el >= '0') and (el <= '9') then
						begin
							if n_flag then
								n := 10*n + StrToInt(el);
							if m_flag then
								m := 10*m + StrToInt(el);
						end
						else if flag_comment and (length(comment_text)<>0) and ((ord(el) = 32) or (ord(el) = 9)) then
						begin
							if n_flag then
							begin
								n_flag := false;
								m_flag := true;
							end
							else if m_flag then
							begin
								m_flag := false;
								flag_comment := false;
								state := row;
								flag_data := true;
								comment_text := '';
							end
							else if comment_text = 'dim' then
							begin
								n_flag := true;
							end
							else if comment_text = 'edges' then
							begin
								comment_text := '';
								flag_comment := false;
								flag_data := false;
								state := input_node;
								SetLength(paths, length(tmp_matrix));
								for i:=0 to length(paths)-1 do
									paths[i] := '';
							end
							else 
							begin
								comment_text := '';
								flag_comment := false;

								if flag_data then state := row
								else state := input_node;

								readln(f);
							end
						end
						else if flag_comment and ((ord(el) <> 32) and (ord(el) <> 9)) then
						begin
							comment_text += el;
						end;
						// else 
						// begin
						// 	writeln(el);
						// 	writeln('error, incorect data');
						// 	Exit;
						// end;			
					end;
				(* парсинг соединений *)
				input_node:
					if not flag_data then
					begin
						if (el >= '0') and (el <= '9') then
						begin
							number_in_node := 10*number_in_node + StrToInt(el);
							flag_I_node := true;
						end
						else if flag_I_node and ((ord(el) = 32) or (ord(el) = 9)) then
						begin
							state := output_node;
							flag_I_node := false;
						end
						else if (el = '/') and (flag_I_node=false) then
						begin
							state := comment;
							flag_I_node := false;
						end;
					end;
				output_node:
					if not flag_data then
					begin
						if (el >= '0') and (el <= '9') then
						begin
							number_to_node := 10*number_to_node + StrToInt(el);
							flag_O_node := true;
						end
						else if flag_O_node and ((ord(el) = 32) or (ord(el) = 9)) then
						begin
							state := direction;
							flag_O_node := false;
						end;
					end;
				direction:
					if not flag_data then
					begin
						if (el = 'L') or (el = 'R') then
						begin
							// writeln(tmp_matrix[number_in_node-1].i, ' ', tmp_matrix[number_in_node-1].j, ' ', tmp_matrix[number_in_node-1].val:3:3);
							// writeln(tmp_matrix[number_to_node-1].i, ' ', tmp_matrix[number_to_node-1].j, ' ', tmp_matrix[number_to_node-1].val:3:3);
							// writeln();

							if flag_root then
							begin
								new(t);
								root := t;
								t^.node_number := number_in_node;
								t^.element := tmp_matrix[number_in_node-1].val;
								t^.row := tmp_matrix[number_in_node-1].i;
								t^.column := tmp_matrix[number_in_node-1].j;
								t^.left := nil; t^.right := nil;
								flag_root := false;
							end;
							
							new(p);
							p^.node_number := number_to_node;
							p^.element := tmp_matrix[number_to_node-1].val;
							p^.row := tmp_matrix[number_to_node-1].i;
							p^.column := tmp_matrix[number_to_node-1].j;
							p^.left := nil; p^.right := nil;

							t := root;
							paths[number_to_node-1] := paths[number_in_node-1] + el;
							
							
							for i:=1 to length(paths[number_in_node-1]) do
							begin
								if paths[number_in_node-1][i] = 'L' then
									t := t^.left
								else
									t := t^.right;
							end;

							// writeln();
							if el = 'L' then t^.left := p;
							if el = 'R' then t^.right := p;

							p := nil; t := nil;
							number_in_node := 0; number_to_node := 0;
							state := input_node;
						end;
					end;
				(* парсинг данных об узлах *)
				row:
					if flag_data then
					begin
						// write(el);
						if el = '"' then
						begin
							flag_row := true;
						end
						else if flag_row then
						begin
							if ((ord(el) = 32) or (ord(el) = 9)) then
							begin
								state := column;
								flag_row := false;
							end
							else
								cur_row := 10*cur_row + StrToInt(el);
						end 
						else if (el = '/') and (flag_row = false) then
						begin
							state := comment;
							flag_I_node := false;
						end;
					end;
				column: 
					if flag_data then
					begin
						if (el >= '0') and (el <= '9') then
						begin
							cur_column := 10*cur_column + StrToInt(el);
							flag_column := true;
						end
						else if flag_column and (el = '\') then
						begin
							state := val;
							flag_column := false;
						end;
					end;
				val: 
					if flag_data then
					begin
					    // write(cur_val:3:3, ' ');
						if (el = '-') then
							tmp := -1
						else if (el >= '0') and (el <= '9') then
						begin
							if not flag_point then
							begin
								cur_val := (10*cur_val + StrToInt(el));
							end
							else
							begin
								cur_val := StrToInt(el)*Power(10, k) + (cur_val);
								k := k - 1;
							end;
							flag_val := true;
						end
						else if el = '.' then
						begin
							flag_point := true;
						end
						else if flag_val and (el = '"') then
						begin
							cur_val *= tmp;
							if (index = l) then
							begin
								l *= 2;
								SetLength(tmp_matrix, l);
							end;

							tmp_matrix[index].i := cur_row; 
							tmp_matrix[index].j := cur_column;
							tmp_matrix[index].val := cur_val;

	 						state := row;
							flag_val := false;
							flag_point := false;
							cur_row := 0; cur_column:= 0; cur_val := 0.0;
							k := -1;
							tmp := 1;
							index := index + 1;
						end;
					end;
			end;
		end
		else
		begin 
			readln(f);
		end;
	end;

	res.t := root;
	res.n := n; res.m := m;
	Dot_parser := res;
	SetLength(tmp_matrix, 0);
	SetLength(paths, 0);
	close(f);
end;

(* build_tree процедура создающая дерево, по переданному в виде параметра 
массиву arr, в котором хранятся данные матрицы представленные в виде массива
рекордов, number переменная нужная для реализации индексирования вершин дерева *)

procedure build_tree(arr: tmp_type; var number: longword; var p: tree);
var k, q, j: word; left_arr: tmp_type; right_arr: tmp_type;
begin
	// writeln(length(arr));
	if length(arr) = 0 then 
		p := nil
	else
	begin
		
		new(p);
		p^.node_number := number;
		number := number + 1;
		k := length(arr) div 2;

		// writeln(arr[k].i, ' ', arr[k].j);
		if arr[k].i = 0 then Exit;

		p^.row := arr[k].i; p^.column := arr[k].j;
		p^.element := arr[k].val;

		// writeln('-> ', p^.row, ' ', p^.column, ' ', p^.element:3:2);
		SetLength(left_arr, k);
		
		if k <> 0 then
		begin
			for q:=0 to k-1 do
			begin
				left_arr[q] := arr[q];
			end;
		end;

		build_tree(left_arr, number, p^.left);

		SetLength(right_arr, length(arr)-k-1);
		j := 0;
		for q:=k+1 to length(arr)-1 do
		begin
			if j >= length(right_arr) then 
			begin
				writeln('ERROR');
				Exit;
			end;
			right_arr[j] := arr[q];
			j := j + 1;
		end;

		build_tree(right_arr, number, p^.right);
	end;
end;

(* процедура формирующая файл dot по переданному в виде аргумента, дереву p *)

procedure write_in_dot_file(p: tree; n,m: integer; var f: text);

	(* внутренняя процедура, процедуры write_in_dot_file, нужна для рекурсивного прохода 
		по дереву p, и записи смежностей в файл dot *)
	procedure write_adjacency(p: tree; var f: text);
	begin
		if p <> nil then
		begin
			if (p^.left <> nil) then
				writeln(f, '	',p^.node_number, ' -> ', p^.left^.node_number, ' [label="L"];');
			if (p^.right <> nil) then
				writeln(f, '	',p^.node_number, ' -> ', p^.right^.node_number, ' [label="R"];');

			write_adjacency(p^.left, f);
			write_adjacency(p^.right, f);
		end;
	end;

	(* внутренняя процедура, процедуры write_in_dot_file, нужна для рекурсивного прохода 
		по дереву p, и записи его вершин в файл dot *)
	procedure write_nodes(p: tree; var f: text);
	var row, column: integer; val: real;
	begin
		if p <> nil then
		begin
			row := p^.row; column := p^.column; val := p^.element;

			writeln(f, '	',p^.node_number,'  [ label="',row,' ',column,'\n',val:3:3,'"];');
			write_nodes(p^.left, f);
			write_nodes(p^.right, f);
		end;
	end;
begin
	rewrite(f);
	writeln(f, 'digraph');
	writeln(f, '{');
	writeln(f);

	(* размерность матрицы *)
	writeln(f, '	// dim ', n, ' ', m);
	writeln(f);
	write_nodes(p, f);
	writeln(f);

	writeln(f, '	// edges');
	writeln(f);

	write_adjacency(p, f);

	writeln(f, '}');
	close(f);
end;

(* 
функция проверяющая существует ли индекс для данной матрицы, 
если нет то она строит его по файлу smtr/dmtr, выдает true
в случае, если файл существует или мы его построили, и false
если файл нельзя построить *)
function check_index(matrix: string): boolean;
var f: text;
begin
	check_index := true;

	(* это значит, что dot файла не существует
	посмотрим, можно ли его создать *)

	if not FileExists(matrix+'.dot') then
	begin
		(* посмотрим, можно ли создать индекс файл из smtr файла матрицы *)
		if not FileExists(matrix+'.smtr') then
		begin
			(* посмотрим, можно ли создать индекс файл из dmtr файла матрицы *)
			(* увы, мы нам не из чего создавать индекс-файл *)
			if not FileExists(matrix+'.dmtr') then
			begin
				check_index := false;
			end
			else
			begin
				(* создаем индекс-файл *)
				SwapVectors;
				Exec('build_index', matrix + ' dmtr');
				SwapVectors;
				if DosError <> 0 then 
					writeln('error', DosError);
			end;
		end
		else
		begin
			(* создаем индекс-файл *)
			SwapVectors;
			Exec('build_index', matrix + ' smtr');
			SwapVectors;
			if DosError <> 0 then
				writeln('error, ', DosError);
			
		end;
	end;
end;

(* процедура очистки дерева *)
procedure free_tree(var t: tree);
begin
	if t <> nil then
	begin
		free_tree(t^.left);
		free_tree(t^.right);
		dispose(t);
		t := nil;
	end;
end;

begin
end.
