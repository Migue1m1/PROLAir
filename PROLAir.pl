%MANEJO DE GUI.

%new_dialog(N,D):- Devuelve undialogo en D con nombre N.
%(string, dialog)(+,?)
new_dialog(Name, Dialog):- new(Dialog, dialog(Name)).

%new_window(N,W):- Devuelve una ventana W con nombre N.
%(string, picture)(+,?)
new_window(Name, Window):- new(Window, picture(Name)).

%Menu con todas las opciones.
menu_options(vuelos_):-
	new_dialog('PROLair®: Vuelos', Dialog),
	send_list(Dialog, append, [new(Vop, menu(vuelos_)),
				 button(ok, and(message(@prolog, menu_options, Vop?selection),
					       message(Dialog, destroy)))]),
	send_list(Vop, append, [todos, vuelos_Por_Dia]),
	send(Dialog, open).
menu_options(todos):-
	new_window('PROLair®: Vuelos', Ventana),
	allFligths(Ventana),
	send(Ventana, open).
menu_options(vuelos_Por_Dia):-
	new_dialog('PROLair®: Vuelos', Dialog),
	send_list(Dialog, append,[new(DV, text_item(dia)),
				 button(ok, and(message(@prolog, fligthsDay, DV?selection),
					        message(Dialog, destroy)))]),
	send(Dialog, open).
menu_options(origen_):-
	new_dialog('PROLair®: Origen', Dialog),
	send_list(Dialog, append,[new(TO, text_item(origen_)),
				 button(ok, and(message(@prolog, origin, TO?selection),
					        message(Dialog, destroy)))]),
	send(Dialog, open).
menu_options(destino_):-
	new_dialog('PROLair®: Destino', Dialog),
	send_list(Dialog, append,[new(TD,text_item(destino_)),
				  button(ok, and(message(@prolog, destination, TD?selection),
					         message(Dialog, destroy)))]),
	send(Dialog,open).
menu_options(rutas_):-
	new_dialog('PROLair®: Rutas', Dialog),
	send_list(Dialog, append,[new(Rop, menu(rutas_)),
				  button(ok, and(message(@prolog, menu_options, Rop?selection),
					         message(Dialog, destroy)))]),
	send_list(Rop, append, [todas, mas_Economica]),
	send(Dialog, open).
menu_options(todas):-
	new_dialog('PROLair®: Rutas', Dialog),
	send_list(Dialog, append, [new(TO, text_item(origen_)),
				   new(TD, text_item(destino_)),
				   button(ok, and(message(@prolog, allPaths, TO?selection, TD?selection),
					          message(Dialog, destroy)))]),
	send(Dialog, open).
menu_options(mas_Economica):-
	new_dialog('PROLair®: Economía', Dialog),
	send_list(Dialog, append, [new(TO, text_item(origen_)),
				   new(TD, text_item(destino_)),
				  button(ok, and(message(@prolog, cheapPath, TO?selection, TD?selection),
					         message(Dialog, destroy)))]),
	send(Dialog, open).

%Carga la hora de conexión mínima.
set_hour_connection(H):- atom_number(H, Hour), number(Hour), Hour >= 0,Hour =< 23.59,
                         deleteDinamicHour,
	                 asserta(dinamicHour(Hour)).

% Valida si la diferencia entre +H1 y +H2
% cumple con la hora de conexión mínima.
valid_hour_connection(H1, H2):-  get_hour_connection(H_Cn),
				 Hora is H2 - H1,
	                         Hora >= H_Cn.

% Obtiene la hora de conexión mínima.
% Por defecto es 0.
get_hour_connection(H):- retract(dinamicHour(H)), asserta(dinamicHour(H)), !.
get_hour_connection(0).

%Elimina de memoria la hora de conexión mínima.
deleteDinamicHour:- findall(_, retract(dinamicHour(_)), _), !.
deleteDinamicHour.

%Menú de configuración para la hora de conexión mínima.
menu_hour:- new_dialog('PROLair®: Config', Dialog),
	    send_list(Dialog, append, [new(Hr,text_item(hora)),
				       button(ok,and(message(@prolog, set_hour_connection, Hr?selection),
					             message(Dialog, destroy)))]),
	    send(Dialog, open).

%LOGICA DE NEGOCIOS.

%Devuelve los posibles caminos entre +Orig y +Dest.
%COntiene las rutas simples y con escala.
%rutas(+, +, ?, ?, ?, +, +)
rutas(Orig, Dest, Cost, Hs, [Vuelo], _, _) :- vuelos(Orig, Dest, Hs, Hll, Cost, Num, Ds),
	                                      procDays(Ds, Dias),
					      outPutRt([Orig, Dest, Hs, Hll, Cost, Num, Dias], Vuelo).

