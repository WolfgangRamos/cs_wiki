-module(effQueue).
-export([empty/0,enqueue/2,dequeue/1]).

empty() -> {q,[],[]}.

dequeue({q,[X|Xs],Ys}) -> {X,{q,Xs,Ys}};
dequeue({q,[],Ys})     -> dequeue({q,lists:reverse(Ys),[]}).

enqueue({q,Xs,Ys},V) -> {q,Xs,[V|Ys]}.


