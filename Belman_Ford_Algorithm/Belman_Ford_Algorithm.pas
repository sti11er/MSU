program Belman_Ford_Algorithm;

Uses sysutils,
	{$IFDEF UNIX}{$IFDEF UseCThreads}
	cthreads,
	{$ENDIF}{$ENDIF}
	Classes;

(* ASCII number values  *)
(* 
32 - blank
13 - Tab
10 - line feed
9 - carriage return  
26 - substitution 
*)

const 
	BLANK = 32;
	TAB = 13;
	LINE_FEED = 10;
	CARRIAGE_RETIRN = 9;
	SUBSTITUTION = 26;
	FIGURES = '0123456789';

type DynStrArray = array of string;
type DynIntArray = array of integer;
type DynIntMatrix = array of DynIntArray;
 
type to_city = record
	index_to_city: integer;
	weight: array[1..3] of integer;
	end;

type arr_to_cites = array of to_city;
type arr_from_to_cites = array of arr_to_cites;

type end_cites = record 
	name_end_city: string;
	i: array of integer;
	j: array of integer;
	end;

type arr_end_cites = array of end_cites;

type transport = record 
	name_transport: string;
	from_cites: DynStrArray;
	to_cites: arr_from_to_cites;
	end_cites: arr_end_cites;
	end;

type Tgraph = array of transport;
type Arr = array [1..5] of string;

type node_data = record
	min_dist: real;
	prev_node: array of integer;
	end;

type arr_node_data = array of node_data;

var error_log: string; graph: Tgraph;
	i, x, y, j: integer;
	states: array[1..5] of string = ('from city','to city','transport type','cruise time','cruise fare');
	flag_session, flag_parser: boolean;
	input_file: text;
	search_mode, transport_type: integer;
	limit_cost, limit_time: integer;
	index_trans, index_to_city: integer;
	dist: arr_node_data;
	tmp: array of integer;
	paths: DynIntMatrix;
	cites: DynIntArray;
	curr_from_city, curr_to_city: string;


const Infinity = 1.0 / 0.0;


procedure delete(index: integer; var arr: arr_end_cites);
var i: integer;
begin
	if length(arr) <= 1 then SetLength(arr, 0)
	else 
	begin
		for i:=index to length(arr)-1 do
		begin
			arr[i] := arr[i+1];
		end;
		SetLength(arr, length(arr)-1);
	end;
end;

procedure deleteInt(index: integer; var arr: DynIntArray);
var i: integer;
begin
	if length(arr) <= 1 then SetLength(arr, 0)
	else 
	begin
		for i:=index to length(arr)-1 do
		begin
			arr[i] := arr[i+1];
		end;
		SetLength(arr, length(arr)-1);
	end;
end;

(* function that counts the number of identical elements *)
function counter(item: string; arr: array of string): integer;
var i: integer; res: integer;
begin
	res := 0;
	for i := 0 to length(arr)-1 do 
	begin
		if item = arr[i] then 
			res += 1;
	end;
	counter := res;
end;


(* function for checks that char is in string, return boolean *)
function char_in_string(ch: char; str: string): boolean;
var i: integer; res: boolean;
begin
	res := false;
	for i := 1 to length(str) do 
	begin
		if ch = str[i] then 
			res := true;
	end;
	char_in_string := res;
end;

function int_in_arr(el: integer; arr: DynIntArray): boolean;
var i: integer; res: boolean;
begin
	res := false;
	for i := 0 to length(arr)-1 do 
	begin
		if el = arr[i] then 
			res := true;
	end;
	int_in_arr := res;
end;

(* adding unique values to the array *)
procedure uappend(val: string; var arr: DynStrArray);
var l: integer;
begin
	(* checking an arr for uniqueness *)
	if counter(val, arr) = 0 then  
	begin
		l := length(arr);
		SetLength(arr, l+1);
		arr[l] := val;
	end;
end;

(* Finding an find_index element in a dynamic str array *)
function find_index(val: string; var arr: DynStrArray): integer;
var i: integer;
begin
	find_index := -1;
	i := 0;

	while (i < length(arr)) do
	begin
		if arr[i] = val then
		begin
			find_index := i;
			break;
		end;
		i += 1;
	end;
end;

