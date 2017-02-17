// Copyright 2011 Bobby Powers. All rights reserved.
// Use of this source code is governed by the MIT
// license that can be found in the LICENSE file.

// based off of Appendix A from http://dinosaur.compilertools.net/yacc/

%{

package main

import (
    "bufio"
    "fmt"
    "os"
    "container/list"
    "regexp"
    "log"
)

type RuleOptionStruct struct {
    option_type int
    value_str string
    value_int int 
    value_str2 string
    value_regex *regexp.Regexp
    OptionList *list.List
}

type RuleBaseStruct struct {
    rule_type int
    name string
    flush int
    rule_list *list.List
}

var line string     // current line
var lineno int      // current line number
var nerrors int

const (
    RULE_OPTION_SIDE = iota
    RULE_OPTION_REGEX
    RULE_OPTION_MATCH
    RULE_OPTION_SKIP
    RULE_OPTION_STATE
)

const (
    RULE_SIDE_CLIENT = 1
    RULE_SIDE_SERVER = 2
)

%}

// fields inside this union end up as the fields in a structure known
// as ${PREFIX}SymType, of which a reference is passed to the lexer.
%union{
    rule_type int
    rule_item int 
    fill_item int
    rule_side int
    rule_flush int
    rule_skip int
    rule_regex string
    rule_name string
    cur_string string
    cur_number int

    input_data struct {
        byte_array []byte
        byte_len int
    }

    rule_base RuleBaseStruct

    rule_match struct {
        match_string string
        depth int
        replace_string string
    }
    
    // rule_options string
    rule_options struct {
        rule_list *list.List
    }

    rule_state struct {
        state_type int
        value string
    }

}

// any non-terminal which returns a value needs a type, which is
// really a field name in the above union struct
%type <rule_base> expr
%type <rule_name> rule_name
%type <rule_base> rule_base
%type <rule_side> rule_side
%type <rule_flush> rule_flush
%type <rule_regex> rule_regex
%type <rule_match> rule_match
%type <rule_skip> rule_skip
%type <rule_options> rule_options
%type <rule_state> rule_state

// same for terminals
%token <input_data> STRING

%token <cur_number> NUMBER

%token <cur_string> WORDCHAR

%token RULE_ALERT
%token RULE_ADMIT
%token RULE_BLOCK

%token ATTRIBUTE_NAME
%token ATTRIBUTE_SIDE
%token ATTRIBUTE_REGEX
%token ATTRIBUTE_FLUSH

%token SIDE_CLIENT
%token SIDE_SERVER

%token ATTRIBUTE_MATCH
%token ATTRIBUTE_REPLACE

%token ATTRIBUTE_SKIP

%token ATTRIBUTE_STATE

%token ATTRIBUTE_STATE_SET
%token ATTRIBUTE_STATE_UNSET
%token ATTRIBUTE_STATE_IS
%token ATTRIBUTE_STATE_NOT

%type <rule_item> RULE_ALERT, RULE_ADMIT, RULE_BLOCK
%type <fill_item> ATTRIBUTE_NAME, ATTRIBUTE_SIDE, ATTRIBUTE_REGEX, ATTRIBUTE_FLUSH, ATTRIBUTE_MATCH, ATTRIBUTE_REPLACE, ATTRIBUTE_SKIP, ATTRIBUTE_STATE, ATTRIBUTE_STATE_SET, ATTRIBUTE_STATE_IS, ATTRIBUTE_STATE_NOT
%type <rule_side> SIDE_CLIENT, SIDE_SERVER
%type <cur_string> QUOTED_STRING, REGULAR_STRING
%%


input    : /* empty */
         | line
    ;

line    :   '\n'
        |    expr '\n'
            {
                AddIDSRule( $1.rule_type, $1.name, $1.flush, $1.rule_list )
            }
    ;

