program index_mapping;

Uses SysUtils, index;

(* 
программа, которая распечатывает индекс файл в 2 режимах передоваемых как параметр 
mode 1-корень, левое поддерево, правое поддерово 2-по уровням от корня к листьям *)

procedure Index_mapping(mode: integer; index_file: string);
	procedure first_print_mode(t: tree);
	begin
		if t <> nil then
		begin
			write('|', t^.node_number, ' ', t^.row, ' ', t^.column, ' ', t^.element:3:2, '| ');
			first_print_mode(t^.left);
			first_print_mode(t^.right);
		end;
	end;

	procedure second_print_mode(n: integer; t: tree);
	begin
		if t <> nil then
		begin
			if n = 0 then 
				write('|', t^.node_number, ' ', t^.row, ' ', t^.column, ' ', t^.element:3:2, '|	')
			else
			begin
				second_print_mode(n-1, t^.left);
				second_print_mode(n-1, t^.right)
			end;
		end;
	end;
	function get_deep(t: tree): integer;
	begin
		if t = nil then
		begin
			get_deep := 0;
		end
		else
		begin
			if get_deep(t^.left) > get_deep(t^.right) then
				get_deep := 1 + get_deep(t^.left)
			else
				get_deep := 1 + get_deep(t^.right)
		end;
	end;

var i, deep: integer;
	t: tree;
	d: data;
	f: text;

begin
	if (mode <> 1) and (mode <> 2) then
    begin
        writeln('Error, mode (',mode,') not found');
        Exit;
	end;

    assign(f, index_file+'.dot');
    {$I-}
    reset(f);

    {$I+}

    if IOresult <> 0 then
    begin
        writeln('Error, file (', index_file+'.dot', ') not found');
        Exit;
    end;	
	close(f);

	d := Dot_parser(index_file);
	t := d.t; 
	deep := get_deep(t);
	case mode of
		1: 
		begin
			first_print_mode(t);
			writeln();
		end;
		2: 
			for i:=0 to deep-1 do
			begin
				second_print_mode(i, t); 
				writeln();
			end;
	end;	
	free_tree(t);
end;

var mode: integer; index_file: string;
begin
	if (paramCount() <> 2) then
		writeln('program parameters not found')
	else 
	begin
		mode := StrToInt(paramStr(1)); index_file := paramStr(2); 
		Index_mapping(mode, index_file);
	end;
end.
