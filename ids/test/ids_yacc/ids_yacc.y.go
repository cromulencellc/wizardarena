//line ids_yacc.y:8
package main

import __yyfmt__ "fmt"

//line ids_yacc.y:9
import (
	"bufio"
	"container/list"
	"fmt"
	"os"
	"regexp"
)

type RuleOptionStruct struct {
	option_type int
	value_str   string
	value_int   int
	value_str2  string
	value_regex *regexp.Regexp
	OptionList  *list.List
}

type RuleBaseStruct struct {
	rule_type int
	name      string
	flush     int
	rule_list *list.List
}

var line string // current line
var lineno int  // current line number
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

//line ids_yacc.y:56
type IDSSymType struct {
	yys        int
	rule_type  int
	rule_item  int
	fill_item  int
	rule_side  int
	rule_flush int
	rule_skip  int
	rule_regex string
	rule_name  string
	cur_string string
	cur_number int

	input_data struct {
		byte_array []byte
		byte_len   int
	}

	rule_base RuleBaseStruct

	rule_match struct {
		match_string   string
		depth          int
		replace_string string
	}

	// rule_options string
	rule_options struct {
		rule_list *list.List
	}

	rule_state struct {
		state_type int
		value      string
	}
}

const STRING = 57346
const NUMBER = 57347
const WORDCHAR = 57348
const RULE_ALERT = 57349
const RULE_ADMIT = 57350
const RULE_BLOCK = 57351
const ATTRIBUTE_NAME = 57352
const ATTRIBUTE_SIDE = 57353
const ATTRIBUTE_REGEX = 57354
const ATTRIBUTE_FLUSH = 57355
const SIDE_CLIENT = 57356
const SIDE_SERVER = 57357
const ATTRIBUTE_MATCH = 57358
const ATTRIBUTE_REPLACE = 57359
const ATTRIBUTE_SKIP = 57360
const ATTRIBUTE_STATE = 57361
const ATTRIBUTE_STATE_SET = 57362
const ATTRIBUTE_STATE_UNSET = 57363
const ATTRIBUTE_STATE_IS = 57364
const ATTRIBUTE_STATE_NOT = 57365

var IDSToknames = [...]string{
	"$end",
	"error",
	"$unk",
	"STRING",
	"NUMBER",
	"WORDCHAR",
	"RULE_ALERT",
	"RULE_ADMIT",
	"RULE_BLOCK",
	"ATTRIBUTE_NAME",
	"ATTRIBUTE_SIDE",
	"ATTRIBUTE_REGEX",
	"ATTRIBUTE_FLUSH",
	"SIDE_CLIENT",
	"SIDE_SERVER",
	"ATTRIBUTE_MATCH",
	"ATTRIBUTE_REPLACE",
	"ATTRIBUTE_SKIP",
	"ATTRIBUTE_STATE",
	"ATTRIBUTE_STATE_SET",
	"ATTRIBUTE_STATE_UNSET",
	"ATTRIBUTE_STATE_IS",
	"ATTRIBUTE_STATE_NOT",
	"'\\n'",
	"'('",
	"')'",
	"':'",
	"';'",
	"','",
}
var IDSStatenames = [...]string{}

const IDSEofCode = 1
const IDSErrCode = 2
const IDSInitialStackSize = 16

//line ids_yacc.y:481

/*  start  of  programs  */

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
		// log.Fatal(err)
		Log(LOG_INFO, "Rules file not found, using empty rule set.\n")
		return
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

//line yacctab:1
var IDSExca = [...]int{
	-1, 1,
	1, -1,
	-2, 0,
}

const IDSNprod = 37
const IDSPrivate = 57344

var IDSTokenNames []string
var IDSStates []string

const IDSLast = 89

