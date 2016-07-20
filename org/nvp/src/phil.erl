-module(phil).
-export([start/0]).

% Sticks sind prozesse, die zwei Zustände haben ('up', 'down') und je
% nach Zustand unterschiedliche Nachrichten verarbeiten.

newStick() -> spawn(fun() -> stickDown() end).

stickDown() ->
  receive
    {take,P} -> P!took,
                stickUp();
    {lookup,P} -> P!true,
                  stickDown()
  end.

stickUp() ->
  receive
    put -> stickDown();
    {lookup,P} -> P!false,
                  stickUp()
  end.

take(S) -> S!{take,self()},
           receive
             took -> ok
           end.

put(S) -> S!put.

lookup(S) -> S!{lookup,self()},
             receive
               Available -> Available 
             end.

start() ->
  S1 = newStick(),
  S2 = newStick(),
  S3 = newStick(),
  S4 = newStick(),
  S5 = newStick(),
  spawn(fun() -> phil(1,S1,S2) end),
  spawn(fun() -> phil(2,S2,S3) end),
  spawn(fun() -> phil(3,S3,S4) end),
  spawn(fun() -> phil(4,S4,S5) end),
  base:getLn(),
  phil(5,S1,S5).

phil(N,SL,SR) ->
  base:printLn(base:show(N)++" thinks"),
  take(SL),
  case lookup(SR) of
    true  -> take(SR),
             base:printLn(base:show(N)++" eats"),
             put(SR);
    false -> base:printLn(base:show(N)++" damn")
  end,
  put(SL),
  phil(N,SL,SR).
