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
 
type to_city = record
	index_to_city: integer;
	cost: integer;
	time: integer;
	end;

type arr_to_cites = array of to_city;
type arr_from_to_cites = array of arr_to_cites;

type end_city = record 
	name_end_city: string;
	i: array of integer;
	j: array of integer;
	end;

type arr_end_cites = array of end_city;

type transport = record 
	name_transport: string;
	from_cites: DynStrArray;
	to_cites: arr_from_to_cites;
	end_cites: arr_end_cites;
	end;

type Tgraph = array of transport;
type Arr = array [1..5] of string;


var error_log: string; graph: Tgraph;
	i, x, y: integer;
	states: array[1..5] of string = ('from city','to city','transport type','cruise time','cruise fare');
	transports, departure_cities, arrival_cities: DynStrArray;
	flag_session, flag_parser: boolean;
	input_file: text;
	search_mode, transport_type: integer;
	curr_from_city, curr_to_city: string;
	limit_cost, limit_time: integer;


const Infinity = 1.0 / 0.0;


// procedure Belman_Ford_Algorithm(src: string; weight_type: integer; var graph: transports); 

// var i, len: integer;
// 	dist: array of real;
// 	curr_query, next_query: array of string;

// begin
// 	len := length(graph.from_cites) + length(graph.end_cites);
// 	SetLength(dist, len);

// 	SetLength(curr_query, len);
// 	SetLength(next_query, len);

// 	for i:=0 to len-1 do 
// 	begin
// 		if graph[i].name_from_city = src then
// 		begin
// 			dist[i] := 0.0;
// 			next_query[0] := src;
// 		end
// 		else
// 			dist[i] := Infinity;
// 		writeln(dist[i]);
// 	end;
// end;
 

procedure delete(index: integer; var arr: arr_end_cites);
var i: integer;
begin
	for i:=index to length(arr)-1 do
	begin
		arr[i] := arr[i+1];
 	end;
 	SetLength(arr, length(arr)-1);
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
	to_cites[len].time := StrToInt(route_info[4]);
	to_cites[len].cost := StrToInt(route_info[5]);
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
	to_cites[len_to_city].time := StrToInt(route_info[4]);
	to_cites[len_to_city].cost := StrToInt(route_info[5]);
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

				write(graph[i].to_cites[x][y].time,' ');
				writeln(graph[i].to_cites[x][y].cost);
			end;
		end;
		writeln('               ');
	end;
end;

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
				uappend(route_info[3], transports);
				uappend(route_info[2], arrival_cities);
				uappend(route_info[1], departure_cities);
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

begin
	error_log := '';
	flag_session := true;
	parser();
	fill_end_cites();

	if error_log = '' then
	begin
		print_graph();
		// Belman_Ford_Algorithm('Москва', 1, graph[0]);
		// writeln('Привет');
		// while flag_session do 
		// begin
		// 	writeln('Выбери режим поиска:');
		// 	writeln('                               ');
		// 	writeln('1. Среди кратчайших по времени путей между двумя городами найти путь минимальной стоимости');
		// 	writeln('2. Среди путей между двумя городами найти путь минимальной стоимости');
		// 	writeln('3. Найти путь между 2-мя городами минимальный по числу посещенных городов');
		// 	writeln('4. Найти множество городов, достижимых из города отправления не более чем за limit_cost денег');
		// 	writeln('5. Найти множество городов, достижимых из города отправления не более чем за limit_time времени');
		// 	writeln('6. выйти');
		// 	writeln('                               ');

		// 	write('>: ');
		// 	readln(search_mode);
		// 	if search_mode = 6 then 
		// 		flag_session := false
		// 	else 
		// 	begin
		// 		if search_mode = 4 then
		// 		begin
	 // 				writeln('Задайте limit_cost');
	 // 				write('>: ');
		// 			readln(limit_cost);
		// 		end;
		// 		if search_mode = 5 then
		// 		begin
	 // 				writeln('Задайте limit_time');
	 // 				write('>: ');
		// 			readln(limit_time);
		// 		end;
		// 		writeln('Каким типом транспорта ты хочешь воспользоваться:');
		// 		for i := 0 to length(transports)-1 do 
		// 		begin
		// 			writeln(IntToStr(i+1) + '. ' + transports[i])
		// 		end;
		// 		writeln('                               ');
		// 		write('>: ');
		// 		readln(transport_type);
		// 		writeln('Выбери город отправления:');
		// 		for i := 0 to length(departure_cities)-1 do 
		// 		begin
		// 			writeln(IntToStr(i+1) + '. ' + departure_cities[i])
		// 		end;
		// 		writeln('                               ');
		// 		write('>: ');
		// 		readln(curr_from_city);
		// 		writeln('Выбери город прибытия:');
		// 		for i := 0 to length(arrival_cities)-1 do 
		// 		begin
		// 			writeln(IntToStr(i+1) + '. ' + arrival_cities[i])
		// 		end;
		// 		writeln('                               ');
		// 		write('>: ');
		// 		readln(curr_to_city);
				
				
		// 		// Belman_Ford_Algorithm(length(graph), pos(curr_from_city, graph));
		// 	end;
		// end;
		// writeln(error_log);
	end;
end.