procedure add_end_city(route_info: Arr; var to_cites: arr_to_cites);
var len: integer;
begin
	len := length(to_cites);
	SetLength(to_cites, len+1);
	to_cites[len].index_to_city := StrToInt(route_info[2]);
	to_cites[len].weight[1] := StrToInt(route_info[4]);
	to_cites[len].weight[2] := StrToInt(route_info[5]);
	to_cites[len].weight[3] := 1;
end;

procedure add_to_city(route_info: Arr; var from_cites: DynStrArray; 
					var to_cites: arr_to_cites; var end_cites: arr_end_cites);

var len_to_city, len_end_cites, len, tmp1, tmp2: integer;
begin
	len_to_city := length(to_cites);
	SetLength(to_cites, len_to_city+1);

	tmp1 := find_index(route_info[2], from_cites);
	if tmp1 = -1 then 
	begin
		len_end_cites := length(end_cites);
		tmp2 := -1;
	
		for i:=0 to len_end_cites-1 do 
		begin
			if end_cites[i].name_end_city = route_info[2] then
			begin
				tmp2 := i;
				break
			end;
		end;

		if tmp2 = -1 then
		begin
			SetLength(end_cites, len_end_cites+1);		
			end_cites[len_end_cites].name_end_city := route_info[2];
			SetLength(end_cites[len_end_cites].i, 1);
			SetLength(end_cites[len_end_cites].j, 1);
			end_cites[len_end_cites].i[0] := find_index(route_info[1], from_cites);
			end_cites[len_end_cites].j[0] := len_to_city;
		end
		else
		begin 
			len := length(end_cites[tmp2].i); 
			SetLength(end_cites[tmp2].i, len+1);
			SetLength(end_cites[tmp2].j, len+1);
			end_cites[tmp2].i[len] := find_index(route_info[1], from_cites);
			end_cites[tmp2].j[len] := len_to_city;
		end;
	end;
	to_cites[len_to_city].index_to_city := tmp1;
	to_cites[len_to_city].weight[1] := StrToInt(route_info[4]);
	to_cites[len_to_city].weight[2] := StrToInt(route_info[5]);
	to_cites[len_to_city].weight[3] := 1;
end;

procedure add_from_city(route_info: Arr; var from_cites: DynStrArray; 
					var to_cites: arr_from_to_cites; var end_cites: arr_end_cites);

var len_from_city, len_to_city, i, j: integer;
begin
	len_from_city := length(from_cites);
	SetLength(from_cites, len_from_city+1);
	from_cites[len_from_city] := route_info[1];

	i := 0;
	while i < length(end_cites) do
	begin
		if end_cites[i].name_end_city = route_info[1] then
		begin
			for j:=0 to length(end_cites[i].i)-1 do 
				to_cites[end_cites[i].i[j]][end_cites[i].j[j]].index_to_city := len_from_city;
			delete(i, end_cites);
			break
		end
		else i += 1;
	end;

	len_to_city := length(to_cites);
	SetLength(to_cites, len_to_city+1);
	add_to_city(route_info, from_cites, to_cites[len_to_city], end_cites);
end;

procedure add_transport(route_info: Arr);
var len: integer;
begin
	len := length(graph);
	SetLength(graph, len+1);
	graph[len].name_transport := route_info[3];
	add_from_city(route_info, graph[len].from_cites, graph[len].to_cites, graph[len].end_cites);
end;

procedure fill_end_cites();
var i, j, x, y, len, k: integer;
begin
	for i:=0 to length(graph)-1 do
	begin
		len := length(graph[i].from_cites);
		for j:=0 to length(graph[i].end_cites)-1 do 
		begin
			for k:=0 to length(graph[i].end_cites[j].i)-1 do 
			begin
				x := graph[i].end_cites[j].i[k];
				y := graph[i].end_cites[j].j[k];
				graph[i].to_cites[x][y].index_to_city := len+j;
			end;
		end;
	end;
end;

procedure print_graph();
var i, x, y, index, len: integer;
begin
	(* print graph *)
	for i:=0 to length(graph)-1 do 
	begin
		writeln(graph[i].name_transport,': ');
		len := length(graph[i].from_cites);
		for x:=0 to len-1 do 
		begin
			writeln('	',graph[i].from_cites[x],': ');
			for y:=0 to length(graph[i].to_cites[x])-1 do 
			begin
				index := graph[i].to_cites[x][y].index_to_city;

				if index < len then write('		',graph[i].from_cites[index],' ')
				else write('		',graph[i].end_cites[index-len].name_end_city,' '); 

				write(graph[i].to_cites[x][y].weight[1],' ');
				write(graph[i].to_cites[x][y].weight[2],' ');
				writeln(graph[i].to_cites[x][y].weight[3]);
			end;
		end;
		writeln('               ');
	end;
