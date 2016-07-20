-module(database).
-export([start/0]).

start() -> spawn(fun() -> database([]) end).

database(KVs) -> 
	receive
		{allocate,Key,P} -> 
			case lookup(Key,KVs) of
				nothing -> 
					P!free,
					receive
						{value,V,P} -> 
							database([{Key,V}|KVs]) 
					end;
				_ -> 
					P!allocated
			end;
		{lookup,Key,P} -> 
			P!lookup(Key,KVs),
			database(KVs)
	end.

lookup(_, []) ->
	nothing;
lookup(Key, [{K,V}|KVs]) ->
	case K == Key of
		true ->
			{just, V};
		false ->
			lookup(Key, KVs)
	end.
                      