rutas(Orig, Dest, Cost, Hs, [Vuelo|P], Vstd, T) :- \+ member(Orig, Vstd),
					           vuelos(Orig, Conn, Hs, Hll, Cost1, Num, Ds),
						   Conn \== T, Conn \== Dest,
	                                           not(member(Conn, Vstd)),
						   procDays(Ds, Dias),
						   outPutRt([Orig, Conn, Hs, Hll, Cost1, Num, Dias], Vuelo),
                                                   rutas(Conn, Dest, Cost2, H2, P, [Orig|Vstd], T),
						   valid_hour_connection(Hll, H2),
						   Cost is Cost1 + Cost2.
rutas(Orig, Dest, Cost, Path, Vstd):- rutas(Orig, Dest, Cost, _, Path, Vstd, Orig).

min([],X,X).
min([[H|G]|T],[M|_],X) :- H =< M, min(T,[H|G],X).
min([[H|_]|T],[M|G],X) :- M < H, min(T,[M|G],X).
min([[H|G]|T],X) :- min(T,[H|G],X).

printList([]):- !.
printList([H|T]):- writef("%w\n", [H]), printList(T).

%Procesa un lista de vuelo y devuelve un string.

mergeDays([D], [Str]):- string_concat(D, '.', Str), !.
mergeDays([D|Ds], [Str|P]):- string_concat(D, ', ', Str), mergeDays(Ds, P).

% Merge compuesto.
% Al quedar un elemento en las listas procesa la lista de días.
mergeVlsTitls([D1], [D], [Str]):- mergeDays(D, LD),
	                          listToString(LD, '', SD),
				  string_concat(D1, SD, Str).
mergeVlsTitls([H1|T1], [H|T], [Str|P]):- string_concat(H1, H, Str), mergeVlsTitls(T1, T, P).

%Toma una lista y la retorna como string.
listToString([], S, S).
listToString([H|T], S, F):- string_concat(S, H, J), listToString(T, J, F).

%Salida en formato string para un +Fligth.
%Usado solo por flightsToString.
outPutFligth(Fligth, OutPut):- mergeVlsTitls(['Origen: ', ', Destino: ', ', Hs: ', ', Hll: ', ', Costo: ', ', Num: ', ', Dias: '],
				             Fligth, MergeVlsTitls),
			       listToString(MergeVlsTitls, '', OutPut).

%Procesa una lista de dias (+Ds) devolviendola como string.
procDays(Ds, Dias):- mergeDays(Ds, LD), listToString(LD, '', Dias).
%Merge simple de subtitulo con origen, destino, etc.
mergeVl([], [], []):- !.
mergeVl([H1|T1], [H|T], [Str|P]):- string_concat(H1, H, Str), mergeVl(T1, T, P).
%Salida en formato string para un +Fligth.
%Usado solo para encontrar todas las rutas, y la más económica.
outPutRt(Fligth, OutPut):- mergeVl(['Origen: ', ', Destino: ', ', Hs: ', ', Hll: ', ', Costo: ', ', Num: ', ', Dias: '],
		                   Fligth, MergeVlsTitls),
			   listToString(MergeVlsTitls, '', OutPut).

%Muestra en +Ventana una ruta, simple o sin escalas.
showList([], _, PosY, PosY).
showList([H|T], Ventana, PosY, PosY2):- send(Ventana, display,
				        new(label(l,H, font('times', 'roman', 16))), point(30, PosY)),
			                PosY1 is PosY + 40,
			                showList(T, Ventana, PosY1, PosY2).

%Muestra en +Ventana una lista de rutas.
showList2([], _, _).
showList2([H|T], Ventana, PosY):- showList(H, Ventana, PosY, PosY1), PosY2 is PosY1 + 40, showList2(T, Ventana, PosY2).

%Muestra en +Ventana la ruta mas económica entre +Orig y +Dest.
showCheapPath(Orig, Dest, [Cost|[CheapPath]], Ventana):- string_concat('Ruta más económica entre ', Orig, Str1),
				                         string_concat(Str1, ' - ', Str2),
				                         string_concat(Str2, Dest, Str3),
				                         string_concat(Str3, '.    ', Str4),
						         string_concat(Str4, Cost, Str5),
						         string_concat(Str5, 'Bs', SubTtl),
						         send(Ventana, display,
				                              new(label(l, SubTtl, font('times', 'roman', 18))), point(60, 10)),
						         showList(CheapPath, Ventana, 80, _).

%Ruta más económica entre +Orig y Dest.
cheapPath(Orig, Dest):-	new_window('PROLair®: Rutas', Ventana),
	                findall([Cost, Path], rutas(Orig, Dest, Cost, Path, []), Paths),
			min(Paths, CheapPath),
			showCheapPath(Orig, Dest, CheapPath, Ventana),
			send(Ventana, open), !.
cheapPath(_, _):- new_dialog('PROLair®: ERROR', Dialog),
	          send(Dialog, append(label(l,'ERROR: RUTA NO ENCONTRADA',font('times','roman',18)))),
		  send(Dialog, open).

