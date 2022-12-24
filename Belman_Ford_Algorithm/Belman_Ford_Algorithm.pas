program Belman_Ford_Algorithm;

Uses sysutils, Math;

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

type dyn_str_array = array of string;
type dyn_int_array = array of integer;
type dyn_int_matrix = array of dyn_int_array;
type two_el_array = array[1..2] of integer;

type to_city = record
	index_to_city: integer;
	weight: array of two_el_array;
	transports: dyn_int_array;
	end;

type arr_to_cites = array of to_city;
type arr_from_to_cites = array of arr_to_cites;

type end_cites = record 
	name_end_city: string;
	i: array of integer;
	j: array of integer;
	end;
	

type arr_end_cites = array of end_cites;

type graph_type = record
	transports: dyn_str_array;
	from_cites: dyn_str_array;
	to_cites: arr_from_to_cites;
	end_cites: arr_end_cites;
	end;

type five_el_array = array [1..5] of string;
type six_el_array = array [1..6] of string;

type node_data = record
	min_dist: real;
	prev_node: array of integer;
	trans_type: array of integer;
	end;


type arr_node_data = array of node_data;

var error_log: string; graph: graph_type;
	i, j, k: integer;
	states: five_el_array = ('from city','to city','transport type','cruise time','cruise fare');
	modes: six_el_array;
	flag_session, flag_parser: boolean;
	input_file: text;
	search_mode: integer;
	limit_cost, limit_time: real;
	dist: arr_node_data;
	tmp: array of integer;
	paths: dyn_int_matrix;
	transport_types: dyn_int_array;
	curr_from_city, curr_to_city, line_transport_types: string;
	curr_trans_type: integer;
	valid_data: string;

const infinity = 1.0 / 0.0;


(* процердура Delete1 для удаления элемента по индексу из массива типа arr_end_cites *)
procedure Delete1(index: integer; var arr: arr_end_cites);
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

(* процердура Delete1 для удаления элемента по индексу из массива типа dyn_int_array *)
procedure Delete1(index: integer; var arr: dyn_int_array);
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

(* процердура counter для определения количества вхождений элемента в массив типа five_el_array *)
function counter(item: string; arr: five_el_array): integer;
var i, res: integer;
begin
	res := 0;
	for i := 1 to length(arr) do 
	begin
		if item = arr[i] then 
			res += 1;
	end;
	counter := res;
end;

(* функция определяющая, есть ли элемент (char) в массиве string, возвращает boolean type data*)
function Char_in_string(el: char; str: string): boolean;
var i: integer; res: boolean;
begin
	res := false;
	for i := 1 to length(str) do 
	begin
		if el = str[i] then 
			res := true;
	end;
	Char_in_string := res;
end;

(* функция определяющая, есть ли элемент (int) в массиве dyn_int_array,возвращает boolean type data*)
function Int_in_arr(el: integer; arr: dyn_int_array): boolean;
var i: integer; res: boolean;
begin
	res := false;
	for i := 0 to length(arr)-1 do 
	begin
		if el = arr[i] then 
			res := true;
	end;
	Int_in_arr := res;
end;

(* функция возвращающая индекс элемента в массиве тип dyn_str_array *)
function Find_index(el: string; var arr: dyn_str_array): integer;
var i: integer;
begin
	Find_index := -1;
	i := 0;

	while (i < length(arr)) do
	begin
		if arr[i] = el then
		begin
			Find_index := i;
			break;
		end;
		i += 1;
	end;
end;

(* функция возвращающая индекс города отправления/прибытия в графе *)
function Get_index_to_value(val: string): integer;
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

	Get_index_to_value := index;
end;

(* функция возвращающая string значение города отправления/прибытия по его индексу в графе *)
function Get_value_to_index(index: integer): string;
var result: string;
	len: integer;
begin
	len := length(graph.from_cites);
	if index < len then result := graph.from_cites[index]
	else result := graph.end_cites[index-length(graph.from_cites)].name_end_city;

	Get_value_to_index := result;
end;

(* процедура обнавляющая информацию о cost,time,transports для конкретного города
  который передается через index *)
