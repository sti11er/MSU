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
	name_to_city: string;
	cost: integer;
	time: integer;
	end;

type arr_to_cites = array of to_city;
type from_city = record 
	name_from_city: string;
	to_cites: arr_to_cites;
	end;

type arr_from_cites = array of from_city;
type transport = record 
	name_transport: string;
	from_cites: arr_from_cites;
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
	dist: array of integer;

// procedure Belman_Ford_Algorithm(n: integer; src: integer, weight_type: integer);
// var i:integer;
// begin
// 	SetLength(dist, n);
// 	for i:=0 to n-1 do dist[i] := maxint;

// 	dist[src] := 0;

// end;
 


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


procedure add_to_city(route_info: Arr; var to_cites: arr_to_cites);
var len: integer;
begin
	len := length(to_cites);
	SetLength(to_cites, len+1);
	to_cites[len].name_to_city := route_info[2];
	to_cites[len].time := StrToInt(route_info[4]);
	to_cites[len].cost := StrToInt(route_info[5]);
end;

procedure add_from_city(route_info: Arr; var from_cites: arr_from_cites);
var len: integer;
begin
	len := length(from_cites);
	SetLength(from_cites, len+1);
	from_cites[len].name_from_city := route_info[1];
	add_to_city(route_info, from_cites[len].to_cites);
end;

procedure add_transport(route_info: Arr);
var len: integer;
begin
	len := length(graph);
	SetLength(graph, len+1);
	graph[len].name_transport := route_info[3];
	add_from_city(route_info, graph[len].from_cites);
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
		index_from_city := -1;

		for i:=0 to length(graph[index_trans].from_cites)-1 do 
		begin
			if graph[index_trans].from_cites[i].name_from_city = route_info[1] then
			begin
				index_from_city := i;
				break
			end;
		end;

		if index_from_city = -1 then
			add_from_city(route_info, graph[index_trans].from_cites)
		else
		// если город есть то записываем еще один вариант маршрута прибытия
		begin
			add_to_city(route_info, graph[index_trans].from_cites[index_from_city].to_cites);
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

	if error_log = '' then
	begin
		(* print graph *)
		for i:=0 to length(graph)-1 do 
		begin
			writeln(graph[i].name_transport,': ');
			for x:=0 to length(graph[i].from_cites)-1 do 
			begin
				writeln('	',graph[i].from_cites[x].name_from_city,': ');
				for y:=0 to length(graph[i].from_cites[x].to_cites)-1 do 
				begin
					write('		',graph[i].from_cites[x].to_cites[y].name_to_city,' ');
					write(graph[i].from_cites[x].to_cites[y].time,' ');
					writeln(graph[i].from_cites[x].to_cites[y].cost);
				end;
			end;
			writeln('               ');
		end;
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