end;

// заполнение индексов конечных вершин 
procedure fill_in_graph(route_info: Arr);

var index_trans, index_from_city, i: integer;
begin
	// -1 когда этого транспорта нету
	index_trans := -1; 
	
	for i:=0 to length(graph)-1 do 
	begin
		if graph[i].name_transport = route_info[3] then
		begin
			index_trans := i;
			break
		end;
	end;

	if index_trans = -1 then
		add_transport(route_info)
	else // транспорт есть
	begin
		// -1 когда этого города нету
		index_from_city := find_index(route_info[1], graph[index_trans].from_cites);

		if index_from_city = -1 then
			add_from_city(route_info, graph[index_trans].from_cites, 
				graph[index_trans].to_cites, graph[index_trans].end_cites)
		else
		// если город есть то записываем еще один вариант маршрута прибытия
		begin
			add_to_city(route_info, graph[index_trans].from_cites, 
				graph[index_trans].to_cites[index_from_city], graph[index_trans].end_cites);
		end;
	end;
end;

(* function implements the processing of user file and create graph *)
procedure parser();
var el, prev: char;
	r, k: integer;
	route_info: Arr = ('', '', '', '', '');
	is_read: boolean;
	stop: boolean;
	line_number: integer;
begin
	flag_parser := true;
	is_read := false;

	stop := false;
	r := 1;
	line_number := 1;
	prev := ' ';

	assign(input_file, 'input.txt');
	reset(input_file);

	while flag_parser do 
	begin
		(*  if end line or end file *)
		if eoln(input_file) or eof(input_file) then
		begin
			is_read := false;
			stop := false;
			line_number += 1; 

			if counter('', route_info) = 0 then 
			begin
				fill_in_graph(route_info)
			end
			else if counter('', route_info) <> 5 then
			begin
				error_log := 'error, incomplete data' + ' (' +IntToStr(line_number)+') line number';
				flag_parser := false;
				stop := false;
			end;

			for k := 1 to 5 do 
			begin
				// writeln(route_info[k]);
				route_info[k] := '';
			end;
			r := 1;
		end;  
		(*  if end file *)
		if eof(input_file) then flag_parser := False
		else
		begin
			read(input_file, el);
			if ((r <= 3) and char_in_string(el, FIGURES)) then 
			begin
				error_log := 'error, invalid in ' + states[r] + ' (' +IntToStr(line_number)+') line number';
				flag_parser := false;
				stop := false;
			end;

			if (el = '#') then	
				stop := true;

			if (ord(el) <> TAB) and (ord(el) <> BLANK) 
				and (ord(el) <> LINE_FEED) and (ord(el) <> CARRIAGE_RETIRN) 
				and (stop = false) then
			begin
				if (r > 5) then
				begin
					error_log := 'error, uncommented unnecessary information' + ' (' +IntToStr(line_number)+') line number';
					flag_parser := false;
					stop := false;
				end
				else 
				begin
					if char_in_string(el, FIGURES) or (el = '"') then
						is_read := true
					else if is_read = false then
					begin
						error_log := 'error, invalid in ' + states[r] + ' (' +IntToStr(line_number)+') line number';
						flag_parser := false;
					end;
				end;
			end
			else if is_read and ((prev = '"') or char_in_string(prev, FIGURES)) then
			begin
				r += 1;
				is_read := false;
			end; 

			if is_read and (el <> '"') then route_info[r] += el;
			prev := el;
		end;
	end;

	writeln(error_log);
	close(input_file);
end;

procedure add_index_next_query(index: integer; var arr: DynIntArray);
var i: integer;
	flag: boolean;
begin
	flag := true;
	for i:=0 to length(arr)-1 do
		if index = arr[i] then
		begin
			flag := false;
			break
		end;

	if flag then
	begin
		SetLength(arr, length(arr)+1);
		arr[length(arr)-1] := index;
	end;
end;