procedure Add_transport_city(index: integer; route_info: five_el_array; var to_cites: arr_to_cites);
var len1: integer;
begin
	len1 := length(to_cites[index].weight);
	SetLength(to_cites[index].weight, len1+1);
	SetLength(to_cites[index].transports, len1+1);

	to_cites[index].weight[len1][1] := StrToInt(route_info[4]);
	to_cites[index].weight[len1][2] := StrToInt(route_info[5]);
	to_cites[index].transports[len1] := Find_index(route_info[3], graph.transports);
end;

(* процедура которая добавляет информацию о городе прибытия (to_city) в граф *)
procedure Add_to_city(route_info: five_el_array; var from_cites: dyn_str_array; 
					var to_cites: arr_to_cites; var end_cites: arr_end_cites);

var len_end_cites, len, tmp1, tmp2, tmp3, l1: integer;
begin
	(* в tmp1 хранится индекс to_city в массиве from_cites *)
	tmp1 := Find_index(route_info[2], from_cites);

	(* если -1, то это конечный город, его нет в from_cites
		добавим его в end_cites *)
	if tmp1 = -1 then
	begin
		len_end_cites := length(end_cites);
		(* в tmp1 хранится индекс to_city в массиве end_cites *)
	
		tmp2 := -1;
	
		for i:=0 to len_end_cites-1 do 
		begin
			if end_cites[i].name_end_city = route_info[2] then
			begin
				tmp2 := i;
				break
			end;
		end;

		(* если -1, то этого города нет в массиве конечных городов *)
		if tmp2 = -1 then
		begin
			SetLength(end_cites, len_end_cites+1);		
			end_cites[len_end_cites].name_end_city := route_info[2];

			l1 := length(to_cites);
			SetLength(to_cites, l1+1);
			to_cites[l1].index_to_city := -len_end_cites-1;

			Add_transport_city(l1, route_info, to_cites);

			SetLength(end_cites[len_end_cites].i, 1);
			SetLength(end_cites[len_end_cites].j, 1);
			end_cites[len_end_cites].i[0] := Find_index(route_info[1], from_cites);
			end_cites[len_end_cites].j[0] := l1;
		end
		else
		begin
			tmp3 := -1;

			for i:=0 to length(to_cites)-1 do
			begin
				if to_cites[i].index_to_city = -tmp2-1 then
				begin
					tmp3 := i;
					break
				end;
			end;

			if tmp3 = -1 then
			begin
				l1 := length(to_cites);
				SetLength(to_cites, l1+1);
				to_cites[l1].index_to_city := -tmp2-1;

				Add_transport_city(l1, route_info, to_cites);
				len := length(end_cites[tmp2].i); 
				SetLength(end_cites[tmp2].i, len+1);
				SetLength(end_cites[tmp2].j, len+1);

				end_cites[tmp2].i[len] := Find_index(route_info[1], from_cites);
				end_cites[tmp2].j[len] := l1;
			end
			else 
			begin
				Add_transport_city(tmp3, route_info, to_cites);
				len := length(end_cites[tmp2].i); 
				SetLength(end_cites[tmp2].i, len+1);
				SetLength(end_cites[tmp2].j, len+1);

				end_cites[tmp2].i[len] := Find_index(route_info[1], from_cites);
				end_cites[tmp2].j[len] := tmp3;
			end;
		end;
	end
	else
	begin
		tmp3 := -1;

		for i:=0 to length(to_cites)-1 do
		begin
			if to_cites[i].index_to_city = tmp1 then
			begin
				tmp3 := i;
				break
			end;
		end;

		if tmp3 = -1 then
		begin
			l1 := length(to_cites);
			SetLength(to_cites, l1+1);
			to_cites[l1].index_to_city := tmp1;

			Add_transport_city(l1, route_info, to_cites);
		end
		else 
		begin
			Add_transport_city(tmp3, route_info, to_cites);
		end;
	end;
end;

