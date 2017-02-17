-module(integration_test).
-compile([export_all]).
-include_lib("eunit/include/eunit.hrl").

-import(cgcids_lexer, [tokenize/1]).
-import(cgcids_parser, [parse/1]).

failing_fixtures_test_() ->
    [?_assertNot(p(read(X))) || X <- enumerate_fixtures("failures")].

passing_fixtures_test_() ->
    [?_assert(p(read(X))) || X <- enumerate_fixtures("passes")].

enumerate_fixtures(FixtureDirName) ->
    Me = ?FILE,
    Here = filename:dirname(Me),
    FixtureDir = filename:join([Here, FixtureDirName]),
    {ok, FixtureNames} = file:list_dir(FixtureDir),
    [filename:join(FixtureDir, X) || X <- FixtureNames].

read(Filename) ->
    {ok, Data} = file:read_file(Filename),
    Data.

p(Line) ->
    %% io:format("~p~n", [Line]),
    case tokenize(Line) of
        {ok, Tokens, _LineNo} ->
            actually_parse(Tokens);
        _ ->
            false
    end.

actually_parse(Tokens) ->
    %% io:format("~p~n~p~n", [Tokens, parse(Tokens)]),
    case parse(Tokens) of
        {ok, Tree} ->
            true;
        _ ->
            false
    end.