expr    :   RULE_ALERT '(' rule_base ')'
                {
                    $$.rule_type = RULE_ALERT
                    $$.name = $3.name
                    $$.flush = $3.flush
                    $$.rule_list = $3.rule_list 
                }
        |   RULE_ADMIT '(' rule_base ')'
                {
                    $$.rule_type = RULE_ADMIT
                    $$.name = $3.name
                    $$.flush = $3.flush
                    $$.rule_list = $3.rule_list 
                }
        |   RULE_BLOCK '(' rule_base ')'
                {
                    $$.rule_type = RULE_BLOCK
                    $$.name = $3.name
                    $$.flush = $3.flush
                    $$.rule_list = $3.rule_list 
                }
    ;

rule_base    :  rule_name rule_options
                {
                    $$.name = $1;
                    $$.rule_list = $2.rule_list
                }
             | rule_name rule_options rule_flush
                {
                    $$.name = $1;
                    $$.flush = $3;
                    $$.rule_list = $2.rule_list
                }
    ;

rule_options : rule_side
                {
                    $$.rule_list = list.New()
                    newRuleOption := &RuleOptionStruct{RULE_OPTION_SIDE, "", $1, "", nil, $$.rule_list}
                    $$.rule_list.PushBack(*newRuleOption)
                }
             |  rule_regex
                {
                    $$.rule_list = list.New()
                    compiled_regex, err := regexp.Compile($1)
                    if err != nil {
                        Errorf("Invalid regex expression %s", $1)
                        return -1
                    }
                    newRuleOption := &RuleOptionStruct{RULE_OPTION_REGEX, $1, 0, "", compiled_regex, $$.rule_list}
                    $$.rule_list.PushBack(*newRuleOption)
                }
             |  rule_match
                {
                    $$.rule_list = list.New()
                    newRuleOption := &RuleOptionStruct{RULE_OPTION_MATCH, $1.match_string, $1.depth, $1.replace_string, nil, $$.rule_list}
                    $$.rule_list.PushBack(*newRuleOption)
                }
             |  rule_skip
                {
                    $$.rule_list = list.New()
                    newRuleOption := &RuleOptionStruct{RULE_OPTION_SKIP, "", $1, "", nil, $$.rule_list}
                    $$.rule_list.PushBack(*newRuleOption)
                }
            |   rule_state
                {
                    $$.rule_list = list.New()
                    newRuleOption := &RuleOptionStruct{RULE_OPTION_STATE, $1.value, $1.state_type, "", nil, $$.rule_list}
                    $$.rule_list.PushBack(*newRuleOption)
                }
            |   rule_side rule_options
                {
                    newRuleOption := &RuleOptionStruct{RULE_OPTION_SIDE, "", $1, "", nil, $2.rule_list}
                    $2.rule_list.PushFront(*newRuleOption)
                    $$.rule_list = $2.rule_list 
                }
            |   rule_match rule_options
                {
                    newRuleOption := &RuleOptionStruct{RULE_OPTION_MATCH, $1.match_string, $1.depth, $1.replace_string, nil, $2.rule_list}
                    $2.rule_list.PushFront(*newRuleOption)
                    $$.rule_list = $2.rule_list 
                }
            |   rule_regex rule_options
                {
                    compiled_regex, err := regexp.Compile($1)
                    if err != nil {
                        Errorf("Invalid regex expression %s", $1)
                        return -1
                    }
                    newRuleOption := &RuleOptionStruct{RULE_OPTION_REGEX, $1, 0, "", compiled_regex, $2.rule_list}
                    $2.rule_list.PushFront(*newRuleOption)
                    $$.rule_list = $2.rule_list 
                }
            |   rule_skip rule_options
                {
                    newRuleOption := &RuleOptionStruct{RULE_OPTION_SKIP, "", $1, "", nil, $2.rule_list}
                    $2.rule_list.PushFront(*newRuleOption)
                    $$.rule_list = $2.rule_list 
                }
            |   rule_state rule_options
                {
                    newRuleOption := &RuleOptionStruct{RULE_OPTION_STATE, $1.value, $1.state_type, "", nil, $2.rule_list}
                    $2.rule_list.PushFront(*newRuleOption)
                    $$.rule_list = $2.rule_list 
                }
    ;

rule_name   :   ATTRIBUTE_NAME ':' QUOTED_STRING ';'
                {  
                    $$ = $3
                }
    ;