(* процедура которая добавляет информацию о городе отправления (from_city) в граф *)
procedure Add_from_city(route_info: five_el_array; var from_cites: dyn_str_array; 
					var to_cites: arr_from_to_cites; var end_cites: arr_end_cites);

var len_from_city, len_to_city, i, j, k, s: integer;
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
			Delete1(i, end_cites);

			for k:=i to length(end_cites)-1 do
				for s:=0 to length(end_cites[k].i)-1 do
					to_cites[end_cites[k].i[s]][end_cites[k].j[s]].index_to_city += 1;
			break
		end
		else i += 1;
	end;

	len_to_city := length(to_cites);
	SetLength(to_cites, len_to_city+1);
	Add_to_city(route_info, from_cites, to_cites[len_to_city], end_cites);
end;

(* процедура заменяющая index_to_city в массиве graph.to_cites конечных городов
с -1 на индекс len(from_cites)+j где j - индекс end_city в массиве end_cites *)
procedure Fill_end_cites();
var i, x, y, len, k: integer;
begin
	len := length(graph.from_cites);
	for i:=0 to length(graph.end_cites)-1 do 
	begin
		for k:=0 to length(graph.end_cites[i].i)-1 do 
		begin
			x := graph.end_cites[i].i[k];
			y := graph.end_cites[i].j[k];
			graph.to_cites[x][y].index_to_city := len+j;
		end;
	end;
end;

(* процедура для печати графа *)
procedure Print_graph();
var i, x, y, index, len: integer;
begin
	len := length(graph.from_cites);
	for x:=0 to len-1 do 
	begin
		writeln(graph.from_cites[x],': ');
		for y:=0 to length(graph.to_cites[x])-1 do 
		begin
			index := graph.to_cites[x][y].index_to_city;

			if index < len then writeln('	',graph.from_cites[index],':')
			else writeln('	',graph.end_cites[index-len].name_end_city,':'); 

			for i:=0 to length(graph.to_cites[x][y].transports)-1 do 
			begin
				write('	  ');
				write(graph.to_cites[x][y].weight[i][1],' ');
				write(graph.to_cites[x][y].weight[i][2],' ');
				writeln(graph.transports[graph.to_cites[x][y].transports[i]], ' ');
			end;

			writeln();
		end;
	end;
	writeln('               ');
end;

(* процедура заполняющая граф *)
procedure Fill_in_graph(route_info: five_el_array);

var index_from_city, tmp: integer;
begin
	(* добавляю в transports все возможные уник транспорты *)
	if Find_index(route_info[3], graph.transports) = -1 then
	begin
		tmp := length(graph.transports);
		SetLength(graph.transports, tmp+1);
		graph.transports[tmp] := route_info[3];
	end;

	(* -1 когда этого города нету *)
	index_from_city := Find_index(route_info[1], graph.from_cites);

	if index_from_city = -1 then
		Add_from_city(route_info, graph.from_cites, graph.to_cites, graph.end_cites)
	else (* город есть *)
	begin
		Add_to_city(route_info, graph.from_cites, graph.to_cites[index_from_city], graph.end_cites)
	end;
end;

(* функция реализует обработку пользовательского файла *)
procedure Parser();
var el, prev: char;
	r, k: integer;
	route_info: five_el_array = ('', '', '', '', '');
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
		(* если конец строки или конец файла *)
		if eoln(input_file) or eof(input_file) then
		begin
			is_read := false;
			stop := false;
			line_number += 1; 

			if counter('', route_info) = 0 then 
			begin
				Fill_in_graph(route_info)
			end
			else if counter('', route_info) <> 5 then
			begin
				error_log := 'error, incomplete data' + ' (' +IntToStr(line_number)+') line number';
				flag_parser := false;
				stop := false;
			end;

			for k := 1 to 5 do 
			begin
				route_info[k] := '';
			end;
			r := 1;
		end;  
		(* если конец файла *)
		if eof(input_file) then flag_parser := False
		else
		begin
			read(input_file, el);
			if ((r <= 3) and Char_in_string(el, FIGURES)) then 
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
					if Char_in_string(el, FIGURES) or (el = '"') then
						is_read := true
					else if is_read = false then
					begin
						error_log := 'error, invalid in ' + states[r] + ' (' +IntToStr(line_number)+') line number';
						flag_parser := false;
					end;
				end;
			end
			else if is_read and ((prev = '"') or Char_in_string(prev, FIGURES)) then
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


