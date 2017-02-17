-module(parser_test).
-compile([export_all]).
-include_lib("eunit/include/eunit.hrl").

-import(cgcids_lexer, [tokenize/1]).
-import(cgcids_parser, [parse/1]).

empty_file_test_() ->
    ?_assertEqual({ok, []}, p("")).

commented_file_test_() ->
    ?_assertEqual({ok, []}, p("# asdf")).

foo_match_test_() ->
    ?_assertEqual({ok, [
                        {rule, 
                         alert,
                         <<"test">>,
                         [{match, <<"foo">>, {}, {}}]}
                       ]}, p("alert (name:\"test\"; match:\"foo\";)")).

p(Str) ->
    {ok, Toks, _LineNo} = tokenize(Str),
    parse(Toks).