rule_side   :   ATTRIBUTE_SIDE ':' SIDE_SERVER ';'
                {
                    $$ = RULE_SIDE_SERVER
                }
            |   ATTRIBUTE_SIDE ':' SIDE_CLIENT ';'
                {
                    $$ = RULE_SIDE_CLIENT
                }
    ;

rule_regex  :   ATTRIBUTE_REGEX ':' QUOTED_STRING ';'
                {
                    $$ = $3
                }
    ;

rule_flush  :   ATTRIBUTE_FLUSH ':' SIDE_CLIENT ';'
                {
                    $$ = RULE_SIDE_CLIENT
                }
            |   ATTRIBUTE_FLUSH ':' SIDE_SERVER ';'
                {
                    $$ = RULE_SIDE_SERVER
                }
    ;

rule_match  :   ATTRIBUTE_MATCH ':' REGULAR_STRING ';'
                {
                    $$.match_string = $3
                }
            |   ATTRIBUTE_MATCH ':' REGULAR_STRING ',' NUMBER ';'
                {
                    $$.match_string = $3
                    $$.depth = $5
                }
            |   ATTRIBUTE_MATCH ':' REGULAR_STRING ';' ATTRIBUTE_REPLACE ':' QUOTED_STRING ';'
                {
                    $$.match_string = $3
                    $$.replace_string = $7
                }
            |   ATTRIBUTE_MATCH ':' REGULAR_STRING ',' NUMBER ';' ATTRIBUTE_REPLACE ':' QUOTED_STRING ';'
                {
                    $$.match_string = $3
                    $$.depth = $5
                    $$.replace_string = $9
                }
    ;

rule_skip   :   ATTRIBUTE_SKIP ':' NUMBER ';'
                {
                    $$ = $3
                }

rule_state  :   ATTRIBUTE_STATE ':' ATTRIBUTE_STATE_SET ',' WORDCHAR ';'
                {
                    $$.state_type = ATTRIBUTE_STATE_SET
                    $$.value = $5
                }
            |   ATTRIBUTE_STATE ':' ATTRIBUTE_STATE_UNSET ',' WORDCHAR ';'
                {
                    $$.state_type = ATTRIBUTE_STATE_UNSET
                    $$.value = $5
                }
            |   ATTRIBUTE_STATE ':' ATTRIBUTE_STATE_IS ',' WORDCHAR ';'
                {
                    $$.state_type = ATTRIBUTE_STATE_IS
                    $$.value = $5
                }
            |   ATTRIBUTE_STATE ':' ATTRIBUTE_STATE_NOT ',' WORDCHAR ';'
                {
                    $$.state_type = ATTRIBUTE_STATE_NOT
                    $$.value = $5
                }

QUOTED_STRING   : STRING
                {
                    // Try to mimic the IDS grammar
                    output_string := make([]byte, $1.byte_len)
                    out_pos := 0
                    for i := 0; i < $1.byte_len; i++ {
                        c := $1.byte_array[i]
                        if c == '\\' {
                            i++
                            if i >= $1.byte_len {
                                Errorf("Invalid regular string, missing character after \\")
                                return -1
                            }
                          
                            c = $1.byte_array[i]
                            if c == 'x' { 
                                i++
                                if i >= $1.byte_len {
                                    Errorf("Invalid string, missing \\x<digit>")
                                    return -1
                                }
                                c = $1.byte_array[i]
                                out_value := byte(0)
                                if c >= 'a' && c <= 'f' {
                                   out_value = (c-'a')+10
                                } else if c >= 'A' && c <= 'F' {
                                    out_value = (c-'A')+10
                                } else if c >= '0' && c <= '9' {
                                    out_value = (c-'0')
                                } else {
                                    Errorf("Invalid string, missing \\x<digit>")
                                    return -1
                                }

                                i++
                                if i >= $1.byte_len {
                                Errorf("Invalid string, missing \\x<digit>")
                                return -1
                                }

                                c = $1.byte_array[i]
                                if c >= 'a' && c <= 'f' {
                                   out_value *= 16
                                   out_value += (c-'a')+10
                                } else if c >= 'A' && c <= 'F' {
                                   out_value *= 16
                                    out_value += (c-'A')+10
                                } else if c >= '0' && c <= '9' {
                                    out_value *= 16
                                    out_value += (c-'0')
                                } else {
                                    i--
                                }

                                output_string[out_pos] = byte(out_value)
                                out_pos++
                            } else {
                                output_string[out_pos] = '\\'
                                out_pos++
                                output_string[out_pos] = c
                                out_pos++
                            }
                        } else {
                            output_string[out_pos] = c
                            out_pos++
                        }
                    }

                    $$ = string(output_string[:out_pos])
                    $$ = string($1.byte_array[:$1.byte_len])
                }

