// CAUTION: Generated file - DO NOT EDIT.

package main

import (
	"fmt"
)

type IDSLex struct {
	S   string
	buf string
	pos int

	/*
	   ids_rule struct {
	       rule_type int
	       name string
	       side int
	       flush int
	       regex string
	   }
	*/
}

func (this *IDSLex) peek() (bret byte) {
	if this.pos < len(this.S) {
		bret = byte(this.S[this.pos])
	} else {
		bret = 0
	}
	return
}

func (this *IDSLex) back() (bret byte) {
	if this.pos < len(this.S) {
		bret = byte(this.S[this.pos])
		this.buf += string(this.S[this.pos])
	} else {
		bret = 0
	}
	this.pos -= 1
	return
}

func (this *IDSLex) next() (bret byte) {
	if this.pos < len(this.S) {
		bret = byte(this.S[this.pos])
		this.buf += string(this.S[this.pos])
	} else {
		bret = 0
	}
	this.pos += 1
	return
}

func (this *IDSLex) Lex(lval *IDSSymType) (ret int) {
	var c byte = ' '

yystate0:

	// fmt.Printf("c=%c\n", c)
	/*
	   if nil!=this.buf {
	               this.buf = this.buf[len(this.buf)-1:]
	           }
	*/
	// "#"(.*[ \t]*.*)*[\n]+

	goto yystart1

	goto yystate0 // silence unused label error
	goto yystate1 // silence unused label error
yystate1:
	c = this.next()
yystart1:
	switch {
	default:
		goto yyabort
	case c == '"':
		goto yystate3
	case c == '#':
		goto yystate4
	case c == '\t' || c == ' ':
		goto yystate2
	case c == 'a':
		goto yystate7
	case c == 'b':
		goto yystate16
	case c == 'c':
		goto yystate21
	case c == 'f':
		goto yystate27
	case c == 'i':
		goto yystate32
	case c == 'm':
		goto yystate34
	case c == 'n':
		goto yystate39
	case c == 'r':
		goto yystate45
	case c == 's':
		goto yystate55
	case c == 'u':
		goto yystate72
	case c >= '0' && c <= '9':
		goto yystate5
	case c >= 'A' && c <= 'Z' || c == 'd' || c == 'e' || c == 'g' || c == 'h' || c >= 'j' && c <= 'l' || c >= 'o' && c <= 'q' || c == 't' || c >= 'v' && c <= 'z':
		goto yystate6
	}

yystate2:
	c = this.next()
	switch {
	default:
		goto yyrule2
	case c == '\t' || c == ' ':
		goto yystate2
	}

yystate3:
	c = this.next()
	goto yyrule22

yystate4:
	c = this.next()
	switch {
	default:
		goto yyrule1
	case c >= '\x01' && c <= '\t' || c >= '\v' && c <= 'ÿ':
		goto yystate4
	}

yystate5:
	c = this.next()
	goto yyrule21

yystate6:
	c = this.next()
	goto yyrule20

yystate7:
	c = this.next()
	switch {
	default:
		goto yyrule20
	case c == 'd':
		goto yystate8
	case c == 'l':
		goto yystate12
	}

yystate8:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'm':
		goto yystate9
	}

yystate9:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'i':
		goto yystate10
	}

yystate10:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 't':
		goto yystate11
	}

yystate11:
	c = this.next()
	goto yyrule4

yystate12:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'e':
		goto yystate13
	}

yystate13:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'r':
		goto yystate14
	}

yystate14:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 't':
		goto yystate15
	}

yystate15:
	c = this.next()
	goto yyrule3

yystate16:
	c = this.next()
	switch {
	default:
		goto yyrule20
	case c == 'l':
		goto yystate17
	}

yystate17:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'o':
		goto yystate18
	}

yystate18:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'c':
		goto yystate19
	}

yystate19:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'k':
		goto yystate20
	}

yystate20:
	c = this.next()
	goto yyrule5

yystate21:
	c = this.next()
	switch {
	default:
		goto yyrule20
	case c == 'l':
		goto yystate22
	}

yystate22:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'i':
		goto yystate23
	}

yystate23:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'e':
		goto yystate24
	}

