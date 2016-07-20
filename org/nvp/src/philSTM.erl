-module(philSTM).
-export([start/0]).
-import(stm,[new_tvar/1,write_tvar/2,read_tvar/1,
             atomically/1,retry/0,or_else/2]).

start() ->
  {S1,S2,S3,S4,S5} = 
       atomically(fun() -> S1 = new_tvar(true),
                           S2 = new_tvar(true),
                           S3 = new_tvar(true),
                           S4 = new_tvar(true),
                           S5 = new_tvar(true),
                           {S1,S2,S3,S4,S5} end),
  spawn(fun() -> phil(S1,S2,"1") end),
  spawn(fun() -> phil(S2,S3,"2") end),
  spawn(fun() -> phil(S3,S4,"3") end),
  spawn(fun() -> phil(S4,S5,"4") end),
  phil(S5,S1,"5").

% take_stick is a transaction!
take_stick(S) -> B = read_tvar(S),
                 case B of
                   true  -> write_tvar(S,false);
                   false -> retry()
                 end.

% put_stick is a transaction!
put_stick(S) -> write_tvar(S,true).

phil(SL,SR,N) ->
  base:printLn(N++" is thinking"),
  atomically (fun() -> take_stick(SL),
                       or_else(fun() -> take_stick(SL),
                                        put_stick(SR)
                               end,
                               fun() -> base:print(N++": OR_ELSE")
                               end),    
                       take_stick(SR)
              end),
  %atomically(fun() -> take_stick(SL) end),
  %atomically(fun() -> take_stick(SR) end),
  base:printLn(N++" is eating"),
  atomically (fun() -> put_stick(SL),
                       put_stick(SR)
              end),
  phil(SL,SR,N).





