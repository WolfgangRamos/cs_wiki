-module(mvar).
-export([new_mvar/0,take_mvar/1,put_mvar/2]).

new_mvar() -> spawn(fun() -> empty() end).

empty() ->
  receive
    {put,V,P} -> P!put,
                 full(V) 
  end.

full(V) ->
  receive
    {take,P} -> P!{took,V},
                empty();
    {read,P} -> P!{read,V},
                full(V)
  end.

take_mvar(MVar) ->
  MVar!{take,self()},
  receive
     {took,V} -> V
  end.

put_mvar(MVar,V) ->
  MVar!{put,V,self()},
  receive
    put -> ok
  end.

read_mvar(Mvar) ->
  MVar!{read,self()},
  receive
    {read,V} -> V
  end.
