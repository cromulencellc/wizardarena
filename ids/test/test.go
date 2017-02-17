package main

import "fmt"
import "net"
import "bufio"
import "regexp"
import "flag"

//import "strings"
const (
	IDS_SIDE_CLIENT = iota
	IDS_SIDE_SERVER = iota
)

const (
	FLUSH_SIDE_CLIENT = iota
	FLUSH_SIDE_SERVER = iota
	FLUSH_SIDE_NA     = iota
)

type IDSMethod func(string, string) string

type IDSRule struct {
	name        string
	method      IDSMethod
	match_regex regexp.Regexp
	side        int
	flush       int
}

func InitCommandLine() {
	var cmdline_host string
	var cmdline_port int
	var cmdline_rules string

	flag.StringVar(&cmdline_host, "host", "localhost", "Host to listen on")
	flag.StringVar(&cmdline_rules, "rules", "", "Rule file for IDS rules")
	flag.IntVar(&cmdline_port, "port", 1234, "Port to listen on")

	flag.Parse()

	fmt.Println("Host is: ", cmdline_host)
	fmt.Println("Port is: ", cmdline_port)
	fmt.Println("Rules is: ", cmdline_rules)
}

func ParseRule(rule_string string) {
	var method_str, parameter_str string

	fmt.Sscanf(rule_string, "%s (", &method_str)

	fmt.Println("Method: ", method_str)
	fmt.Println("Parameters: ", parameter_str)
}

func main() {
	InitCommandLine()
	ParseRule("admit (name:\"whenever we see server data, flush the client stream\"; side:server; regex:\".*\"; flush:client;)")

	return

	fmt.Printf("Starting server: ")

	ln, _ := net.Listen("tcp", ":8081")

	conn, _ := ln.Accept()

	match_regobj, _ := regexp.Compile("*.foo, bar.*")

	for {
		message, _ := bufio.NewReader(conn).ReadString('\n')

		if len(message) == 0 {
			break
		}

		match_string := match_regobj.FindStringIndex(message)
		if match_string != nil {
			fmt.Print("Match: ", string(message[match_string[0]:match_string[1]]))
		}
	}
}
