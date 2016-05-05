%%%-------------------------------------------------------------------
%%% @author Jeimmi
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. May 2016 12:39 AM
%%%-------------------------------------------------------------------
-module('Lab5').
-author("Jeimmi").

%% API
-compile(export_all).




index_of(Value, List) ->
  index_of(Value, List, 1).
index_of(V, [V|T], N) ->
  N;
index_of(V, [_|T], N) ->
  index_of(V, T, N+1);
index_of(_, [], _) ->
  false.

first([]) -> undefined;
first([H|_]) -> H.


room(Students, Capacity, Queue, Helping) ->
  receive
  % student entering, not at capacity
    {From, enter, Name} when Capacity > 0 ->
      From ! {self(), ok},
      room([Name|Students], Capacity - 1, Queue);

  % student entering, at capacity
    {From, enter, Name} ->
     % From ! {self(), room_full, rand:uniform(5000)},
      %room(Students, Capacity, Queue),
      StuPosition = string:str(Queue, [Name]),
      StuSleep = StuPosition*1000,
      timer:sleep(StuSleep),
      inQueue = lists:member(Name,Queue),
      inFront = Name =:='Lab5':first(Queue),

      if
        inFront ->
          From ! {self(), ok},
          room([Name|Students], Capacity - 1, lists:delete(Name, Queue));
        inQueue ->
          From ! {self(), room_full, StuSleep},
          room(Students, Capacity, Queue);
        true ->
          io:format("~s could not enter and must wait ~B ms.~n", [Name, StuSleep]),
          timer:sleep(StuSleep),
          From ! {self(), room_full, StuSleep},
          room(Students, Capacity,Queue ++ [Name])
      end;

  % student leaving
    {From, leave, Name} ->
      % make sure they are already in the room
      case lists:member(Name, Students) of
        true ->
          From ! {self(), ok},
          room(lists:delete(Name, Students), Capacity + 1, Queue);
        false ->
          From ! {self(), not_found},
          room(Students, Capacity, Queue)
      end
  end.

studentWork(Name) ->
  SleepTime = rand:uniform(7000) + 3000,
  io:format("~s entered the Office and will work for ~B ms.~n", [Name, SleepTime]),
  timer:sleep(SleepTime).

student(Office, Name, Help) ->
  timer:sleep(rand:uniform(3000)),
  Office ! {self(), enter, Name},
  receive
  % Success; can enter room.
    {_, ok} ->
      studentWork(Name),
      Office ! {self(), leave, Name},
      io:format("~s left the Office.~n", [Name]);

  % Office is full; sleep and try again.
    {_, room_full, SleepTime} ->
      io:format("~s could not enter and must wait ~B ms.~n", [Name, SleepTime]),
      timer:sleep(SleepTime),
      student(Office, Name)
  end.

officedemo() ->
  R = spawn(office, room, [[], 3, []]), % start the room process with an empty list of students
  spawn(office, student, [R, "Ada"]),
  spawn(office, student, [R, "Barbara"]),
  spawn(office, student, [R, "Charlie"]),
  spawn(office, student, [R, "Donald"]),
  spawn(office, student, [R, "Elaine"]),
  spawn(office, student, [R, "Frank"]),
  spawn(office, student, [R, "George"]).