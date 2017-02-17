Nonterminals

File
Rule
Action
NameClause
Options
MaybeFlush
Option
MatchOption
MatchString
SkipOption
RegexOption
SideOption
StateOption
StateVerb
StateObject
MaybeDepth
MaybeReplace

String
Number
.

Terminals

admit
alert
block
name
match
skip
regex
side
state
flush
client
server
set
unset
is
not_
replace
paren_open
paren_close
colon
comma
semicolon
number
quoted_string
newline
wordchar
.

Rootsymbol File.
Endsymbol '$end'.

File -> Rule newline File : ['$1' | '$3'].
File -> Rule : ['$1'].
File -> newline File : '$2'.
File -> '$empty' : [].

Rule ->
    Action paren_open NameClause Options MaybeFlush paren_close :
        {rule, '$1', '$3', '$4'}.

Action -> admit : admit.
Action -> alert : alert.
Action -> block : block.

NameClause ->
    name colon String semicolon :
        '$3'.

Options -> Option Options : ['$1' | '$2'].
Options -> Option : ['$1'].

Option -> MatchOption : '$1'.
Option -> SkipOption : '$1'.
Option -> RegexOption : '$1'.
Option -> SideOption : '$1'.
Option -> StateOption : '$1'.

MatchOption ->
    match colon MatchString MaybeDepth semicolon MaybeReplace :
        {match, '$3', '$4', '$6'}.

MatchString ->
    String : validate_match_string('$1').

MaybeDepth -> comma Number : {depth, '$2'}.
MaybeDepth -> '$empty' : {}.

MaybeReplace -> replace colon String semicolon : {replace, '$3'}.
MaybeReplace -> '$empty' : {}.

SkipOption ->
    skip colon Number semicolon :
        {skip, '$3'}.

RegexOption ->
    regex colon String semicolon :
        {regex, '$3'}.

SideOption -> side colon client semicolon : {side, client}.
SideOption -> side colon server semicolon : {side, server}.

StateOption ->
    state colon StateVerb comma StateObject semicolon :
        {state, '$3', '$5'}.

StateVerb -> set : set.
StateVerb -> unset : unset.
StateVerb -> is : is.
StateVerb -> not_ : not_.

MaybeFlush -> flush colon server semicolon : {flush, server}.
MaybeFlush -> flush colon client semicolon : {flush, client}.
MaybeFlush -> '$empty' : {}.

StateObject -> wordchar : parse_wordchar('$1').

String -> quoted_string : parse_str('$1').

Number -> number : parse_number('$1').

Erlang code.

-export([return_error/2]).

parse_wordchar({wordchar, Bin}) ->
    Bin.

parse_str({quoted_string, Bin}) ->
    WholeThing = binary_to_list(Bin),
    NoQuotes = string:strip(WholeThing, both, $"),
    Unescape = re:replace(NoQuotes, "\\\"", "\"", [global, {return, list}]),
    list_to_binary(Unescape).

parse_number({number, NumBin}) ->
    list_to_integer(binary_to_list(NumBin)).

validate_match_string(<<"">>) ->
    return_error(0, "too short matchstring");
validate_match_string(Bin) ->
    ReResult = re:run(Bin, "^(?:\\\\x[a-fA-F0-9]|[a-zA-Z0-9 ])+$"),
    case ReResult of
        {match, _Captured} -> Bin;
        nomatch ->
            return_error(
              iolist_to_binary(
                io_lib:format("invalid chars in matchstring ~p",
                           [Bin])), 0)
    end.
