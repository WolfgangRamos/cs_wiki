-module(queueLinda).
-export([start/0,in/2,out/2,rd/2]).
-import(effQueue,[empty/0,enqueue/2,dequeue/1]).

start() -> S = spawn(fun() -> space(empty(),[]) end),
           register(linda,S),
           S.

space(Q,Reqs)-> 
  receive
    {out,T} -> {Reqs1,KeepT} = findMatchingReq(T,Reqs),
               case KeepT of
                 true  -> space(enqueue(Q,T),Reqs1);
                 false -> space(Q,Reqs1)
               end;
    {InRd,F,P} -> case findMatchingTuple(F,Q,InRd) of
                    nothing           -> space(Q,Reqs++[{F,P,InRd}]);
                    {just,{Match,Q1}} -> P!{tupleMatch,Match},
                                         space(Q1,Reqs)
                  end
  end.

findMatchingReq(_,[]) -> {[],true};
findMatchingReq(T,[Req|Reqs]) ->
  {F,P,InRd} = Req,
  case catch F(T) of
    {'EXIT',_} -> {Reqs1,KeepT} = findMatchingReq(T,Reqs),
                  {[Req|Reqs1], KeepT};
    Match      -> P!{tupleMatch, Match},
                  case InRd of
                    in -> {Reqs,false};
                    rd -> findMatchingReq(T,Reqs)
                  end
  end.

findMatchingTuple(_,{q,[],[]},_)    -> nothing;
findMatchingTuple(F,{q,[],Ys},InRd) ->
  findMatchingTuple(F,{q,lists:reverse(Ys),[]},InRd); 
findMatchingTuple(F,{q,[T|Ts],Ys},InRd) ->
  case catch F(T) of
    {'EXIT',_} -> case findMatchingTuple(F,{q,Ts,Ys},InRd) of
                    nothing                -> nothing; 
                    {just,{M1,{q,Ts1,Zs}}} -> {just,{M1,{q,[T|Ts1],Zs}}}
                  end;
    Match      -> case InRd of
                    in -> {just,{Match,{q,Ts,Ys}}};
                    rd -> {just,{Match,{q,[T|Ts],Ys}}}
                  end
  end.

out(Space,T) -> Space!{out,T}.

in_rd(Space,F,InRd) when is_function(F) ->
  Space!{InRd,F,self()},
  receive
    {tupleMatch,Match} -> Match
  end;
in_rd(Space,V,InRd) -> in_rd(Space,fun(X) -> V=X end, InRd).

in(Space,F) -> in_rd(Space,F,in).
rd(Space,F) -> in_rd(Space,F,rd).