function get_index_to_value(val: string; var graph: transport): integer;
var index, i, l1, l2: integer;
begin
	index := -1;
	l1 := length(graph.from_cites);
	l2 := length(graph.end_cites);
	for i:=0 to l1-1 do 
	begin
		if (graph.from_cites[i] = val) then 
		begin
			index := i;
			break
		end;
	end;

	if index = -1 then
		for i:=0 to l2-1 do
		begin
			if (graph.end_cites[i].name_end_city = val) then
			begin
				index := l1+i;
				break
			end;
		end;

	get_index_to_value := index;
end;

function get_value_to_index(index: integer; var graph: transport): string;
var result: string;
	len: integer;
begin
	len := length(graph.from_cites);
	if index < len then result := graph.from_cites[index]
	else result := graph.end_cites[index-length(graph.from_cites)].name_end_city;

	get_value_to_index := result;
end;


procedure path_restoration(to_city: integer; end_cites: integer; var dist: arr_node_data);
var i, len: integer;
begin	
	SetLength(tmp, length(tmp)+1);
	tmp[length(tmp)-1] := to_city;

	if (to_city = end_cites) then
	begin
		len := length(paths);
		SetLength(paths, len+1);
		paths[len] := tmp;
	end
	else
	begin
		for i:=0 to length(dist[to_city].prev_node)-1 do
		begin
			path_restoration(dist[to_city].prev_node[i], end_cites, dist);
		end;
	end;
	SetLength(tmp, length(tmp)-1);
end;

procedure push(var curr_query: DynIntArray; var next_query: DynIntArray);
var tmp: DynIntArray;
	i, l1, l2: integer;
begin
	l1 := length(curr_query);
	l2 := length(next_query);

	tmp := curr_query;
	SetLength(curr_query, l1+l2);

	for i:=0 to l2-1 do 
	begin
		curr_query[i] := next_query[i];
	end;
	for i:=l2 to l2+l1-1 do 
	begin
		curr_query[i] := tmp[i-l2];
	end;
end;

function BFS(src: string; weight_type: integer; var graph: transport): DynIntArray;
var i, index_src, len_to_cites, index_to_city: integer;
	passed_cities: DynIntArray;
	curr_query: DynIntArray;
	next_query: DynIntArray;
	cites: DynIntArray;

begin
	index_src := get_index_to_value(src, graph);

	len_to_cites := length(graph.from_cites)+length(graph.end_cites);
	SetLength(passed_cities, len_to_cites);

	for i:=0 to len_to_cites-1 do 
	begin
		passed_cities[i] := 0;
	end;

	passed_cities[index_src] := 1;

	SetLength(curr_query, length(curr_query)+1);
	curr_query[length(curr_query)-1] := index_src;

	while length(curr_query) <> 0 do
	begin		
		SetLength(next_query, 0);
		for i:=0 to length(curr_query)-1 do
			write(get_value_to_index(curr_query[i], graph), ' ');
		writeln();

		for i:=0 to length(graph.to_cites[curr_query[0]])-1 do 
		begin
			index_to_city := graph.to_cites[curr_query[0]][i].index_to_city; 
			// write(get_value_to_index(index_to_city, graph), ' ', passed_cities[index_to_city], ' ');
			if passed_cities[index_to_city] = 0 then
			begin
				SetLength(next_query, length(next_query)+1);
				next_query[length(next_query)-1] := index_to_city; 
				passed_cities[index_to_city] := 1;
			end;
		end;

		// pop
		deleteInt(0, curr_query);
		push(curr_query, next_query);

		// search
		// for i:=0 to length(curr_query)-1 do 
		// begin
			
		// end;
	end;

	BFS := passed_cities;
end; 


function Belman_Ford_Algorithm(src: string; weight_type: integer; var graph: transport): arr_node_data; 

var i, k, len, index_src, index_to_city, curr_weight, len_prev_node: integer;
	curr_query, next_query: DynIntArray;
	curr_dist: real;
	dist: arr_node_data;

