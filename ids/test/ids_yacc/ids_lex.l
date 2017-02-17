%{
package main

import (
    "fmt"
)

type IDSLex struct {
    S string
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

%}

%yyc c
%yyn c = this.next()

%%
        // fmt.Printf("c=%c\n", c)
        /*
        if nil!=this.buf {
                    this.buf = this.buf[len(this.buf)-1:]
                }
        */

        // "#"(.*[ \t]*.*)*[\n]+
"#".*

[ \t]+

alert     this.back();return RULE_ALERT
admit     this.back();return RULE_ADMIT
block     this.back();return RULE_BLOCK

name      this.back();return ATTRIBUTE_NAME
side      this.back();return ATTRIBUTE_SIDE
regex     this.back();return ATTRIBUTE_REGEX
flush     this.back();return ATTRIBUTE_FLUSH

client    this.back();return SIDE_CLIENT
server    this.back();return SIDE_SERVER

match     this.back();return ATTRIBUTE_MATCH
replace   this.back();return ATTRIBUTE_REPLACE

skip      this.back();return ATTRIBUTE_SKIP

state     this.back();return ATTRIBUTE_STATE

set       this.back();return ATTRIBUTE_STATE_SET
unset     this.back();return ATTRIBUTE_STATE_UNSET
is        this.back();return ATTRIBUTE_STATE_IS
not       this.back();return ATTRIBUTE_STATE_NOT

[a-zA-Z]  this.back();this.back();c = this.next(); lval.cur_string = ""; for ;; {
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
                this.back();
                return WORDCHAR
          }
        }

[0-9]     this.back();this.back();c = this.next(); lval.cur_number = 0; for ; ; {
         
          if c == 0 {
                this.back()
                return NUMBER
          }

          if c >= '0' && c <= '9' {
              lval.cur_number = (lval.cur_number*10) + int(c)-'0'
              c = this.next()
          } else {
                this.back()
                return NUMBER
          }
        }


\"    lval.input_data.byte_array = make([]byte,8192); lval.input_data.byte_len = 0 ; for ; ; {
            if c == 0 {
                fmt.Printf("Unterminated string! " )
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

%%

return int(c)

} // ends lexer

func AsciiCharToHex( c byte ) (byte, error) {
    if ( c >= 'a' && c <= 'f' ) {
        return 10+(c-'a'), nil
    } else if ( c >= 'A' && c <= 'F' ) {
        return 10+(c-'A'), nil
    } else if ( c >= '0' && c <= '9' ) {
        return c-'0', nil
    } else {
        return 0, fmt.Errorf("Invalid ascii hex character: %c\n", c )
    } 
}
