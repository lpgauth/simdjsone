%%%----------------------------------------------------------------------------
%%% @doc  Fast decoding of JSON using simdjson C++ library.
%%%
%%% By default JSON decoder uses the atom `null' to represent JSON nulls.
%%% To modify this behavior, set the following configuration option to another
%%% atom value (e.g. `nil' for Elixir):
%%% ```
%%% {simdjsone, [{null, nil}]}.
%%% '''
%%%
%%% See also [https://github.com/simdjson/simdjson]
%%% @end
%%%----------------------------------------------------------------------------
-module(simdjson).
-export([decode/1, parse/1, get/2, minify/1]).
-compile({no_auto_import, [get/2]}).

-on_load(init/0).

-define(APPNAME, simdjsone).
-define(LIBNAME, simdjsone).

-define(NOT_LOADED_ERROR,
  erlang:nif_error({not_loaded, [{module, ?MODULE}, {line, ?LINE}]})).

-ifdef(TEST).
-export([benchmark/1, benchmark/2]).
-include_lib("eunit/include/eunit.hrl").
-endif.

init() ->
    SoName = case code:priv_dir(?APPNAME) of
        {error, bad_name} ->
            case filelib:is_dir(filename:join(["..", priv])) of
                true ->
                    filename:join(["..", priv, ?LIBNAME]);
                _ ->
                    filename:join([priv, ?LIBNAME])
            end;
        Dir ->
            filename:join(Dir, ?LIBNAME)
    end,
    erlang:load_nif(SoName, [{null, null}]).

%% @doc Decode a JSON string or binary to a term representation of JSON.
-spec decode(binary()|list()|reference()) -> term() | no_return().
decode(_BinOrRef) ->
  ?NOT_LOADED_ERROR.

%% @doc Parse a JSON string or binary and save it in a resource for later access by `get/2'.
%% Returns a resource reference owned by the calling pid.
-spec parse(binary()) -> reference() | string() | no_return().
parse(_Bin) ->
  ?NOT_LOADED_ERROR.

%% @doc Find a given `Path' (which must start with a slash) in the JSON resource.
%% The resource reference must have been previously created by calling
%% `parse/1,2'.
-spec get(reference(), binary()) -> term() | no_return().
get(_Ref, Path) when is_binary(Path) ->
  ?NOT_LOADED_ERROR.

%% @doc Minify a JSON string or binary.
-spec minify(binary()|list()) -> {ok, binary()} | {error, binary()} | no_return().
minify(_BinOrStr) ->
  ?NOT_LOADED_ERROR.

-ifdef(EUNIT).

cached_decode_test_() ->
  {setup,
    fun() ->
      parse("{\"a\": 1, \"b\": 2, \"c\": {\"a\": 1, \"b\": 2, \"c\": [1,2,3]}}")
    end,
    fun(Ref) ->
      [
        ?_assertEqual([1,2,3], decode("[1,2,3]")),
        ?_assertEqual(#{<<"a">> => 1,<<"b">> => 2}, decode("{\"a\": 1, \"b\": 2}")),
        ?_assertEqual([1,2,3], get(Ref, "/c/c")),
        ?_assertEqual(1, get(Ref, "/c/c/0"))
      ]
    end
  }.

cached_decode_ownership_test_() ->
  {setup,
    fun() ->
      Pid = spawn(fun() -> receive {ready, P} -> P ! done end end),
      Ref = parse("{\"a\": 1, \"b\": 2, \"c\": {\"a\": 1, \"b\": 2, \"c\": [1,2,3]}}"),
      Pid ! {ready, self()},
      receive
        done -> Ref
      end
    end,
    fun(Ref) ->
      ?_assertEqual([1,2,3], get(Ref, "/c/c"))
      %%?_assertException(error, badarg, get(Ref, "/c/c"))
    end
  }.

minify_test_() ->
  [
    ?_assertEqual({ok, <<"[1,2,3]">>}, minify("[ 1, 2, 3 ]")),
    ?_assertEqual({ok, <<"[{\"a\":true,\"b\":false},2,3]">>}, minify("[ {\"a\": true, \"b\":  false}, 2, 3 ]"))
  ].

benchmark_test_() ->
  case os:getenv("MIX_ENV") of
    "test" ->
      ?_assert(true);
    _ ->
      ?_assertEqual(ok, benchmark([]))
  end.

benchmark(NameFuns) ->
  {ok, Dir} = file:get_cwd(),
  File1 = filename:join(Dir, "test/data/twitter.json"),
  benchmark(File1, NameFuns),
  File2 = filename:join(Dir, "test/data/esad.json"),
  benchmark(File2, NameFuns),
  File3 = filename:join(Dir, "test/data/small.json"),
  benchmark(File3, NameFuns),
  ok.

benchmark(File, NameFuns) ->
  {ok, Bin} = file:read_file(File),
  benchmark(100, Bin, NameFuns).

benchmark(N, Bin, NameFuns) ->
  erlang:group_leader(whereis(init), self()),
  io:format("\n=== Benchmark (file size: ~.1fK) ===\n", [byte_size(Bin) / 1024]),
  P = self(),
  L = [
    {"simdjsone", fun(B) -> simdjson:decode(B)             end},
    {"jiffy",     fun(B) -> jiffy:decode(B, [return_maps]) end},
    {"thoas",     fun(B) -> {ok, R} = thoas:decode(B),  R  end},
    {"euneus",    fun(B) -> {ok, R} = euneus:decode(B), R  end}
  ] ++ NameFuns,

  Tasks = [{Name, spawn(fun() ->
              P ! {Name, tc(N, fun() -> Fun(Bin) end)}
            end)} || {Name, Fun} <- L],

  K = length(Tasks),
  R = [receive Msg -> {ok, Msg} after 15000 -> {error, timeout} end || _ <- Tasks],
  M = lists:sort(fun({_, {T1, _}}, {_, {T2, _}}) -> T1 =< T2 end, [X || {ok, X} <- R]),
  [print(Nm, {T, S}) || {Nm, {T, S}} <- M],
  K = length(M),
  ok.

print(Fmt, {T, R}) ->
  case os:getenv("DEBUG") of
    V when V==false; V=="0" ->
      io:format("~12s: ~10.3fus\n", [Fmt, T]);
    _ ->
      io:format("~12s: ~10.3fus | Sample output: ~s\n", [Fmt, T, string:substr(lists:flatten(io_lib:format("~1024p", [R])), 1, 60)])
  end.

tc(N, F) when N > 0 ->
  time_it(fun() -> exit(call(N, N, F, erlang:system_time(microsecond))) end).

time_it(F) ->
  Pid  = spawn_opt(F, [{min_heap_size, 16384}]),
  MRef = erlang:monitor(process, Pid),
  receive
  {'DOWN', MRef, process, _, Result} -> Result
  end.

call(1, X, F, Time1) ->
  Res = (catch F()),
  return(X, Res, Time1, erlang:system_time(microsecond));
call(N, X, F, Time1) ->
  (catch F()),
  call(N-1, X, F, Time1).

return(N, Res, Time1, Time2) ->
  Int   = Time2 - Time1,
  {Int / N, Res}.

-endif.
