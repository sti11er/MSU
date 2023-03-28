program build_index;

Uses SysUtils, matrix, index;

(* 
программа - построитель индекса, строит индекс по имени матрицв (fname) и ее режиму (smtr) *)

procedure Build_index(fname: string; mode: string);
	procedure print_tree(p: tree);
	begin
		if p <> nil then
		begin
			write('|', p^.node_number, ' ', p^.row, ' ', p^.column, ' ', p^.element:3:2, '|  ');
			print_tree(p^.left);
			print_tree(p^.right);
		end;
	end;

var f1, f2: text;
	tmp_matrix: tmp_type;
	t: tree;
	number, i: longword;
	n, m: integer;
begin
	if (mode <> 'smtr') and (mode <> 'dmtr') then
	begin
		writeln('Error, mode (',mode,') not found');
		Exit;
	end;

	assign(f1, fname+'.'+mode); 
	{$I-}
	reset(f1);
	{$I+}

	if IOresult <> 0 then 
	begin
		writeln('Error, file (', fname+'.'+mode, ') not found');
		Exit;
	end;

	assign(f2, fname+'.dot');
	reset(f1); rewrite(f2);

	if mode = 'dmtr' then
		dmtr_parser(f1, tmp_matrix, n, m)
	else if mode = 'smtr' then
		smtr_parser(f1, tmp_matrix, n, m);

	(* build graph *)
	number := 1;

	build_tree(tmp_matrix, number, t);

	(* write in index file  *)
	write_in_dot_file(t, n, m, f2);

	(* dot -Tpdf -o result.pdf matrix.dot *)
	(* work in graph
		... *)

	SetLength(tmp_matrix, 0);
	free_tree(t);
	close(f1);
end;

var fname: string; mode: string;
begin
	if (paramCount() <> 2) then
		writeln('program parameters not found')
	else 
	begin
		fname := paramStr(1); mode := paramStr(2); 
		Build_index(fname, mode);
	end;
end.