yystate24:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'n':
		goto yystate25
	}

yystate25:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 't':
		goto yystate26
	}

yystate26:
	c = this.next()
	goto yyrule10

yystate27:
	c = this.next()
	switch {
	default:
		goto yyrule20
	case c == 'l':
		goto yystate28
	}

yystate28:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'u':
		goto yystate29
	}

yystate29:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 's':
		goto yystate30
	}

yystate30:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'h':
		goto yystate31
	}

yystate31:
	c = this.next()
	goto yyrule9

yystate32:
	c = this.next()
	switch {
	default:
		goto yyrule20
	case c == 's':
		goto yystate33
	}

yystate33:
	c = this.next()
	goto yyrule18

yystate34:
	c = this.next()
	switch {
	default:
		goto yyrule20
	case c == 'a':
		goto yystate35
	}

yystate35:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 't':
		goto yystate36
	}

yystate36:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'c':
		goto yystate37
	}

yystate37:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'h':
		goto yystate38
	}

yystate38:
	c = this.next()
	goto yyrule12

yystate39:
	c = this.next()
	switch {
	default:
		goto yyrule20
	case c == 'a':
		goto yystate40
	case c == 'o':
		goto yystate43
	}

yystate40:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'm':
		goto yystate41
	}

yystate41:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'e':
		goto yystate42
	}

yystate42:
	c = this.next()
	goto yyrule6

yystate43:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 't':
		goto yystate44
	}

yystate44:
	c = this.next()
	goto yyrule19

yystate45:
	c = this.next()
	switch {
	default:
		goto yyrule20
	case c == 'e':
		goto yystate46
	}

yystate46:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'g':
		goto yystate47
	case c == 'p':
		goto yystate50
	}

yystate47:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'e':
		goto yystate48
	}

yystate48:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'x':
		goto yystate49
	}

yystate49:
	c = this.next()
	goto yyrule8

yystate50:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'l':
		goto yystate51
	}

yystate51:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'a':
		goto yystate52
	}

yystate52:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'c':
		goto yystate53
	}

yystate53:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'e':
		goto yystate54
	}

yystate54:
	c = this.next()
	goto yyrule13

yystate55:
	c = this.next()
	switch {
	default:
		goto yyrule20
	case c == 'e':
		goto yystate56
	case c == 'i':
		goto yystate62
	case c == 'k':
		goto yystate65
	case c == 't':
		goto yystate68
	}

yystate56:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'r':
		goto yystate57
	case c == 't':
		goto yystate61
	}

yystate57:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'v':
		goto yystate58
	}

yystate58:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'e':
		goto yystate59
	}

yystate59:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'r':
		goto yystate60
	}

yystate60:
	c = this.next()
	goto yyrule11

yystate61:
	c = this.next()
	goto yyrule16

yystate62:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'd':
		goto yystate63
	}

yystate63:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'e':
		goto yystate64
	}

yystate64:
	c = this.next()
	goto yyrule7

yystate65:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'i':
		goto yystate66
	}

yystate66:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'p':
		goto yystate67
	}

yystate67:
	c = this.next()
	goto yyrule14

yystate68:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'a':
		goto yystate69
	}

yystate69:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 't':
		goto yystate70
	}

yystate70:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'e':
		goto yystate71
	}

yystate71:
	c = this.next()
	goto yyrule15

yystate72:
	c = this.next()
	switch {
	default:
		goto yyrule20
	case c == 'n':
		goto yystate73
	}

yystate73:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 's':
		goto yystate74
	}

yystate74:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 'e':
		goto yystate75
	}

yystate75:
	c = this.next()
	switch {
	default:
		goto yyabort
	case c == 't':
		goto yystate76
	}

yystate76:
	c = this.next()
	goto yyrule17

yyrule1: // "#".*

	goto yystate0
yyrule2: // [ \t]+

	goto yystate0
yyrule3: // alert
	{
		this.back()
		return RULE_ALERT
		goto yystate0
	}
yyrule4: // admit
	{
		this.back()
		return RULE_ADMIT
		goto yystate0
	}
yyrule5: // block
	{
		this.back()
		return RULE_BLOCK
		goto yystate0
	}
