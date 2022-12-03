program Belman_Ford_Algorithm;

{$mode objfpc}{$H+}

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

type routes = record
	to_city: DynIntArray;
	cruise_time: DynIntArray;
	cruise_fare: DynIntArray;
end;

type Tgraph = array of array of routes;
type Arr = array [1..5] of string;
		

var error_log: string; graph: Tgraph;
	new_route: routes;
	i, j: integer;
	states: array[1..5] of string = ('from city','to city','transport type','cruise time','cruise fare');
	transports, departure_cities, arrival_cities: DynStrArray;
	number_of_possible_offers: array of integer;
	flag_session, flag_parser: boolean;
	input_file: text;
	search_mode, transport_type: integer;
	from_city, to_city: string;
	limit_cost, limit_time: integer;
	dist: array of integer;


procedure Belman_Ford_Algorithm(n: integer; src: integer, weight_type: integer);
var i:integer;
begin
	SetLength(dist, n);
	for i:=0 to n-1 do dist[i] := maxint;

	dist[src] := 0;

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

procedure fill_in_graph(route_info: Arr);

var transport_index: integer;
	i, j, k: integer;
begin
	(* determine the index of the current vehicle *)
	for k:=0 to length(transports)-1 do 
	begin
		if transports[k] = route_info[3] then
			transport_index := k; 
	end;

	SetLength(number_of_possible_offers, length(transports));
	i := transport_index;
	j := number_of_possible_offers[transport_index];

	(* expanding graph to length(transports) for rows and j+1 for columns *)
	SetLength(graph, length(transports), j+1);

	graph[i][j].to_city := route_info[2];
	graph[i][j].cruise_time := StrToInt(route_info[4]);
	graph[i][j].cruise_fare := StrToInt(route_info[5]);

	number_of_possible_offers[transport_index] += 1;
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


(* function implements the processing of user file and create graph *)
procedure parser();
var el, prev: char;
	r, k: integer;
	route_info: Arr = ('', '', '', '', '');
	is_read: boolean;
	stop: boolean;
	transport_index: integer;
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
					writeln(el);
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
		for i:=0 to length(graph)-1 do 
			for j:=0 to length(graph[i])-1 do 
			begin
				writeln(graph[i][j].from_city);
				writeln(graph[i][j].to_city);
				writeln(graph[i][j].cruise_time);
				writeln(graph[i][j].cruise_fare);
			end;
		writeln('Привет');
		while flag_session do 
		begin
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
				for i := 0 to length(transports)-1 do 
				begin
					writeln(IntToStr(i+1) + '. ' + transports[i])
				end;
				writeln('                               ');
				write('>: ');
				readln(transport_type);
				writeln('Выбери город отправления:');
				for i := 0 to length(departure_cities)-1 do 
				begin
					writeln(IntToStr(i+1) + '. ' + departure_cities[i])
				end;
				writeln('                               ');
				write('>: ');
				readln(from_city);
				writeln('Выбери город прибытия:');
				for i := 0 to length(arrival_cities)-1 do 
				begin
					writeln(IntToStr(i+1) + '. ' + arrival_cities[i])
				end;
				writeln('                               ');
				write('>: ');
				readln(to_city);
				
				
				// Belman_Ford_Algorithm(length(graph), pos(from_city, graph));
			end;
		end;
		writeln(error_log);
	end;
end.