begin
	index_src := find_index(src, graph.from_cites);
	len := length(graph.from_cites) + length(graph.end_cites);

	SetLength(dist, len);

	SetLength(curr_query, len);
	SetLength(next_query, len);

	for i:=0 to len-1 do 
	begin
		dist[i].min_dist := Infinity;
	end;

	if index_src = -1 then
	begin
		error_log := 'error, '+src+' finish node';
	end
	else
	begin
		dist[index_src].min_dist := 0.0;
		SetLength(next_query, 1);
		next_query[0] := index_src;

		while length(next_query) > 0 do 
		begin
			curr_query := Copy(next_query);
			SetLength(next_query, 0);

			while length(curr_query) > 0 do
			begin
				curr_dist := dist[curr_query[0]].min_dist;
				for i:=0 to length(graph.to_cites[curr_query[0]])-1 do
				begin
					index_to_city := graph.to_cites[curr_query[0]][i].index_to_city;
					curr_weight := graph.to_cites[curr_query[0]][i].weight[weight_type];
					// при weight_type = 1 делаем поиск по времени 
					if (curr_dist + curr_weight) < dist[index_to_city].min_dist then
					begin
						dist[index_to_city].min_dist := curr_dist + curr_weight;

						SetLength(dist[index_to_city].prev_node, 1);
						dist[index_to_city].prev_node[0] := curr_query[0];

						if index_to_city < length(graph.from_cites) then 
							add_index_next_query(index_to_city, next_query);
					end
					else if (curr_dist + curr_weight) = dist[index_to_city].min_dist then
					begin
						len_prev_node := length(dist[index_to_city].prev_node);
						SetLength(dist[index_to_city].prev_node, len_prev_node+1);
						dist[index_to_city].prev_node[len_prev_node] := curr_query[0];
					end;
				end;
				deleteInt(0, curr_query);
			end;
		end;
	end;

	// for i:=0 to length(dist)-1 do
	// begin
	// 	if i < length(graph.from_cites) then
	// 		writeln(dist[i].min_dist:2:2, ' ', graph.from_cites[i], ' ')
	// 	else 
	// 		writeln(dist[i].min_dist:2:2, ' ', graph.end_cites[i-length(graph.from_cites)].name_end_city, ' ');

	// 	write('			');
	// 	for k:=0 to length(dist[i].prev_node)-1 do 
	// 		write(graph.from_cites[dist[i].prev_node[k]], ' ');
	// 	writeln();
	// end;

	Belman_Ford_Algorithm := dist;
end; 	

procedure path_min_time_and_cost(from_city:string; to_city:string; var dist: arr_node_data; var graph: transport);
var min_cost, cost, i, j, index_min_cost: integer;
	index_from_city, index_to_city: integer;
begin
	writeln();
	index_to_city := get_index_to_value(to_city,graph);
	index_from_city := get_index_to_value(from_city,graph);

	min_cost := 10000000;
	writeln('');
	writeln('min time: ', dist[get_index_to_value('Тула', graph)].min_dist:2:2);

	path_restoration(index_to_city, index_from_city, dist);
	for i:=0 to length(paths)-1 do
	begin
		cost := 0;
		for j:=length(paths[i])-1 downto 0 do
		begin
			if j <> length(paths[i])-1 then 
				cost += graph.to_cites[index_from_city][paths[i][j]].weight[2];
		end;
		if cost < min_cost then
		begin 
			min_cost := cost;
			index_min_cost := i;
		end;
	end;

	writeln('path min time and min cost:');
	writeln('=================');
	write('	');
	for j:=length(paths[index_min_cost])-1 downto 0 do
	begin
		write(get_value_to_index(paths[index_min_cost][j], graph));
		if j <> 0 then write('=>');
	end;
	writeln();
end;

procedure path_min_cost(from_city:string; to_city:string; var dist: arr_node_data; var graph: transport);
var i, j, index_min_cost: integer;
	index_from_city, index_to_city: integer;
begin
	writeln('');
	index_to_city := get_index_to_value(to_city,graph);
	index_from_city := get_index_to_value(from_city,graph);

	writeln('');
	writeln('min cost: ', dist[get_index_to_value('Тула', graph)].min_dist:2:2);
	writeln('possible route:');
	writeln('=================');

	path_restoration(index_to_city, index_from_city, dist);
	for i:=0 to length(paths)-1 do
	begin
		write('	');
		for j:=length(paths[i])-1 downto 0 do
		begin
			write(get_value_to_index(paths[i][j], graph));
			if j <> 0 then write('=>');
		end;
		writeln();
	end;
	writeln();
end;

procedure path_min_length(from_city:string; to_city:string; var dist: arr_node_data; var graph: transport);
var i, j, index_min_length, min_length: integer;
	index_from_city, index_to_city: integer;