(* процедура добавление в массив next_query нового, уникального элемента *)
procedure Add_index_next_query(el: integer; var arr: dyn_int_array);
var i: integer;
	flag: boolean;
begin
	flag := true;
	for i:=0 to length(arr)-1 do
		if el = arr[i] then
		begin
			flag := false;
			break
		end;

	if flag then
	begin
		SetLength(arr, length(arr)+1);
		arr[length(arr)-1] := el;
	end;
end;

(* процедура востанновления всех путей из города to_city в город end_city в массив dist *)
procedure Path_restoration(to_city: integer; end_city: integer; var dist: arr_node_data);
var i, len: integer;
begin	
	SetLength(tmp, length(tmp)+1);
	tmp[length(tmp)-1] := to_city;

	if (to_city = end_city) then
	begin
		len := length(paths);
		SetLength(paths, len+1);
		paths[len] := tmp;
	end
	else
	begin
		for i:=0 to length(dist[to_city].prev_node)-1 do
		begin
			Path_restoration(dist[to_city].prev_node[i], end_city, dist);
		end;
	end;
	SetLength(tmp, length(tmp)-1);
end;

(* процедура добавление элементов из next_query в очередь curr_query *)
procedure Push(var curr_query: dyn_int_array; var next_query: dyn_int_array);
var tmp: dyn_int_array;
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

(* функция возвращающая индекс самого первого транспорта из графа, который подходит пользователю  *)
function Index_transport(user_transports: dyn_int_array; transports: dyn_int_array): integer;
var i, j, transport_index, curr_transport_index: integer;
begin
	Index_transport := -1;

	(* пробегаемся по всем видам транспорта *)
	for i:=0 to length(transports) do 
	begin
		curr_transport_index := transports[i];
		(* проверка, что данные вид транспорта есть в 
				тех видах транспорта, которые указал пользователь *)
		for j:=0 to length(user_transports)-1 do 
		begin
			if curr_transport_index = user_transports[j] then
			begin
				transport_index := curr_transport_index;
				break
			end;
		end;
	end;
	Index_transport := transport_index;
end;

(* алгоритм поиска в ширину *)
procedure BFS(src: string; user_transports: dyn_int_array);

var i, index_src, len_to_cites, index_to_city, len, transport_index: integer;
	curr_query: dyn_int_array;
	next_query: dyn_int_array;

begin
	index_src := Get_index_to_value(src);

	len_to_cites := length(graph.from_cites)+length(graph.end_cites);
	SetLength(dist, len_to_cites);

	for i:=0 to len_to_cites-1 do 
	begin
		dist[i].min_dist := -1;
		SetLength(dist[i].trans_type, 1);
		dist[i].trans_type[0] := -1;
		SetLength(dist[i].prev_node, 1);
		dist[i].prev_node[0] := -1;
	end;

	dist[index_src].min_dist := 0;

	SetLength(curr_query, 1);
	curr_query[0] := index_src;

	while length(curr_query) <> 0 do
	begin		
		SetLength(next_query, 0);

		(* добавление новых элементов в next_query *)
		for i:=0 to length(graph.to_cites[curr_query[0]])-1 do 
		begin
			index_to_city := graph.to_cites[curr_query[0]][i].index_to_city; 
			transport_index := Index_transport(user_transports, graph.to_cites[curr_query[0]][i].transports); 

			if (dist[index_to_city].min_dist = -1) and (transport_index <> -1) then
			begin
				len := length(next_query);
				SetLength(next_query, len+1);
				next_query[len] := index_to_city; 
				dist[index_to_city].min_dist := dist[curr_query[0]].min_dist+1;

				if dist[index_to_city].prev_node[0] = -1 then
				begin
					dist[index_to_city].prev_node[0] := curr_query[0];
					dist[index_to_city].trans_type[0] := transport_index;
				end
				else
				begin
					len := length(dist[index_to_city].prev_node);
					SetLength(dist[index_to_city].prev_node, len+1);
					SetLength(dist[index_to_city].trans_type, len+1);

					dist[index_to_city].prev_node[len] := curr_query[0];
					dist[index_to_city].trans_type[len] := transport_index;
				end; 
			end;
		end;

		Delete1(0, curr_query);
		Push(curr_query, next_query);
	end;	
