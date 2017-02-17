#!/bin/sh

go tool yacc -p IDS -o ids_yacc.y.go ids_yacc.y
golex -t -o ids_lex.yy.go ids_lex.l | gofmt > ids_lex.yy.go

go build
