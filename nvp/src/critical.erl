-module(critical).
-export([start/0]).
-import(ltl,[prop/1,neg/1,conj/2,disj/2,x/1,f/1,g/1,
             assert/1,newProp/1,releaseProp/1,status/0]).

start() -> ltl:start(),
           assert(g(neg(conj(prop(csInc),prop(csDec))))),
           S = spawn(fun() -> store(42) end),
           spawn(fun() -> inc(S) end),
           dec(S).

store(V) ->
  receive
    {lookup,P} -> P!V, store(V);
    {set,V1}   -> store(V1)
  end.

inc(S) -> S!{lookup,self()},
          receive
            V -> newProp(csInc), S!{set,V+1}
          end,
          releaseProp(csInc),
          inc(S).

dec(S) -> S!{lookup,self()},
          receive
            V -> newProp(csDec), S!{set,V-1}
          end,
          releaseProp(csDec),
          dec(S).