end; 

(* процедура печати массива dist *)
procedure Print_dist();
var i, j: integer;
begin
	for i:=0 to length(dist)-1 do
	begin
		write(Get_value_to_index(i), ' ', dist[i].min_dist:1:1, ' prev: ');
		for j:=0 to length(dist[i].prev_node)-1 do 
			write(dist[i].prev_node[j], ' ');

		write(' trans: ');
		for j:=0 to length(dist[i].trans_type)-1 do 
			write(dist[i].trans_type[j], ' ');

		writeln();
	end;
	writeln();
end;

(* if weight_type = 1 then search for time
if weight_type = 1 then search for cost *)
procedure Belman_Ford_Algorithm(src: string; weight_type: integer; user_transports: dyn_int_array); 

var i, j, k, len, index_src, index_to_city, 
	curr_weight, tmp_weight, len_prev_node, curr_transport_index, transport_index: integer;
	curr_query, next_query: dyn_int_array;
	curr_dist: real;
	min_weight: int64;
	in_user_transports: boolean;

begin
	index_src := Get_index_to_value(src);

	len := length(graph.from_cites) + length(graph.end_cites);
	SetLength(dist, len);

	SetLength(curr_query, len);
	SetLength(next_query, len);

	for i:=0 to len-1 do 
	begin
		dist[i].min_dist := infinity;
		SetLength(dist[i].trans_type, 1);
		dist[i].trans_type[0] := -1;
		SetLength(dist[i].prev_node, 1);
		dist[i].prev_node[0] := -1;
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
					min_weight := 1000000000000000;
					index_to_city := graph.to_cites[curr_query[0]][i].index_to_city;
					transport_index := -1;

					(* выбираем минимальный по весу маршрут  *)
					for j:=0 to length(graph.to_cites[curr_query[0]][i].weight)-1 do 
					begin
						curr_transport_index := graph.to_cites[curr_query[0]][i].transports[j];
						in_user_transports := false;

						(* проверка, что данные вид транспорта есть в 
												тех видах транспорта, которые указал пользователь *)
						for k:=0 to length(user_transports)-1 do 
						begin
							if curr_transport_index = user_transports[k] then
							begin
								in_user_transports := true;
								break
							end;
						end;

						tmp_weight := graph.to_cites[curr_query[0]][i].weight[j][weight_type];
						if (in_user_transports=true) and (tmp_weight < min_weight) then
						begin
							transport_index := graph.to_cites[curr_query[0]][i].transports[j];
							min_weight := tmp_weight;
						end;
					end;

					curr_weight := min_weight;
					
					if (transport_index <> -1) then
					begin
						if ((curr_dist+curr_weight) < dist[index_to_city].min_dist) then
						begin
							(* очищаем dist[index_to_city].prev_node и dist[index_to_city].trans_type *)
							SetLength(dist[index_to_city].prev_node, 1);
							SetLength(dist[index_to_city].trans_type, 1);

							dist[index_to_city].min_dist := curr_dist + curr_weight;
							dist[index_to_city].prev_node[0] := curr_query[0];
							dist[index_to_city].trans_type[0] := transport_index;
							if index_to_city < length(graph.from_cites) then 
								Add_index_next_query(index_to_city, next_query);
						end
						else if (curr_dist + curr_weight) = dist[index_to_city].min_dist then
						begin
							len_prev_node := length(dist[index_to_city].prev_node);
							SetLength(dist[index_to_city].prev_node, len_prev_node+1);
							SetLength(dist[index_to_city].trans_type, len_prev_node+1);

							dist[index_to_city].prev_node[len_prev_node] := curr_query[0];
							dist[index_to_city].trans_type[len_prev_node] := transport_index;
						end;
					end;
				end;
				Delete1(0, curr_query);
			end;
		end;
	end;