begin
	index_to_city := get_index_to_value(to_city,graph);
	index_from_city := get_index_to_value(from_city,graph);

	min_length := 1000000;

	writeln('');
	writeln('possible route:');
	writeln('=================');

	path_restoration(index_to_city, index_from_city, dist);

	for i:=0 to length(paths)-1 do
	begin
		if length(paths[i]) < min_length then
			min_length := length(paths[i]);

		index_min_length := i;
	end;

	for i:=length(paths[index_min_length])-1 downto 0 do
	begin
		write(get_value_to_index(paths[index_min_length][i], graph));
		if i <> 0 then write('=>');
	end;
	writeln();
end;

begin
	error_log := '';
	flag_session := true;
	parser();
	fill_end_cites();

	if error_log = '' then
	begin
		// // 1.
		// dist := Belman_Ford_Algorithm('Москва', 1, graph[0]);
		// path_min_time_and_cost('Москва','Тула',dist, graph[0]);

		// // 2.
		// dist := Belman_Ford_Algorithm('Москва', 2, graph[0]);
		// path_min_cost('Москва','Тула',dist, graph[0]);

		// 3.
		// dist := Belman_Ford_Algorithm('Москва', 3, graph[0]);
		// path_min_length('Москва', 'Курск', dist, graph[0]);

		// 4 
		// cites := BFS('Москва', 1200, graph[0]);



		writeln('Привет');
		while flag_session do 
		begin
			writeln();
			writeln();
			writeln('Выбери режим поиска:');
			writeln('                               ');
			writeln('1. Среди кратчайших по времени путей между двумя городами найти путь минимальной стоимости');
			writeln('2. Среди путей между двумя городами найти путь минимальной стоимости');
			writeln('3. Найти путь между 2-мя городами минимальный по числу посещенных городов');
			writeln('4. Найти множество городов, достижимых из города отправления не более чем за limit_cost денег');
			writeln('5. Найти множество городов, достижимых из города отправления не более чем за limit_time времени');
			writeln('6. выйти');
			writeln('                               ');

			write('>: ');
			readln(search_mode);
			if search_mode = 6 then 
				flag_session := false
			else 
			begin
				if search_mode = 4 then
				begin
	 				writeln('Задайте limit_cost');
	 				write('>: ');
					readln(limit_cost);
				end;
				if search_mode = 5 then
				begin
	 				writeln('Задайте limit_time');
	 				write('>: ');
					readln(limit_time);
				end;
				writeln('Каким типом транспорта ты хочешь воспользоваться:');
				for i := 0 to length(graph)-1 do 
				begin
					writeln(IntToStr(i+1) + '. ' + graph[i].name_transport)
				end;
				writeln('                               ');
				write('>: ');
				readln(transport_type);
				writeln();

				writeln('Выбери город отправления:');
				writeln();
				for i := 0 to length(graph)-1 do 
				begin
					for j := 0 to length(graph[i].from_cites)-1 do 
					begin
						writeln('	', graph[i].from_cites[j] , ' ')
					end;
					for j := 0 to length(graph[i].end_cites)-1 do 
					begin
						writeln('	', graph[i].end_cites[j].name_end_city, ' ');
					end; 
				end;
				writeln('                               ');
				write('>: ');
				readln(curr_from_city);

				writeln('Выбери город прибытия:');
				writeln();
				for i := 0 to length(graph)-1 do 
				begin
					for j := 0 to length(graph[i].from_cites)-1 do 
					begin
						writeln('	', graph[i].from_cites[j] , ' ')
					end;
					for j := 0 to length(graph[i].end_cites)-1 do 
					begin
						writeln('	', graph[i].end_cites[j].name_end_city, ' ');
					end; 
				end;
				writeln('                               ');
				write('>: ');
				readln(curr_to_city);


				if search_mode = 1 then
				begin
					dist := Belman_Ford_Algorithm(curr_from_city, 1, graph[transport_type-1]);
					// print_graph();
					path_min_time_and_cost(curr_from_city,curr_to_city,dist, graph[transport_type-1]);
				end;
				if search_mode = 2 then
				begin
					dist := Belman_Ford_Algorithm(curr_from_city, 2, graph[transport_type-1]);
					// print_graph();
					path_min_cost(curr_from_city,curr_to_city, dist, graph[transport_type-1]);
				end;
				if search_mode = 3 then
				begin
					dist := Belman_Ford_Algorithm(curr_from_city, 3, graph[transport_type-1]);
					// print_graph();
					path_min_length(curr_from_city,curr_to_city, dist, graph[transport_type-1]);
				end; 
			end;
		end;
		writeln(error_log);
	end;
end.
