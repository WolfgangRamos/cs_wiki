-module(linda).
-export([start/0, in/2, out/2, rd/2]).

start() ->
    S = spawn(fun() -> space([], []) end),
    register(linda, S),
    S.

space(Ts, Reqs) ->
    receive
        {out, T} ->
            {Reqs1, KeepT} = findMatchingReq(T,Reqs),
            case KeepT of
                true ->
                    space([T|Ts], Reqs1);
                false ->
                    space(Ts, Reqs1)
            end;
        {InRd, F, P} ->
            case findMatchingTuple(F, Ts, InRd) of
                nothing ->
                    space(Ts,[{F,P,InRd}|Reqs]);
                {just, {Match, Ts1}} ->
                    P!{tupleMatch, Match},
                    space(Ts1, Reqs)
            end
    end.

findMatchingTuple(_,[],_) ->
    nothing;
findMatchingTuple(F, [T|Ts], InRd) ->
    case catch F(T) of
        {'EXIT', _} ->
            case findMatchingTuple(F, Ts, InRd) of
                nothing ->
                    nothing;
                {just, {M1, Ts1}} ->
                    {just, {M1, [T|Ts1]}}
            end;
        Match ->
            case InRd of
                in ->
                    {just, {Match, Ts}};
                rd ->
                    {just, {Match, [T|Ts]}}
            end
    end.

out(Space, T) ->
    Space!{out,T}.

in_rd(Space, F, InRd) when is_function(F) ->
    Space!{InRd,F,self()},
    receive
        {tupleMatch, Match} ->
            Match
    end;
in_rd(Space, V, InRd) ->
    in_rd(Space,fun(X) -> V=X end, InRd).

in(Space, X) ->
    in_rd(Space, X, in).

rd(Space,F) ->
    in_rd(Space, X, rd).

findMatchingReq(_,[]) ->    
    {[], true};
findMatchingReq(T,[Req|Reqs]) ->
    {F,P,InRd} = Req,
    case catch F(T) of
        {'EXIT', _} ->
            {Reqs1, KeepT} = findMatchingReq(T,Reqs),
            {[Req|Reqs1], KeepT};
        Match -> 
            P!{tupleMatch, Match},
            case InRd of
                in ->
                    {Reqs,false};
                rd ->
                    findMatchingReq(T,Reqs)
            end
    end.

