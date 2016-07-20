-module(runtimeStack).
-export([stack/1, blank_stack/1]).

stack(P) ->
	receive
		pop ->
			pop;
		V ->
			stack(P),
			P!V,
			stack(P)
	end.

blank_stack(P) ->
	stack(P),
	P!blank,
	blank_stack(P).
