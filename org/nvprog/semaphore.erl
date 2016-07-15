-module(semaphore).
-export().

newSemaphore(N) ->
	spawn(fun() ->
				  sem(N) end).

sem(N) when N >= 1 ->
	receive
		{p, P} ->
			P!go,
			sem(N-1);
		v ->
			sem(N+1)
	end;
sem(N) when N =< 0 ->
	receive
		v ->
			sem(N+1)
	end.

p(Sem) ->
	Sem!{p,self()},
	receive
		go ->
			ok
	end.

v(Sem) ->
	Sem!v.
			
