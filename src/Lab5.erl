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
-export([room/3,index_of/2,index_of/3,student/2,studentWork/1,officedemo/0]).



index_of(Value, List) ->
  index_of(Value, List, 1).
index_of(V, [V|T], N) ->
  N;
index_of(V, [_|T], N) ->
  index_of(V, T, N+1);
index_of(_, [], _) ->
  false
.

room(Students, Capacity, Queue) ->
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

      case lists:member(Name,Queue) of
        true ->
          %Student in the queue now check if they are the next one up
          io:format("~s could not enter and must wait ~B ms.~n", [Name, StuSleep]),
          timer:sleep(StuSleep),
          room(Students, Capacity,Queue);

        false ->
        %Student not in the queue append them in the queue
          io:format("~s could not enter and must wait ~B ms.~n", [Name, StuSleep]),
          timer:sleep(StuSleep),
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

student(Office, Name) ->
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