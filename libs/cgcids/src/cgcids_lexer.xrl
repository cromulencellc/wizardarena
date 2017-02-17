Definitions.

% rule types
ADMIT = admit
ALERT = alert
BLOCK = block

% rule elements
NAME = name
MATCH = match
SKIP = skip
REGEX = regex
SIDE = side
STATE = state
FLUSH = flush

% sides
CLIENT = client
SERVER = server

% state changes
SET = set
UNSET = unset
IS = is
NOT = not

% match parts
REPLACE = replace

% flush parts - just server and client again

PAREN_OPEN  = \(
PAREN_CLOSE = \)

SEMICOLON = \;
COMMA = (,)
COLON = (:)

% complex stuff

COMMENT = (\s*[#][^\n]*)
NUMBER = ([0-9]+)
QUOTED_STRING = ("([^\"\\]|(\\.))+")
% "

WORDCHAR = ([0-9A-Za-z_])+
WHITESPACE = \s+
NEWLINE = \n

Rules.

{ADMIT} : {token, {admit, <<"admit">>}}.
{ALERT} : {token, {alert, <<"alert">>}}.
{BLOCK} : {token, {block, <<"block">>}}.

{NAME} : {token, {name, <<"name">>}}.
{MATCH} : {token, {match, <<"match">>}}.
{SKIP} : {token, {skip, <<"skip">>}}.
{REGEX} : {token, {regex, <<"regex">>}}.
{SIDE} : {token, {side, <<"side">>}}.
{STATE} : {token, {state, <<"state">>}}.
{FLUSH} : {token, {flush, <<"flush">>}}.

{CLIENT} : {token, {client, <<"client">>}}.
{SERVER} : {token, {server, <<"server">>}}.

{SET} : {token, {set, <<"set">>}}.
{UNSET} : {token, {unset, <<"unset">>}}.
{IS} : {token, {is, <<"is">>}}.
{NOT} : {token, {not_, <<"not">>}}.

{REPLACE} : {token, {replace, <<"replace">>}}.

{PAREN_OPEN} : {token, {paren_open, <<"(">>}}.
{PAREN_CLOSE} : {token, {paren_close, <<")">>}}.

{COLON} : {token, {colon, <<":">>}}.
{COMMA} : {token, {comma, <<",">>}}.
{SEMICOLON} : {token, {semicolon, <<";">>}}.

{COMMENT} : skip_token.
{NUMBER} : {token, {number, list_to_binary(TokenChars)}}.
{QUOTED_STRING} : {token, {quoted_string, list_to_binary(TokenChars)}}.

{WORDCHAR} : {token, {wordchar, list_to_binary(TokenChars)}}.
{WHITESPACE} : skip_token.
{NEWLINE} : {token, {newline, <<"\n">>}}.

Erlang code.

-export([tokenize/1]).

tokenize(Str) when is_list(Str) ->
    string(Str);
tokenize(Bin) when is_binary(Bin) ->
    string(binary_to_list(Bin)).
