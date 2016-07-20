-module(stm).
-export([new_tvar/1,write_tvar/2,read_tvar/1,atomically/1,retry/0,or_else/2,test/0]).
-import(gb_trees,[empty/0,insert/3,enter/3,lookup/2,keys/1,to_list/1]).
-import(lists,[map/2]).

new_tvar(V) ->
	spawn(fun() -> tvar(V,0,[]) end).

tvar(V,Ver,Susps) -> 
  receive
    {core_read,P}   -> P ! {value,V,Ver},
                       tvar(V,Ver,Susps);
    {lock,P}        -> P ! locked,
                       tvar_locked(V,Ver,Susps);
    {unsusp,P}      -> tvar(V,Ver,Susps--[P])
  end.

tvar_locked(V,Ver,Susps) ->
  receive
    {core_write,V1} -> map(fun(P) -> P!go end, Susps),
                       tvar_locked(V1,Ver+1,[]);
    {get_version,P} -> P!{version,Ver},
                       tvar_locked(V,Ver,Susps);
    {susp,P}        -> tvar_locked(V,Ver,[P|Susps]);
    unlock          -> tvar(V,Ver,Susps)
  end.

core_read(T) -> T ! {core_read,self()},
                receive
                  {value,V,Ver} -> {V,Ver}
                end.

core_write(T,V) -> T ! {core_write,V}.

lock(T) -> T!{lock,self()},
           receive
              locked -> ok
           end.

unlock(T) -> T!unlock.

get_version(T) -> T!{get_version,self()},
                  receive
                    {version,Ver} -> Ver
                  end.

% Zum Suspendieren wird ein neuer Prozess ('Catcher') erstellt, der
% die 'go'-Nachrichten der TVars empfängt. Der Thread, welcher die
% Transaktion ausführt kann dafür nicht verwendet werden, da er
% mehrere go Nachrichten empfangen könnte und dann alle bis auf eine
% in seiner mailbox verbleiben würden.
%
% @return: PID des Catcher (um diesen wieder aus der Liste der
% suspendierten Prozesse der TVar entfernen zu können)
susp(Ts) -> Me = self(),
            P = spawn(fun() -> receive
                                 go -> Me!go
                               end
                      end),
            map(fun(T) -> T!{susp,P} end, Ts),
            P.

unsusp(Ts,P) -> map(fun(T) -> T!{unsusp,P} end,Ts).

read_tvar(T) ->
  {RS,WS} = get(trans_state),
  case lookup(T,WS) of
    none      -> {V,Ver} = core_read(T),
                 case lookup(T,RS) of
                   none            -> RS1 = insert(T,Ver,RS),
                                      put(trans_state,{RS1,WS});
                   {value,Old_ver} -> case Old_ver==Ver of
                                        true  -> okay;
                                        false -> throw(rollback)
                                      end
                 end,
                 V;
    {value,V} -> V
  end.

write_tvar(T,V) ->
  {RS,WS} = get(trans_state),
  put(trans_state,{RS,enter(T,V,WS)}).

retry() -> %base:print("RETRY"),
           throw(retry).

or_else(Trans1,Trans2) -> 
  {_,WS1} = get(trans_state),
  case catch Trans1() of
    rollback -> throw(rollback);
    retry    -> %base:print("CATCH"),
                {RS2,_} = get(trans_state),
                put(trans_state,{RS2,WS1}),
                Trans2();
    Res      -> Res
  end.

atomically(Trans) ->
  put(trans_state,{empty(),empty()}),
  case catch Trans() of
    rollback -> %base:print("rollback2"),
                atomically(Trans);
    retry -> {RS,_} = get(trans_state), 
             RL = keys(RS),
             map(fun(Tvar) -> lock(Tvar) end, RL), 
             case validate(to_list(RS)) of
               true  -> P = susp(RL),
                        map(fun(Tvar) -> unlock(Tvar) end, RL),
                        receive
                          go -> go
                        end,
                        unsusp(RL,P); % nicht unbedingt notwendig, da 
                                      % P nach dem ersten empfangenen ok 
                                      % terminiert; das ist jedoch eine
                                      % Erlang-Besonderheit und kann nicht 
                                      % in allen Sprachen so leicht 
                                      % implementiert werden
               false -> map(fun(Tvar) -> unlock(Tvar) end, RL)
             end,
             atomically(Trans);
	  Res -> 
		  {RS,WS} = get(trans_state),
		  Tvars = lists:umerge(keys(RS),keys(WS)), % sorted, no duplicates!
		  map(fun(Tvar) -> lock(Tvar) end, Tvars),
		  case validate(to_list(RS)) of
			  true  -> 
				  % do the commit
				  map(fun({Tvar,V}) -> core_write(Tvar,V) end,
					  to_list(WS)),
				  map(fun(Tvar) -> unlock(Tvar) end, Tvars),
				  Res;
			  false -> 
				  % transaction invalid -> do it again
				  map(fun(Tvar) -> unlock(Tvar) end, Tvars),
				  atomically(Trans)
		  end
  end.

validate([]) -> true;
validate([{T,Ver}|RS]) ->
  case get_version(T) of
    Ver -> validate(RS);
    _   -> false
  end.



test() -> T1 = atomically(fun() -> new_tvar(42) end),
          T2 = atomically(fun() -> new_tvar(73) end),
          spawn(fun() -> test1(T1,100) end),
          test2(T1,T2,100),
          base:print("test2 ist fertig"),
          base:getLn(),
          V1 = atomically(fun() -> read_tvar(T1) end),
          V2 = atomically(fun() -> read_tvar(T2) end),
          base:print({V1,V2}).

test1(_,0) -> base:print("test1 ist fertig");
test1(T,N) -> atomically(fun() -> V1 = read_tvar(T),
                                  write_tvar(T,V1+1),
				  V2 = read_tvar(T),
                                  write_tvar(T,V2+1)
                         end),
              test1(T,N-1).
          
test2(_, _, 0) -> ok;
test2(T1,T2,N) ->
          atomically(fun() -> V1 = read_tvar(T1),
                              V2 = read_tvar(T2),
                              write_tvar(T1,V1+V2)
                     end),
          test2(T1,T2,N-1).
          


