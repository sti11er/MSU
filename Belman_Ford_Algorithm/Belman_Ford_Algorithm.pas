program Belman_Ford_Algorithm;

{$mode objfpc}{$H+}

Uses sysutils,
	{$IFDEF UNIX}{$IFDEF UseCThreads}
	cthreads,
	{$ENDIF}{$ENDIF}
	Classes, 
	Math;



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

type routes = record
	from_city: string;
	to_city: string;
	cruise_time: integer;
	cruise_fare: integer;
end;

type Tgraph = array of array of routes;
type Arr = array [1..5] of string;


var error_log: string; graph: Tgraph;
	new_route: routes;
	i, j: integer;
	states: array[1..5] of string = ('from city','to city','transport type','cruise time','cruise fare');
	transports: array of string;
	number_of_possible_offers: array of integer;


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
	i, j, k, l: integer;
begin
	(* checking an transports for uniqueness *)
	if counter(route_info[3], transports) = 0 then 
	begin
		l := length(transports);
		SetLength(transports, l+1);
		transports[l] := route_info[3];
	end;

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

	graph[i][j].from_city := route_info[1];
	graph[i][j].to_city := route_info[2];
	graph[i][j].cruise_time := StrToInt(route_info[4]);
	graph[i][j].cruise_fare := StrToInt(route_info[5]);

	number_of_possible_offers[transport_index] += 1;
end;

(* function implements the processing of user file and create graph *)
procedure parser();
var flag: boolean; 
	el: char;
	i, j, r, k: integer;
	route_info: Arr = ('', '', '', '', '');
	is_read: boolean;
	stop: boolean;
	transport_index: integer;
	line_number: integer;
begin
	flag := true;
	is_read := false;

	stop := false;
	r := 1;
	line_number := 0;

	while flag do 
	begin
		(*  if end line or end file *)
		if eoln() or eof() then
		begin
			is_read := false;
			stop := false;
			line_number += 1; 

			if counter('', route_info) = 0 then 
				fill_in_graph(route_info)
			else if counter('', route_info) <> 5 then
			begin
				error_log := 'error, incomplete data' + ' (' +IntToStr(line_number)+') line number';
				flag := false;
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
		if eof() then flag := False
		else
		begin
			read(el);
			if ((r <= 3) and char_in_string(el, FIGURES)) then 
			begin
				error_log := 'error, invalid in ' + states[r] + ' (' +IntToStr(line_number)+') line number';
				flag := false;
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
					flag := false;
					stop := false;
				end
				else 
				begin
					if el <> '"' then route_info[r] += el;

					if char_in_string(el, FIGURES) or (el = '"') then
						is_read := true
					else if is_read = false then
					begin
						error_log := 'error, invalid in ' + states[r] + ' (' +IntToStr(line_number)+') line number';
						flag := false;
					end;
				end;
			end
			else if is_read then
			begin
				r += 1;
				is_read := false;
			end; 
		end;
	end;

	writeln(error_log);
end;

begin
	error_log := '';
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
	end;
end.
