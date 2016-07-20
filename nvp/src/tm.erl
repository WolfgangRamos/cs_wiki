-module(tm).
-export([stack/1, push/2, pop/1, blankStack/1]).

stack(P) -> receive
              pop -> pop;
              X   -> stack(P),
                     base:printLn(X),
                     P!X,
                     stack(P)
            end.

push(S,V) -> S!V.

pop(S) -> S!pop,
          receive
            X -> X
          end.

blankStack(P) -> stack(P),
                 P!blank,
                 blankStack(P).

delta(SL,SR,q,_) -> pop;              % falls q \in F
delta(SL,SR,q,a) -> push(SL,b),
                    A = pop(SR),
                    delta(SL,SR,p,A); % falls q \in Q\F mit 
                                      % \delta(q,a) = (p,b,r)
delta(SL,SR,q,a) -> push(SR,b),
                    A = pop(SL),
                    delta(SL,SR,p,A). % falls q \in Q\F mit 
                                      % \delta(q,a) = (p,b,l)
% Konkrete Umsetzung:
% geg. sei die folgende konkrete Regel der TM: delta(start,a) = (next,a,r)
% dann muss diese Regel für die Funktion delta in das Programm:
delta(SL,SR,start,a) -> push(SL,a),
                        A = pop(SR),
                        delta(SL,SR,next,A);

start() -> Me = self(),
           SL = spawn(fun() -> blankStack(Me) end),
           SR = spawn(fun() -> blankStack(Me) end),
           %writeInputToStack(SR),
           A = pop(SR),
           delta(SL,SR,q0,A),
           outputStack(SR).