REGULAR_STRING  : STRING
                {
                    output_string := make([]byte, $1.byte_len)
                    out_pos := 0
                    for i := 0; i < $1.byte_len; i++ {
                        c := $1.byte_array[i]
                        if c == '\\' {
                            i++
                            if i >= $1.byte_len || $1.byte_array[i] != 'x' {
                                Errorf("Invalid string, missing \\x<digit>")
                                return -1
                            }
                           
                            i++
                            if i >= $1.byte_len {
                                Errorf("Invalid string, missing \\x<digit>")
                                return -1
                            }
                            c = $1.byte_array[i]
                            out_value := byte(0)
                            if c >= 'a' && c <= 'f' {
                               out_value = (c-'a')+10
                            } else if c >= 'A' && c <= 'F' {
                                out_value = (c-'A')+10
                            } else if c >= '0' && c <= '9' {
                                out_value = (c-'0')
                            } else {
                                Errorf("Invalid string, missing \\x<digit>")
                                return -1
                            }

                            i++
                            if i >= $1.byte_len {
                                Errorf("Invalid string, missing \\x<digit>")
                                return -1
                            }

                            c = $1.byte_array[i]
                            if c >= 'a' && c <= 'f' {
                               out_value *= 16
                               out_value += (c-'a')+10
                            } else if c >= 'A' && c <= 'F' {
                               out_value *= 16
                                out_value += (c-'A')+10
                            } else if c >= '0' && c <= '9' {
                                out_value *= 16
                                out_value += (c-'0')
                            } else {
                                i--
                            }

                            output_string[out_pos] = byte(out_value)
                            out_pos++

                        } else if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == ' ') {
                            output_string[out_pos] = c
                            out_pos++
                        } else {
                            Errorf("Invalid string, bad character %c", c)
                            return -1
                        }
                    }

                    $$ = string(output_string[:out_pos])
                }
    ;
%%      /*  start  of  programs  */

func (l *IDSLex) Error(s string) {
    Errorf("syntax error %s: ", s)
}

func Errorf(s string, v ...interface{}) {
    fmt.Printf("%v: %v\n\t", lineno, line)
    fmt.Printf(s, v...)
    fmt.Printf("\n")

    nerrors++
    if nerrors > 5 {
        fmt.Printf("too many errors\n")
        os.Exit(1)
    }
}

func ReadIDSRules(filename string) {
    // Open IDS rules file
    file, err := os.Open(filename)

    if err != nil {
        log.Fatal(err)
    }
    defer file.Close()

    fi := bufio.NewReader(file)

    lineno = 0
    nerrors = 0
    // Read in IDS rules (line by line)
    for {
        var ids_line string
        var line_status bool

        lineno++

        if ids_line, line_status = readline(fi); line_status {
            line = ids_line
            IDSParse(&IDSLex{S: ids_line})
        } else {
            break
        }
    }
}

func readline(fi *bufio.Reader) (string, bool) {
    s, err := fi.ReadString('\n')
    if err != nil {
        return "", false
    }
    return s, true
}

/*
func main() {
    fi := bufio.NewReader(os.NewFile(0, "stdin"))

    for {
        var eqn string
        var ok bool

        fmt.Printf("equation: ")
        if eqn, ok = readline(fi); ok {
            IDSParse(&IDSLex{S: eqn})
        } else {
            break
        }
    }
}

func readline(fi *bufio.Reader) (string, bool) {
    s, err := fi.ReadString('\n')
    if err != nil {
        return "", false
    }
    return s, true
}
*/