end; 	

(* Среди кратчайших по времени путей между двумя городами найти путь минимальной стоимости *)
procedure Path_min_time_and_cost(from_city:string; to_city:string);
var cost, i, j, k, index_min_cost: integer;
	index_from_city, index_to_city: integer;
	min_cost, min_weight: int64;
begin
	writeln();
	index_to_city := Get_index_to_value(to_city);
	index_from_city := Get_index_to_value(from_city);

	min_cost := 1000000000000000000;
	writeln('');
	writeln('мин стоимость: ', dist[index_to_city].min_dist:2:2);

	Path_restoration(index_to_city, index_from_city, dist);
	for i:=0 to length(paths)-1 do
	begin
		cost := 0;
		for j:=length(paths[i])-1 downto 0 do
		begin
			if j <> length(paths[i])-1 then 
			begin
				min_weight := 1000000000000000000;

				for k:=0 to length(graph.to_cites[index_from_city][paths[i][j]].weight)-1 do
				begin
					if graph.to_cites[index_from_city][paths[i][j]].weight[k][2] < min_weight then
						min_weight := graph.to_cites[index_from_city][paths[i][j]].weight[k][2];
				end;
				cost += min_weight;
			end;
		end;
		if cost < min_cost then
		begin 
			min_cost := cost;
			index_min_cost := i;
		end;
	end;

	writeln('путь минимальный по времени и стоимости:');
	writeln('=================');
	write('	');
	for j:=length(paths[index_min_cost])-1 downto 0 do
	begin
		write(Get_value_to_index(paths[index_min_cost][j]));
		if j <> 0 then write('=>');
	end;
	writeln();
end;

(* Среди путей между двумя городами найти путь минимальной стоимости *)
procedure Path_min_cost(from_city:string; to_city:string);
var i, j: integer;
	index_from_city, index_to_city: integer;
begin
	writeln('');
	index_to_city := Get_index_to_value(to_city);
	index_from_city := Get_index_to_value(from_city);

	writeln('');
	writeln('мин стоимость: ', dist[index_to_city].min_dist:2:2);
	writeln('возможный путь:');
	writeln('=================');

	Path_restoration(index_to_city, index_from_city, dist);
	for i:=0 to length(paths)-1 do
	begin
		write('	');
		for j:=length(paths[i])-1 downto 0 do
		begin
			write(Get_value_to_index(paths[i][j]));
			if j <> 0 then write('=>');
		end;
		writeln();
	end;
	writeln();
end;

(* Найти путь между 2-мя городами минимальный по числу посещенных городов *)
procedure Paths_min_length(from_city:string; to_city:string);
var i, index_min_length: integer;
	index_from_city, index_to_city: integer;
	min_length: int64;
begin
	index_to_city := Get_index_to_value(to_city);
	index_from_city := Get_index_to_value(from_city);

	min_length := 1000000000000000000;

	Path_restoration(index_to_city, index_from_city, dist);

	for i:=0 to length(paths)-1 do
	begin
		if length(paths[i]) < min_length then
		begin
			min_length := length(paths[i]);
		end;
		index_min_length := i;
	end;

	writeln('');
	writeln('возможные пути:');
	writeln('=================');

	write('	');
	for i:=length(paths[index_min_length])-1 downto 0 do
	begin
		write(Get_value_to_index(paths[index_min_length][i]));
		if i <> 0 then write('=>');
	end;
	writeln();
end;

(* шаблон для заполнения города отправления/прибытия *)
procedure Getting_city(type_city: string; var curr_city: string);
var in_cites: boolean;
	error_log: string;
