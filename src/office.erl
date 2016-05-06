%%%-------------------------------------------------------------------
%%% @author Jeimmi
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. May 2016 12:43 PM
%%%-------------------------------------------------------------------
-module(office).
-author("Jeimmi").

-compile(export_all).

room(Students, Capacity, Queue,Helping) ->
  receive
  % student entering, not at capacity
    {From, enter, Name} when Capacity > 0 ->
      %StuPosition = string:str(Queue, Name),

      InQueue = lists:member(Name,Queue),
      case  length(Queue) =:=0 of
        true ->
          From ! {self(), ok},
          room([Name|Students], Capacity - 1, Queue, Helping);
        false ->
          case Name =:=hd(Queue) of
            true->
              From ! {self(), ok},
              room([Name|Students], Capacity - 1, tl(Queue), Helping);
            false ->
              case InQueue of
                 true ->
                   From ! {self(), room_full,((index_of(Name,Queue)+1)*1000)},
                   room(Students, Capacity, Queue, Helping);
                false ->
                  From ! {self(), room_full, (length(Queue)+1)*1000},
                  room(Students, Capacity,Queue ++ [Name], Helping)
              end
          end
      end;



  % student entering, at capacity
    {From, enter, Name} ->
      %room(Students, Capacity, Queue),
      %Taking into account that student is in queue BECAREFUL
%%      StuPosition = string:str(Queue, Name),

%%      StuPosition = index_of(Name,Queue),
%%      StuSleep = (StuPosition+1)*1000,
      InQueue = lists:member(Name,Queue),

      if
        InQueue ->
          From ! {self(), room_full, ((index_of(Name,Queue)+1)*1000)},
          room(Students, Capacity, Queue,Helping);
        true ->

          io:format("~s wait ~B ms.~n", [Name, (length(Queue)+1)*1000]),
          %Room doesnt sleep. The student sleeps so you send them the sleeping number
          %timer:sleep(StuSleep),
          From ! {self(), room_full, (length(Queue)+1)*1000},
          room(Students, Capacity,Queue ++ [Name],Helping)
      end;


    %student asking for help
    {From, help_me} when Helping =:= false ->
      %then send ok back to the student
      From ! {self(),ok},
      room(Students, Capacity,Queue,true);
    {From, help_me}->
      From ! {self(),busy},
      room(Students, Capacity,Queue,Helping);


    {From, thanks}->
      room(Students, Capacity,Queue,false);

  % student leaving
    {From, leave, Name} ->
      % make sure they are already in the room
      case lists:member(Name, Students) of
        true ->
          From ! {self(), ok},
          room(lists:delete(Name, Students), Capacity + 1, Queue, Helping);
        false ->
          From ! {self(), not_found},
          room(Students, Capacity, Queue, Helping)
      end
  end.

studentWork(Name) ->
  SleepTime = rand:uniform(5000)+5000,
  io:format("~s entered the Office and will work for ~B ms.~n", [Name, SleepTime]),

  timer:sleep(SleepTime).

student(Office, Name) ->
  timer:sleep(rand:uniform(3000)),

  Office ! {self(), enter, Name},
  receive
  % Success; can enter room.
    {_, ok} ->
      studentWork(Name),
      busy(Office,Name),
      Office ! {self(), leave, Name},
      io:format("~s left the Office.~n", [Name]);

  % Office is full; sleep and try again.
    {_, room_full, SleepTime} ->
      io:format("~s could not enter and must wait ~B ms.~n", [Name, SleepTime]),
      timer:sleep(SleepTime),
      student(Office, Name)

  end.


busy(Office,Name) ->
  SleepTime = rand:uniform(5000)+5000,
  Office ! {self(), help_me},
  receive
    {_,busy}->
      timer:sleep(1000),
      io:format("~s wanted help but the instructor was busy ~B ms.~n", [Name, SleepTime]),
      busy(Office,Name);
    {_,ok} ->
      io:format("~s Received help.~n", [Name]),
      timer:sleep(SleepTime),
      Office ! {self(), thanks}
  end.

index_of(Value, List) ->
  index_of(Value, List, 1).
index_of(V, [V|T], N) ->
  N;
index_of(V, [_|T], N) ->
  index_of(V, T, N+1);
index_of(_, [], _) ->
  false.



officedemo() ->
  R = spawn(office, room, [[], 3,[],false]), % start the room process with an empty list of students
  spawn(office, student, [R, "Ada"]),
  spawn(office, student, [R, "Barbara"]),
  spawn(office, student, [R, "Charlie"]),
  spawn(office, student, [R, "Donald"]),
  spawn(office, student, [R, "Elaine"]),
  spawn(office, student, [R, "Frank"]),
  spawn(office, student, [R, "George"]).