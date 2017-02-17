-module(lexer_test).
-compile([export_all]).
-include_lib("eunit/include/eunit.hrl").

-import(cgcids_lexer, [tokenize/1]).

empty_rule_test_() ->
    ?_assertEqual({ok, [], 1}, tokenize("")).

comment_test_() ->
    Comments = ["# blah",
                "#",
                "# alert (name:\"hi mom\") # known bad - missing a semi-colon",
                "# alert (name:\"foo match:\"; match:\"itch\";) foo  # known bad, extra content after the paren."],
    [?_assertMatch({ok, [], 1}, tokenize(X)) || X <- Comments].

quoted_string_test_() ->
    ?_assertMatch({ok, [{quoted_string, _}], 1},
                  tokenize("\"some quoted string\"")).

rule_words_test_() ->
    ?_assertMatch({ok, [
                       {admit, _},
                       {alert, _},
                       {block, _}
                       ], 1}, tokenize("admit alert block")).

match_replace_test_() ->
    Str = "alert (name:\"hi mom\"; match:\"hello there\"; skip: 4; match:\"bob\", 4; replace:\"wit\";)",
    ?_assertMatch(
       {ok,
        [{alert, _},
         {paren_open, _},
         {name, _}, {colon, _}, {quoted_string, _}, {semicolon, _},
         {match, _}, {colon, _}, {quoted_string, _}, {semicolon, _},
         {skip, _}, {colon, _}, {number, _}, {semicolon, _},
         {match, _}, {colon, _}, {quoted_string, _}, {comma, _},
         {number, _}, {semicolon, _},
         {replace, _}, {colon, _}, {quoted_string, _}, {semicolon, _},
         {paren_close, _}
        ],
        1}, tokenize(Str)).

block_directory_traversal_test_() ->
    Str = "block (name:\"ch_sec directory traversal\"; side:client; regex:\"^ch_sec \\x7c\\x2b\\x2b\\x7c\\x2b\\x2b\\x7c\";)",
    ?_assertMatch(
       {ok,
        [{block, _}, {paren_open, _},
         {name, _}, {colon, _}, {quoted_string, _}, {semicolon, _},
         {side, _}, {colon, _}, {client, _}, {semicolon, _},
         {regex, _}, {colon, _}, {quoted_string, _}, {semicolon, _},
         {paren_close, _}],
        1}, tokenize(Str)).

alert_state_test_() ->
    Str = "alert (name:\"test\"; state:not,foo_bar;)",
    ?_assertMatch(
       {ok,
        [{alert, _}, {paren_open, _},
         {name, _}, {colon, _}, {quoted_string, _}, {semicolon, _},
         {state, _}, {colon, _}, {not_, _}, {comma, _},
         {wordchar, <<"foo_bar">>}, {semicolon, _},
         {paren_close, _}],
        1}, tokenize(Str)).