var IDSAct = [...]int{

	44, 63, 64, 69, 68, 67, 66, 89, 86, 83,
	82, 81, 80, 79, 71, 70, 65, 62, 61, 60,
	57, 87, 18, 78, 46, 43, 42, 41, 40, 39,
	29, 5, 6, 7, 53, 54, 55, 56, 31, 30,
	11, 49, 34, 35, 36, 37, 38, 17, 3, 85,
	10, 9, 8, 24, 25, 72, 33, 12, 26, 14,
	27, 28, 58, 59, 48, 47, 77, 76, 15, 16,
	75, 74, 73, 52, 45, 51, 2, 1, 50, 84,
	23, 22, 21, 20, 32, 19, 13, 4, 88,
}
var IDSPact = [...]int{

	24, -1000, -1000, -1000, 28, 26, 25, 15, -1000, 49,
	49, 49, 21, 42, 3, 13, 12, -1000, 43, 42,
	42, 42, 42, 42, 2, 1, 0, -1, -2, 70,
	-1000, -1000, -1000, -3, -1000, -1000, -1000, -1000, -1000, 50,
	70, 71, 68, 14, -8, -1000, 48, -9, -10, -11,
	-27, -1000, -12, -23, -24, -25, -26, -1000, -13, -14,
	-1000, -1000, -1000, 38, 67, -1000, 65, 64, 61, 60,
	-1000, -1000, -4, -15, -16, -17, -18, -19, 70, 32,
	-1000, -1000, -1000, -1000, -20, -6, -1000, 70, -21, -1000,
}
var IDSPgo = [...]int{

	0, 87, 86, 57, 85, 84, 83, 82, 81, 22,
	80, 0, 78, 77, 76,
}
var IDSR1 = [...]int{

	0, 13, 13, 14, 14, 1, 1, 1, 3, 3,
	9, 9, 9, 9, 9, 9, 9, 9, 9, 9,
	2, 4, 4, 6, 5, 5, 7, 7, 7, 7,
	8, 10, 10, 10, 10, 11, 12,
}
var IDSR2 = [...]int{

	0, 0, 1, 1, 2, 4, 4, 4, 2, 3,
	1, 1, 1, 1, 1, 2, 2, 2, 2, 2,
	4, 4, 4, 4, 4, 4, 4, 6, 8, 10,
	4, 6, 6, 6, 6, 1, 1,
}
var IDSChk = [...]int{

	-1000, -13, -14, 24, -1, 7, 8, 9, 24, 25,
	25, 25, -3, -2, 10, -3, -3, 26, -9, -4,
	-6, -7, -8, -10, 11, 12, 16, 18, 19, 27,
	26, 26, -5, 13, -9, -9, -9, -9, -9, 27,
	27, 27, 27, 27, -11, 4, 27, 15, 14, -11,
	-12, 4, 5, 20, 21, 22, 23, 28, 14, 15,
	28, 28, 28, 28, 29, 28, 29, 29, 29, 29,
	28, 28, 17, 5, 6, 6, 6, 6, 27, 28,
	28, 28, 28, 28, -11, 17, 28, 27, -11, 28,
}
var IDSDef = [...]int{

	1, -2, 2, 3, 0, 0, 0, 0, 4, 0,
	0, 0, 0, 0, 0, 0, 0, 5, 8, 10,
	11, 12, 13, 14, 0, 0, 0, 0, 0, 0,
	6, 7, 9, 0, 15, 17, 16, 18, 19, 0,
	0, 0, 0, 0, 0, 35, 0, 0, 0, 0,
	0, 36, 0, 0, 0, 0, 0, 20, 0, 0,
	21, 22, 23, 26, 0, 30, 0, 0, 0, 0,
	24, 25, 0, 0, 0, 0, 0, 0, 0, 27,
	31, 32, 33, 34, 0, 0, 28, 0, 0, 29,
}
var IDSTok1 = [...]int{

	1, 3, 3, 3, 3, 3, 3, 3, 3, 3,
	24, 3, 3, 3, 3, 3, 3, 3, 3, 3,
	3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
	3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
	25, 26, 3, 3, 29, 3, 3, 3, 3, 3,
	3, 3, 3, 3, 3, 3, 3, 3, 27, 28,
}
var IDSTok2 = [...]int{

	2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
	12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
	22, 23,
}
var IDSTok3 = [...]int{
	0,
}

var IDSErrorMessages = [...]struct {
	state int
	token int
	msg   string
}{}

//line yaccpar:1

/*	parser for yacc output	*/

var (
	IDSDebug        = 0
	IDSErrorVerbose = false
)

type IDSLexer interface {
	Lex(lval *IDSSymType) int
	Error(s string)
}