begin 
	repeat
		in_cites := false;
		error_log := '';
		writeln('Выбери город ', type_city, ':');
		writeln();
		for i := 0 to length(graph.from_cites)-1 do 
		begin
			writeln(graph.from_cites[i] , ' ');
		end;
		for i := 0 to length(graph.end_cites)-1 do 
		begin
			writeln(graph.end_cites[i].name_end_city, ' ');
		end; 

		writeln();
		write('>: ');
		readln(curr_city);
		writeln();

		for i := 0 to length(graph.from_cites)-1 do 
			if graph.from_cites[i] = curr_city then
			begin
				in_cites := true;
				break
			end;
		
		if not in_cites then
		begin
			for i := 0 to length(graph.end_cites)-1 do 
				if graph.end_cites[i].name_end_city = curr_city then
				begin
					in_cites := true;
					break
				end;
		end;

		if not in_cites then
		begin
			writeln('---------------------------------------------------------------');
			error_log := 'ОШИБКА, ' + curr_city + ' нет среди среди перечисленных городов';
			writeln(error_log);
			writeln('Возможно Вы ошиблись, выберите город',type_city,' из перечисленных');
			writeln('---------------------------------------------------------------');
		end;

	until error_log = '';
end;

(* Найти множество городов, достижимых из города отправления 
	не более чем за limit_cost/limit_time денег.времени *)
procedure Get_valid_cities(limit: real);
var i: integer;
begin
	writeln('');
	writeln('possible cites:');
	writeln('=================');

	write('	');
	for i:=0 to length(dist)-1 do
	begin
		if dist[i].min_dist <= limit then
		begin
			write(Get_value_to_index(i), ' ');
		end;
	end;
	writeln();
end;


begin
	error_log := '';
	flag_session := true;
	Parser();
	Fill_end_cites();
