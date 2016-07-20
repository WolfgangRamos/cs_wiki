-module(philLinda).
-export([start/0]).

start() ->
	TS = linda:start(),
	linda:out(TS,{stick,1}),
	linda:out(TS,{stick,2}),
	linda:out(TS,{stick,3}),
	linda:out(TS,{stick,4}),
	linda:out(TS,{stick,5}),
	spawn(fun() -> phil(1, TS, {stick, 1}, {stick,2}) end),
	spawn(fun() -> phil(2, TS, {stick, 2}, {stick,3}) end),
	spawn(fun() -> phil(3, TS, {stick, 3}, {stick,4}) end),
	spawn(fun() -> phil(4, TS, {stick, 4}, {stick,5}) end),
	base:getLn(),
	phil(5, TS, {stick, 5}, {stick,1}).

phil(N,TS,SL,SR) ->
	base:printLn(base:show(N)++" thinks"),
	linda:in(TS,SL),
	linda:in(TS,SR),
	base:printLn(base:show(N)++" eats"),
	linda:out(SL),
	linda:out(SR),
	phil(N,TS,SL,SR).