type IDSParser interface {
	Parse(IDSLexer) int
	Lookahead() int
}

type IDSParserImpl struct {
	lval  IDSSymType
	stack [IDSInitialStackSize]IDSSymType
	char  int
}

func (p *IDSParserImpl) Lookahead() int {
	return p.char
}

func IDSNewParser() IDSParser {
	return &IDSParserImpl{}
}

const IDSFlag = -1000

func IDSTokname(c int) string {
	if c >= 1 && c-1 < len(IDSToknames) {
		if IDSToknames[c-1] != "" {
			return IDSToknames[c-1]
		}
	}
	return __yyfmt__.Sprintf("tok-%v", c)
}

func IDSStatname(s int) string {
	if s >= 0 && s < len(IDSStatenames) {
		if IDSStatenames[s] != "" {
			return IDSStatenames[s]
		}
	}
	return __yyfmt__.Sprintf("state-%v", s)
}

func IDSErrorMessage(state, lookAhead int) string {
	const TOKSTART = 4

	if !IDSErrorVerbose {
		return "syntax error"
	}

	for _, e := range IDSErrorMessages {
		if e.state == state && e.token == lookAhead {
			return "syntax error: " + e.msg
		}
	}

	res := "syntax error: unexpected " + IDSTokname(lookAhead)

	// To match Bison, suggest at most four expected tokens.
	expected := make([]int, 0, 4)

	// Look for shiftable tokens.
	base := IDSPact[state]
	for tok := TOKSTART; tok-1 < len(IDSToknames); tok++ {
		if n := base + tok; n >= 0 && n < IDSLast && IDSChk[IDSAct[n]] == tok {
			if len(expected) == cap(expected) {
				return res
			}
			expected = append(expected, tok)
		}
	}

	if IDSDef[state] == -2 {
		i := 0
		for IDSExca[i] != -1 || IDSExca[i+1] != state {
			i += 2
		}

		// Look for tokens that we accept or reduce.
		for i += 2; IDSExca[i] >= 0; i += 2 {
			tok := IDSExca[i]
			if tok < TOKSTART || IDSExca[i+1] == 0 {
				continue
			}
			if len(expected) == cap(expected) {
				return res
			}
			expected = append(expected, tok)
		}

		// If the default action is to accept or reduce, give up.
		if IDSExca[i+1] != 0 {
			return res
		}
	}

	for i, tok := range expected {
		if i == 0 {
			res += ", expecting "
		} else {
			res += " or "
		}
		res += IDSTokname(tok)
	}
	return res
}

func IDSlex1(lex IDSLexer, lval *IDSSymType) (char, token int) {
	token = 0
	char = lex.Lex(lval)
	if char <= 0 {
		token = IDSTok1[0]
		goto out
	}
	if char < len(IDSTok1) {
		token = IDSTok1[char]
		goto out
	}
	if char >= IDSPrivate {
		if char < IDSPrivate+len(IDSTok2) {
			token = IDSTok2[char-IDSPrivate]
			goto out
		}
	}
	for i := 0; i < len(IDSTok3); i += 2 {
		token = IDSTok3[i+0]
		if token == char {
			token = IDSTok3[i+1]
			goto out
		}
	}

out:
	if token == 0 {
		token = IDSTok2[1] /* unknown char */
	}
	if IDSDebug >= 3 {
		__yyfmt__.Printf("lex %s(%d)\n", IDSTokname(token), uint(char))
	}
	return char, token
}

func IDSParse(IDSlex IDSLexer) int {
	return IDSNewParser().Parse(IDSlex)
}