%Muestra en +Ventana las rutas entre +Orig y +Dest.
showAllPaths(Orig, Dest, Paths, Ventana):- length(Paths, Nums),
	                                   string_concat('Todas las rutas entre ', Orig, Str1),
	                                   string_concat(Str1, ' - ', Str2),
					   string_concat(Str2, Dest, Str3),
					   string_concat(Str3, '. Total: ', Str4),
					   string_concat(Str4, Nums, SubTtl),
					   send(Ventana, display,
				                              new(label(l, SubTtl, font('times', 'roman', 18))), point(60, 10)),
					   showList2(Paths, Ventana, 80).

%Todas las rutas entre +Orig y +Dest.
allPaths(Orig, Dest):- new_window('PROLair®: Rutas', Ventana),
		       findall(Path, rutas(Orig, Dest, _, Path, []), Paths),
		       showAllPaths(Orig, Dest, Paths, Ventana),
		       send(Ventana, open).

% Toma una lista de vuelos sin formato.
% Devuelve una lista de strings con los vuelos.
fligthsToStrings([], []).
fligthsToStrings([H|T], [V|Vs]):- outPutFligth(H, V), fligthsToStrings(T, Vs).

%Todos los vuelos.
allFligths(Ventana):- findall([Orig, Dest, Hs, Hll, Cost, Num, Dias], vuelos(Orig, Dest, Hs, Hll, Cost, Num, Dias), Vls),
		      fligthsToStrings(Vls, Vuelos),
		      length(Vuelos, Nums),
		      string_concat('Todos los vuelos. Total: ', Nums, SubTtl),			send(Ventana, display,
			            new(label(l, SubTtl, font('times', 'roman', 18))), point(60, 10)),
		      showList(Vuelos, Ventana, 80, _).

%Todos los vuelos que parten de +Orig.
origin(Orig):- new_window('PROLair®: Rutas', Ventana),
	       findall([Orig, Dest, Hs, Hll, Cost, Num, Dias], vuelos(Orig, Dest, Hs, Hll, Cost, Num, Dias), Vls),
	       fligthsToStrings(Vls, Vuelos),
	       length(Vuelos, Nums),
	       string_concat('Todos los vuelos que parten de ', Orig, Str1),
	       string_concat(Str1, '. Total: ', Str2),
	       string_concat(Str2, Nums, SubTtl),
	       send(Ventana, display,
		             new(label(l, SubTtl, font('times', 'roman', 18))), point(60, 10)),
	       showList(Vuelos, Ventana, 80, _),
	       send(Ventana, open).

%Todos los vuelos con destino a +Dest.
destination(Dest):- new_window('PROLair®: Rutas', Ventana),
	            findall([Orig, Dest, Hs, Hll, Cost, Num, Dias], vuelos(Orig, Dest, Hs, Hll, Cost, Num, Dias), Vls),
		    fligthsToStrings(Vls, Vuelos),
		    length(Vuelos, Nums),
		    string_concat('Todos los vuelos con destino a ', Dest, Str1),
		    string_concat(Str1, '. Total: ', Str2),
		    string_concat(Str2, Nums, SubTtl),
		    send(Ventana, display,
				  new(label(l, SubTtl, font('times', 'roman', 18))), point(60, 10)),
		    showList(Vuelos, Ventana, 80, _),
		    send(Ventana, open).

%Vuelo que se da el día +Day.
validDays(Day, [Orig, Dest, Hs, Hll, Cost, Num, Dias]):- vuelos(Orig, Dest, Hs, Hll, Cost, Num, Dias), member(Day, Dias).

%Todos los vuelos que se dan el día +Day.
fligthsDay(Day):- new_window('PROLair®: Vuelos', Ventana),
	          findall(Vl, validDays(Day, Vl), Vls),
		  fligthsToStrings(Vls, Vuelos),
	          length(Vuelos, Nums),
	          string_concat('Todos los vuelos del día ', Day, Str1),
		  string_concat(Str1, '. Total: ', Str2),
		  string_concat(Str2, Nums, SubTtl),
		  send(Ventana, display,
			        new(label(l, SubTtl, font('times', 'roman', 18))), point(60, 10)),
		  showList(Vuelos, Ventana, 80, _),
		  send(Ventana, open).

%Función principal.
main:- consult('Flights_List.rules'),
       new_dialog('PROLair®', Dialog),
       send(Dialog, append, new(Menu, menu_bar)),
       send(Menu, append, new(Configurar, popup(configurar))),
       %send(Menu, append, new(Ayuda, popup(ayuda))),
       send_list(Configurar, append,
	                     [menu_item(hora_De_Conexión,
				        message(@prolog, menu_hour))]),
       send_list(Dialog, append,
              [new(D, menu(opciones, cycle)),
                      button(cerrar, message(Dialog, destroy)),
                      button(ok, and(message(@prolog, menu_options, D?selection)))]),
       send_list(D, append, [vuelos_, origen_, destino_, rutas_]),
       send(Dialog, default_button, ok),
       send(Dialog, open).
?- main.