yyrule6: // name
	{
		this.back()
		return ATTRIBUTE_NAME
		goto yystate0
	}
yyrule7: // side
	{
		this.back()
		return ATTRIBUTE_SIDE
		goto yystate0
	}
yyrule8: // regex
	{
		this.back()
		return ATTRIBUTE_REGEX
		goto yystate0
	}
yyrule9: // flush
	{
		this.back()
		return ATTRIBUTE_FLUSH
		goto yystate0
	}
yyrule10: // client
	{
		this.back()
		return SIDE_CLIENT
		goto yystate0
	}
yyrule11: // server
	{
		this.back()
		return SIDE_SERVER
		goto yystate0
	}
yyrule12: // match
	{
		this.back()
		return ATTRIBUTE_MATCH
		goto yystate0
	}
yyrule13: // replace
	{
		this.back()
		return ATTRIBUTE_REPLACE
		goto yystate0
	}
yyrule14: // skip
	{
		this.back()
		return ATTRIBUTE_SKIP
		goto yystate0
	}
yyrule15: // state
	{
		this.back()
		return ATTRIBUTE_STATE
		goto yystate0
	}
yyrule16: // set
	{
		this.back()
		return ATTRIBUTE_STATE_SET
		goto yystate0
	}
yyrule17: // unset
	{
		this.back()
		return ATTRIBUTE_STATE_UNSET
		goto yystate0
	}
yyrule18: // is
	{
		this.back()
		return ATTRIBUTE_STATE_IS
		goto yystate0
	}
yyrule19: // not
	{
		this.back()
		return ATTRIBUTE_STATE_NOT
		goto yystate0
	}
yyrule20: // [a-zA-Z]
	{
		this.back()
		this.back()
		c = this.next()
		lval.cur_string = ""
		for {
			if c == 0 {
				this.back()
				return WORDCHAR
			}
			if c >= '0' && c <= '9' {
				lval.cur_string += string(c)
				c = this.next()
			} else if c >= 'a' && c <= 'z' {
				lval.cur_string += string(c)
				c = this.next()
			} else if c >= 'A' && c <= 'Z' {
				lval.cur_string += string(c)
				c = this.next()
			} else if c == '_' {
				lval.cur_string += string(c)
				c = this.next()
			} else {
				this.back()
				return WORDCHAR
			}
		}
		goto yystate0
	}
yyrule21: // [0-9]
	{
		this.back()
		this.back()
		c = this.next()
		lval.cur_number = 0
		for {

			if c == 0 {
				this.back()
				return NUMBER
			}
			if c >= '0' && c <= '9' {
				lval.cur_number = (lval.cur_number * 10) + int(c) - '0'
				c = this.next()
			} else {
				this.back()
				return NUMBER
			}
		}
		goto yystate0
	}
yyrule22: // \"
	{
		lval.input_data.byte_array = make([]byte, 8192)
		lval.input_data.byte_len = 0
		for {
			if c == 0 {
				fmt.Printf("Unterminated string! ")
				return -1
			}
			if c == '\\' {
				c = this.next()
				lval.input_data.byte_array[lval.input_data.byte_len] = '\\'
				lval.input_data.byte_len++
				lval.input_data.byte_array[lval.input_data.byte_len] = c
				lval.input_data.byte_len++
			} else if c == '"' {
				// Terminate string
				return STRING
			} else {
				// fmt.Printf("Char: %d\n", c )
				lval.input_data.byte_array[lval.input_data.byte_len] = c
				lval.input_data.byte_len++
			}
			c = this.next()
		}
		goto yystate0
	}
	panic("unreachable")

	goto yyabort // silence unused label error

yyabort: // no lexem recognized

	return int(c)

} // ends lexer

func AsciiCharToHex(c byte) (byte, error) {
	if c >= 'a' && c <= 'f' {
		return 10 + (c - 'a'), nil
	} else if c >= 'A' && c <= 'F' {
		return 10 + (c - 'A'), nil
	} else if c >= '0' && c <= '9' {
		return c - '0', nil
	} else {
		return 0, fmt.Errorf("Invalid ascii hex character: %c\n", c)
	}
}