(* 
	SetLength(transport_types, length(transport_types)+1);
	transport_types[length(transport_types)-1] := 0;

	SetLength(transport_types, length(transport_types)+1);
	transport_types[length(transport_types)-1] := 1;

	Belman_Ford_Algorithm('Москва', 1, transport_types);
	Path_min_time_and_cost('Москва','Крым');
	Print_graph();
	Path_min_cost('Москва','Крым');

	Belman_Ford_Algorithm('Москва', 1, transport_types);
	Get_valid_cities(10);

	Belman_Ford_Algorithm('Москва', 1, transport_types);
	Get_valid_cities(12);


	BFS('Москва', transport_types);
	Paths_min_length('Москва','Крым');
 *)

 	modes[1] := 'Среди кратчайших по времени путей между двумя городами найти путь минимальной стоимости';
 	modes[2] := 'Среди путей между двумя городами найти путь минимальной стоимости';
 	modes[3] := 'Найти путь между 2-мя городами минимальный по числу посещенных городов';
 	modes[4] := 'Найти множество городов, достижимых из города отправления не более чем за limit_cost денег';
 	modes[5] := 'Найти множество городов, достижимых из города отправления не более чем за limit_time времени';
 	modes[6] := 'выйти';

	if error_log = '' then
	begin
		while flag_session do 
		begin
			SetLength(dist, 0);
			writeln('Выбери режим поиска:');
			writeln();
			for i:=1 to 6 do 
				writeln(i,'. ', modes[i]);

			writeln();

			write('>: ');
			readln(search_mode);

			if search_mode = 6 then 
				flag_session := false
			else if (search_mode >= 1) and (search_mode <= 5) then 
			begin 
				if search_mode = 4 then
				repeat
					error_log := '';
	 				writeln('Задайте limit_cost:');
	 				write('>: ');
					readln(limit_cost);

					if limit_cost < 0 then
					begin
						writeln();
						writeln('-------------------------------------------------------------------------');
						error_log := 'ОШИБКА, ' + FloatToStr(limit_cost) + ' ОТРИЦАТЕЛЬНЫЙ limit_cost';
						writeln(error_log);
						writeln('Возможно Вы ошиблись, выберите режим от limit_cost большим, либо равным 0');
						writeln('-------------------------------------------------------------------------');
					end;
					writeln();
				until error_log = '';

				if search_mode = 5 then
				repeat 
					error_log := '';
	 				writeln('Задайте limit_time:');
	 				write('>: ');
					readln(limit_time);
					if limit_time < 0 then
					begin
						writeln();
						writeln('-------------------------------------------------------------------------');
						error_log := 'ОШИБКА, ' + FloatToStr(limit_time) + ' ОТРИЦАТЕЛЬНЫЙ limit_time';
						writeln(error_log);
						writeln('Возможно Вы ошиблись, выберите режим от limit_time большим, либо равным 0');
						writeln('-------------------------------------------------------------------------');
					end;
					writeln();
				until error_log = '';

			
				repeat
					error_log := '';
					writeln('Какими видами транспорта ты хочешь воспользоваться:');
					for i := 0 to length(graph.transports)-1 do 
					begin
						writeln(IntToStr(i+1) + '. ' + graph.transports[i])
					end;
					writeln();
					write('>: ');

					readln(line_transport_types);
					line_transport_types := ' ' + line_transport_types;

					curr_trans_type := 0;
					(* строка символом, которую ввел пользователь *)
					j := 0;
					k := 0;
					for i:=length(line_transport_types) downto 1 do
					begin
						if (line_transport_types[i] = ' ') then 
						begin
							if (curr_trans_type > length(graph.transports)) or (curr_trans_type <= 0) 
								and (i <> length(line_transport_types)) then
							begin
								writeln();
								writeln('---------------------------------------------------------------');
								error_log := 'ОШИБКА, ' + IntToStr(curr_trans_type) + ' нет среди среди перечисленных';
								writeln(error_log);
								writeln('Возможно Вы ошиблись, выберите тип транспорта из перечисленных');
								writeln('---------------------------------------------------------------');
								break
							end;

							SetLength(transport_types, j+1);
							transport_types[j] := curr_trans_type-1;
							k := 0;
							j += 1;
							curr_trans_type := 0;
						end
						else if line_transport_types[i] = '-'  then
						begin
							curr_trans_type := -1 * curr_trans_type;
						end 
						else if line_transport_types[i] <> ' '  then
						begin
							curr_trans_type += round(Power(10, k)) * StrToInt(line_transport_types[i]);
							k += 1;
						end;
					end;
					writeln();

				until error_log = '';

				Getting_city('отправления', curr_from_city);

				if (search_mode <> 4) and (search_mode <> 5) then
				begin
					Getting_city('прибытия', curr_to_city);
				end;

				writeln('Режим: ', modes[search_mode]);
				writeln('Город отправления: ', curr_from_city);

				if search_mode = 4 then writeln('limit_cost: ', limit_cost:2:2)
				else if search_mode = 5 then writeln('limit_time: ', limit_time:2:2)
				else writeln('Город прибытия: ', curr_to_city);

				writeln();
				write('Данные введены верно (да, нет): ');
				read(valid_data);
				writeln();

				if (valid_data = 'да') then
				begin
					(* Print_graph(); *)
					if search_mode = 1 then
					begin
						Belman_Ford_Algorithm(curr_from_city, 1, transport_types);
						Path_min_time_and_cost(curr_from_city,curr_to_city);
					end;
					if search_mode = 2 then
					begin
						Belman_Ford_Algorithm(curr_from_city, 2, transport_types);
						Path_min_cost(curr_from_city,curr_to_city);
					end;
					if search_mode = 3 then
					begin
						BFS(curr_from_city, transport_types);
						Paths_min_length(curr_from_city, curr_to_city);
					end; 
					if search_mode = 4 then
					begin
						Belman_Ford_Algorithm('Москва', 2, transport_types);
						Get_valid_cities(limit_cost);
					end; 
					if search_mode = 5 then
					begin
						Belman_Ford_Algorithm('Москва', 1, transport_types);
						Get_valid_cities(limit_time);
					end;
				end
			end
			else 
			begin
				error_log := 'ОШИБКА, ' + IntToStr(search_mode) + ' НЕСУЩЕСТВУЮЩИЙ РЕЖИМ';
				writeln('----------------------------------------------');
				writeln(error_log);
				writeln('Возможно Вы ошиблись, выберите режим от 1 до 6');
				writeln('----------------------------------------------');
			end;
			writeln();
			writeln();
		end;
		writeln(error_log);
	end;
end.