func (IDSrcvr *IDSParserImpl) Parse(IDSlex IDSLexer) int {
	var IDSn int
	var IDSVAL IDSSymType
	var IDSDollar []IDSSymType
	_ = IDSDollar // silence set and not used
	IDSS := IDSrcvr.stack[:]

	Nerrs := 0   /* number of errors */
	Errflag := 0 /* error recovery flag */
	IDSstate := 0
	IDSrcvr.char = -1
	IDStoken := -1 // IDSrcvr.char translated into internal numbering
	defer func() {
		// Make sure we report no lookahead when not parsing.
		IDSstate = -1
		IDSrcvr.char = -1
		IDStoken = -1
	}()
	IDSp := -1
	goto IDSstack

ret0:
	return 0

ret1:
	return 1

IDSstack:
	/* put a state and value onto the stack */
	if IDSDebug >= 4 {
		__yyfmt__.Printf("char %v in %v\n", IDSTokname(IDStoken), IDSStatname(IDSstate))
	}

	IDSp++
	if IDSp >= len(IDSS) {
		nyys := make([]IDSSymType, len(IDSS)*2)
		copy(nyys, IDSS)
		IDSS = nyys
	}
	IDSS[IDSp] = IDSVAL
	IDSS[IDSp].yys = IDSstate

IDSnewstate:
	IDSn = IDSPact[IDSstate]
	if IDSn <= IDSFlag {
		goto IDSdefault /* simple state */
	}
	if IDSrcvr.char < 0 {
		IDSrcvr.char, IDStoken = IDSlex1(IDSlex, &IDSrcvr.lval)
	}
	IDSn += IDStoken
	if IDSn < 0 || IDSn >= IDSLast {
		goto IDSdefault
	}
	IDSn = IDSAct[IDSn]
	if IDSChk[IDSn] == IDStoken { /* valid shift */
		IDSrcvr.char = -1
		IDStoken = -1
		IDSVAL = IDSrcvr.lval
		IDSstate = IDSn
		if Errflag > 0 {
			Errflag--
		}
		goto IDSstack
	}

IDSdefault:
	/* default state action */
	IDSn = IDSDef[IDSstate]
	if IDSn == -2 {
		if IDSrcvr.char < 0 {
			IDSrcvr.char, IDStoken = IDSlex1(IDSlex, &IDSrcvr.lval)
		}

		/* look through exception table */
		xi := 0
		for {
			if IDSExca[xi+0] == -1 && IDSExca[xi+1] == IDSstate {
				break
			}
			xi += 2
		}
		for xi += 2; ; xi += 2 {
			IDSn = IDSExca[xi+0]
			if IDSn < 0 || IDSn == IDStoken {
				break
			}
		}
		IDSn = IDSExca[xi+1]
		if IDSn < 0 {
			goto ret0
		}
	}
	if IDSn == 0 {
		/* error ... attempt to resume parsing */
		switch Errflag {
		case 0: /* brand new error */
			IDSlex.Error(IDSErrorMessage(IDSstate, IDStoken))
			Nerrs++
			if IDSDebug >= 1 {
				__yyfmt__.Printf("%s", IDSStatname(IDSstate))
				__yyfmt__.Printf(" saw %s\n", IDSTokname(IDStoken))
			}
			fallthrough

		case 1, 2: /* incompletely recovered error ... try again */
			Errflag = 3

			/* find a state where "error" is a legal shift action */
			for IDSp >= 0 {
				IDSn = IDSPact[IDSS[IDSp].yys] + IDSErrCode
				if IDSn >= 0 && IDSn < IDSLast {
					IDSstate = IDSAct[IDSn] /* simulate a shift of "error" */
					if IDSChk[IDSstate] == IDSErrCode {
						goto IDSstack
					}
				}

				/* the current p has no shift on "error", pop stack */
				if IDSDebug >= 2 {
					__yyfmt__.Printf("error recovery pops state %d\n", IDSS[IDSp].yys)
				}
				IDSp--
			}
			/* there is no state on the stack with an error shift ... abort */
			goto ret1

		case 3: /* no shift yet; clobber input char */
			if IDSDebug >= 2 {
				__yyfmt__.Printf("error recovery discards %s\n", IDSTokname(IDStoken))
			}
			if IDStoken == IDSEofCode {
				goto ret1
			}
			IDSrcvr.char = -1
			IDStoken = -1
			goto IDSnewstate /* try again in the same state */
		}
	}

	/* reduction by production IDSn */
	if IDSDebug >= 2 {
		__yyfmt__.Printf("reduce %v in:\n\t%v\n", IDSn, IDSStatname(IDSstate))
	}

	IDSnt := IDSn
	IDSpt := IDSp
	_ = IDSpt // guard against "declared and not used"

	IDSp -= IDSR2[IDSn]
	// IDSp is now the index of $0. Perform the default action. Iff the
	// reduced production is ε, $1 is possibly out of range.
	if IDSp+1 >= len(IDSS) {
		nyys := make([]IDSSymType, len(IDSS)*2)
		copy(nyys, IDSS)
		IDSS = nyys
	}
	IDSVAL = IDSS[IDSp+1]

	/* consult goto table to find next state */
	IDSn = IDSR1[IDSn]
	IDSg := IDSPgo[IDSn]
	IDSj := IDSg + IDSS[IDSp].yys + 1

	if IDSj >= IDSLast {
		IDSstate = IDSAct[IDSg]
	} else {
		IDSstate = IDSAct[IDSj]
		if IDSChk[IDSstate] != -IDSn {
			IDSstate = IDSAct[IDSg]
		}
	}
	// dummy call; replaced with literal code
	switch IDSnt {

	case 4:
		IDSDollar = IDSS[IDSpt-2 : IDSpt+1]
		//line ids_yacc.y:150
		{
			AddIDSRule(IDSDollar[1].rule_base.rule_type, IDSDollar[1].rule_base.name, IDSDollar[1].rule_base.flush, IDSDollar[1].rule_base.rule_list)
		}
	case 5:
		IDSDollar = IDSS[IDSpt-4 : IDSpt+1]
		//line ids_yacc.y:156
		{
			IDSVAL.rule_base.rule_type = RULE_ALERT
			IDSVAL.rule_base.name = IDSDollar[3].rule_base.name
			IDSVAL.rule_base.flush = IDSDollar[3].rule_base.flush
			IDSVAL.rule_base.rule_list = IDSDollar[3].rule_base.rule_list
		}
	case 6:
		IDSDollar = IDSS[IDSpt-4 : IDSpt+1]
		//line ids_yacc.y:163
		{
			IDSVAL.rule_base.rule_type = RULE_ADMIT
			IDSVAL.rule_base.name = IDSDollar[3].rule_base.name
			IDSVAL.rule_base.flush = IDSDollar[3].rule_base.flush
			IDSVAL.rule_base.rule_list = IDSDollar[3].rule_base.rule_list
		}
	case 7:
		IDSDollar = IDSS[IDSpt-4 : IDSpt+1]
		//line ids_yacc.y:170
		{
			IDSVAL.rule_base.rule_type = RULE_BLOCK
			IDSVAL.rule_base.name = IDSDollar[3].rule_base.name
			IDSVAL.rule_base.flush = IDSDollar[3].rule_base.flush
			IDSVAL.rule_base.rule_list = IDSDollar[3].rule_base.rule_list
		}
	case 8:
		IDSDollar = IDSS[IDSpt-2 : IDSpt+1]
		//line ids_yacc.y:179
		{
			IDSVAL.rule_base.name = IDSDollar[1].rule_name
			IDSVAL.rule_base.rule_list = IDSDollar[2].rule_options.rule_list
		}
	case 9:
		IDSDollar = IDSS[IDSpt-3 : IDSpt+1]
		//line ids_yacc.y:184
		{
			IDSVAL.rule_base.name = IDSDollar[1].rule_name
			IDSVAL.rule_base.flush = IDSDollar[3].rule_flush
			IDSVAL.rule_base.rule_list = IDSDollar[2].rule_options.rule_list
		}
	case 10:
		IDSDollar = IDSS[IDSpt-1 : IDSpt+1]
		//line ids_yacc.y:192
		{
			IDSVAL.rule_options.rule_list = list.New()
			newRuleOption := &RuleOptionStruct{RULE_OPTION_SIDE, "", IDSDollar[1].rule_side, "", nil, IDSVAL.rule_options.rule_list}
			IDSVAL.rule_options.rule_list.PushBack(*newRuleOption)
		}
	case 11:
		IDSDollar = IDSS[IDSpt-1 : IDSpt+1]
		//line ids_yacc.y:198
		{
			IDSVAL.rule_options.rule_list = list.New()
			compiled_regex, err := regexp.Compile(IDSDollar[1].rule_regex)
			if err != nil {
				Errorf("Invalid regex expression %s", IDSDollar[1].rule_regex)
				return -1
			}
			newRuleOption := &RuleOptionStruct{RULE_OPTION_REGEX, IDSDollar[1].rule_regex, 0, "", compiled_regex, IDSVAL.rule_options.rule_list}
			IDSVAL.rule_options.rule_list.PushBack(*newRuleOption)
		}
	case 12:
		IDSDollar = IDSS[IDSpt-1 : IDSpt+1]
		//line ids_yacc.y:209
		{
			IDSVAL.rule_options.rule_list = list.New()
			newRuleOption := &RuleOptionStruct{RULE_OPTION_MATCH, IDSDollar[1].rule_match.match_string, IDSDollar[1].rule_match.depth, IDSDollar[1].rule_match.replace_string, nil, IDSVAL.rule_options.rule_list}
			IDSVAL.rule_options.rule_list.PushBack(*newRuleOption)
		}
	case 13:
		IDSDollar = IDSS[IDSpt-1 : IDSpt+1]
		//line ids_yacc.y:215
		{
			IDSVAL.rule_options.rule_list = list.New()
			newRuleOption := &RuleOptionStruct{RULE_OPTION_SKIP, "", IDSDollar[1].rule_skip, "", nil, IDSVAL.rule_options.rule_list}
			IDSVAL.rule_options.rule_list.PushBack(*newRuleOption)
		}
	case 14:
		IDSDollar = IDSS[IDSpt-1 : IDSpt+1]
		//line ids_yacc.y:221
		{
			IDSVAL.rule_options.rule_list = list.New()
			newRuleOption := &RuleOptionStruct{RULE_OPTION_STATE, IDSDollar[1].rule_state.value, IDSDollar[1].rule_state.state_type, "", nil, IDSVAL.rule_options.rule_list}
			IDSVAL.rule_options.rule_list.PushBack(*newRuleOption)
		}
	case 15:
		IDSDollar = IDSS[IDSpt-2 : IDSpt+1]
		//line ids_yacc.y:227
		{
			newRuleOption := &RuleOptionStruct{RULE_OPTION_SIDE, "", IDSDollar[1].rule_side, "", nil, IDSDollar[2].rule_options.rule_list}
			IDSDollar[2].rule_options.rule_list.PushFront(*newRuleOption)
			IDSVAL.rule_options.rule_list = IDSDollar[2].rule_options.rule_list
		}
	case 16:
		IDSDollar = IDSS[IDSpt-2 : IDSpt+1]
		//line ids_yacc.y:233
		{
			newRuleOption := &RuleOptionStruct{RULE_OPTION_MATCH, IDSDollar[1].rule_match.match_string, IDSDollar[1].rule_match.depth, IDSDollar[1].rule_match.replace_string, nil, IDSDollar[2].rule_options.rule_list}
			IDSDollar[2].rule_options.rule_list.PushFront(*newRuleOption)
			IDSVAL.rule_options.rule_list = IDSDollar[2].rule_options.rule_list
		}
	case 17:
		IDSDollar = IDSS[IDSpt-2 : IDSpt+1]
		//line ids_yacc.y:239
		{
			compiled_regex, err := regexp.Compile(IDSDollar[1].rule_regex)
			if err != nil {
				Errorf("Invalid regex expression %s", IDSDollar[1].rule_regex)
				return -1
			}
			newRuleOption := &RuleOptionStruct{RULE_OPTION_REGEX, IDSDollar[1].rule_regex, 0, "", compiled_regex, IDSDollar[2].rule_options.rule_list}
			IDSDollar[2].rule_options.rule_list.PushFront(*newRuleOption)
			IDSVAL.rule_options.rule_list = IDSDollar[2].rule_options.rule_list
		}
	case 18:
		IDSDollar = IDSS[IDSpt-2 : IDSpt+1]
		//line ids_yacc.y:250
		{
			newRuleOption := &RuleOptionStruct{RULE_OPTION_SKIP, "", IDSDollar[1].rule_skip, "", nil, IDSDollar[2].rule_options.rule_list}
			IDSDollar[2].rule_options.rule_list.PushFront(*newRuleOption)
			IDSVAL.rule_options.rule_list = IDSDollar[2].rule_options.rule_list
		}
	case 19:
		IDSDollar = IDSS[IDSpt-2 : IDSpt+1]
		//line ids_yacc.y:256
		{
			newRuleOption := &RuleOptionStruct{RULE_OPTION_STATE, IDSDollar[1].rule_state.value, IDSDollar[1].rule_state.state_type, "", nil, IDSDollar[2].rule_options.rule_list}
			IDSDollar[2].rule_options.rule_list.PushFront(*newRuleOption)
			IDSVAL.rule_options.rule_list = IDSDollar[2].rule_options.rule_list
		}
	case 20:
		IDSDollar = IDSS[IDSpt-4 : IDSpt+1]
		//line ids_yacc.y:264
		{
			IDSVAL.rule_name = IDSDollar[3].cur_string
		}
	case 21:
		IDSDollar = IDSS[IDSpt-4 : IDSpt+1]
		//line ids_yacc.y:270
		{
			IDSVAL.rule_side = RULE_SIDE_SERVER
		}
	case 22:
		IDSDollar = IDSS[IDSpt-4 : IDSpt+1]
		//line ids_yacc.y:274
		{
			IDSVAL.rule_side = RULE_SIDE_CLIENT
		}
	case 23:
		IDSDollar = IDSS[IDSpt-4 : IDSpt+1]
		//line ids_yacc.y:280
		{
			IDSVAL.rule_regex = IDSDollar[3].cur_string
		}
	case 24:
		IDSDollar = IDSS[IDSpt-4 : IDSpt+1]
		//line ids_yacc.y:286
		{
			IDSVAL.rule_flush = RULE_SIDE_CLIENT
		}
	case 25:
		IDSDollar = IDSS[IDSpt-4 : IDSpt+1]
		//line ids_yacc.y:290
		{
			IDSVAL.rule_flush = RULE_SIDE_SERVER
		}
	case 26:
		IDSDollar = IDSS[IDSpt-4 : IDSpt+1]
		//line ids_yacc.y:296
		{
			IDSVAL.rule_match.match_string = IDSDollar[3].cur_string
		}
	case 27:
		IDSDollar = IDSS[IDSpt-6 : IDSpt+1]
		//line ids_yacc.y:300
		{
			IDSVAL.rule_match.match_string = IDSDollar[3].cur_string
			IDSVAL.rule_match.depth = IDSDollar[5].cur_number
		}
	case 28:
		IDSDollar = IDSS[IDSpt-8 : IDSpt+1]
		//line ids_yacc.y:305
		{
			IDSVAL.rule_match.match_string = IDSDollar[3].cur_string
			IDSVAL.rule_match.replace_string = IDSDollar[7].cur_string
		}
	case 29:
		IDSDollar = IDSS[IDSpt-10 : IDSpt+1]
		//line ids_yacc.y:310
		{
			IDSVAL.rule_match.match_string = IDSDollar[3].cur_string
			IDSVAL.rule_match.depth = IDSDollar[5].cur_number
			IDSVAL.rule_match.replace_string = IDSDollar[9].cur_string
		}
	case 30:
		IDSDollar = IDSS[IDSpt-4 : IDSpt+1]
		//line ids_yacc.y:318
		{
			IDSVAL.rule_skip = IDSDollar[3].cur_number
		}
	case 31:
		IDSDollar = IDSS[IDSpt-6 : IDSpt+1]
		//line ids_yacc.y:323
		{
			IDSVAL.rule_state.state_type = ATTRIBUTE_STATE_SET
			IDSVAL.rule_state.value = IDSDollar[5].cur_string
		}
	case 32:
		IDSDollar = IDSS[IDSpt-6 : IDSpt+1]
		//line ids_yacc.y:328
		{
			IDSVAL.rule_state.state_type = ATTRIBUTE_STATE_UNSET
			IDSVAL.rule_state.value = IDSDollar[5].cur_string
		}
	case 33:
		IDSDollar = IDSS[IDSpt-6 : IDSpt+1]
		//line ids_yacc.y:333
		{
			IDSVAL.rule_state.state_type = ATTRIBUTE_STATE_IS
			IDSVAL.rule_state.value = IDSDollar[5].cur_string
		}
	case 34:
		IDSDollar = IDSS[IDSpt-6 : IDSpt+1]
		//line ids_yacc.y:338
		{
			IDSVAL.rule_state.state_type = ATTRIBUTE_STATE_NOT
			IDSVAL.rule_state.value = IDSDollar[5].cur_string
		}
	case 35:
		IDSDollar = IDSS[IDSpt-1 : IDSpt+1]
		//line ids_yacc.y:344
		{
			// Try to mimic the IDS grammar
			output_string := make([]byte, IDSDollar[1].input_data.byte_len)
			out_pos := 0
			for i := 0; i < IDSDollar[1].input_data.byte_len; i++ {
				c := IDSDollar[1].input_data.byte_array[i]
				if c == '\\' {
					i++
					if i >= IDSDollar[1].input_data.byte_len {
						Errorf("Invalid regular string, missing character after \\")
						return -1
					}

					c = IDSDollar[1].input_data.byte_array[i]
					if c == 'x' {
						i++
						if i >= IDSDollar[1].input_data.byte_len {
							Errorf("Invalid string, missing \\x<digit>")
							return -1
						}
						c = IDSDollar[1].input_data.byte_array[i]
						out_value := byte(0)
						if c >= 'a' && c <= 'f' {
							out_value = (c - 'a') + 10
						} else if c >= 'A' && c <= 'F' {
							out_value = (c - 'A') + 10
						} else if c >= '0' && c <= '9' {
							out_value = (c - '0')
						} else {
							Errorf("Invalid string, missing \\x<digit>")
							return -1
						}

						i++
						if i >= IDSDollar[1].input_data.byte_len {
							Errorf("Invalid string, missing \\x<digit>")
							return -1
						}

						c = IDSDollar[1].input_data.byte_array[i]
						if c >= 'a' && c <= 'f' {
							out_value *= 16
							out_value += (c - 'a') + 10
						} else if c >= 'A' && c <= 'F' {
							out_value *= 16
							out_value += (c - 'A') + 10
						} else if c >= '0' && c <= '9' {
							out_value *= 16
							out_value += (c - '0')
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

			IDSVAL.cur_string = string(output_string[:out_pos])
			IDSVAL.cur_string = string(IDSDollar[1].input_data.byte_array[:IDSDollar[1].input_data.byte_len])
		}
	case 36:
		IDSDollar = IDSS[IDSpt-1 : IDSpt+1]
		//line ids_yacc.y:416
		{
			output_string := make([]byte, IDSDollar[1].input_data.byte_len)
			out_pos := 0
			for i := 0; i < IDSDollar[1].input_data.byte_len; i++ {
				c := IDSDollar[1].input_data.byte_array[i]
				if c == '\\' {
					i++
					if i >= IDSDollar[1].input_data.byte_len || IDSDollar[1].input_data.byte_array[i] != 'x' {
						Errorf("Invalid string, missing \\x<digit>")
						return -1
					}

					i++
					if i >= IDSDollar[1].input_data.byte_len {
						Errorf("Invalid string, missing \\x<digit>")
						return -1
					}
					c = IDSDollar[1].input_data.byte_array[i]
					out_value := byte(0)
					if c >= 'a' && c <= 'f' {
						out_value = (c - 'a') + 10
					} else if c >= 'A' && c <= 'F' {
						out_value = (c - 'A') + 10
					} else if c >= '0' && c <= '9' {
						out_value = (c - '0')
					} else {
						Errorf("Invalid string, missing \\x<digit>")
						return -1
					}

					i++
					if i >= IDSDollar[1].input_data.byte_len {
						Errorf("Invalid string, missing \\x<digit>")
						return -1
					}

					c = IDSDollar[1].input_data.byte_array[i]
					if c >= 'a' && c <= 'f' {
						out_value *= 16
						out_value += (c - 'a') + 10
					} else if c >= 'A' && c <= 'F' {
						out_value *= 16
						out_value += (c - 'A') + 10
					} else if c >= '0' && c <= '9' {
						out_value *= 16
						out_value += (c - '0')
					} else {
						i--
					}

					output_string[out_pos] = byte(out_value)
					out_pos++

				} else if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == ' ' {
					output_string[out_pos] = c
					out_pos++
				} else {
					Errorf("Invalid string, bad character %c", c)
					return -1
				}
			}

			IDSVAL.cur_string = string(output_string[:out_pos])
		}
	}
	goto IDSstack /* stack new state and value */
}
