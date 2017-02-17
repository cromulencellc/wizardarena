// ======================================================= //
// Network Appliance (rewritten in GO)
//
// Description:
// 		Main entry point for network appliance
//
//======================================================== //
package main

import "fmt"
import "net"

//import "bufio"
//import "log"
import "strings"
import "container/list"
import "errors"
import "encoding/binary"
import "encoding/hex"
import "bytes"

//import "regexp"
import "flag"

//import "os"

var cmdline_listen_port int
var cmdline_rules_filename string
var cmdline_pcap_host string
var cmdline_pcap_port int
var cmdline_outbound_host string
var cmdline_outbound_port int
var cmdline_negotiate bool
var cmdline_loglevel int
var cmdline_buffer_size int
var cmdline_csid uint
var cmdline_max_connections uint
var cmdline_connection_id uint

type NetworkFilter struct {
	filter_list   *list.List
	state         map[string]bool
	client_buffer []byte
	server_buffer []byte
	buffer_size   int
}

type NegotiationData struct {
	state            int
	raw_client_data  []byte
	tlv_left         uint32
	server_data_left int
	chunk_size       uint32
}

type Connection struct {
	name            string
	csid            uint
	connection_id   uint
	side            int
	in_data         chan []byte // Data coming from other end
	out_data        chan []byte // Data going to other end
	conn_socket     net.Conn
	close_conn      chan bool
	ConnectionList  *list.List
	filter          *NetworkFilter
	do_negotiate    *bool // Negotiate on the connection
	negotiation     *NegotiationData
	pcap_socket     net.Conn
	pcap_message_id *uint32
}

type IDSRule struct {
	rule_type      int
	name           string
	flush          int
	RuleOptionList *list.List
	IDSRuleList    *list.List
}

const (
	LOG_DEBUG = 1
	LOG_INFO  = 2
	LOG_WARN  = 3
	LOG_ERROR = 4
	LOG_NONE  = 5
)

const (
	NEGOTIATION_STATE_CLIENT_COUNT        = 0
	NEGOTIATION_STATE_CLIENT_CHUNK_HEADER = 1
	NEGOTIATION_STATE_CLIENT_CHUNK_DATA   = 2
	NEGOTIATION_STATE_SERVER_DATA         = 3
)

var g_ruleList *list.List

func AddIDSRule(rule_type int, name string, flush int, rule_list *list.List) {

	//Log(LOG_DEBUG, "NEW RULE [%s] FLUSH=%d (possible %d,%d)", name, flush, RULE_SIDE_CLIENT, RULE_SIDE_SERVER)

	newRule := &IDSRule{rule_type, name, flush, rule_list, g_ruleList}
	g_ruleList.PushBack(*newRule)
}

func Log(level int, format string, v ...interface{}) {
	if level >= cmdline_loglevel {
		fmt.Printf(format+"\n", v...)
	}
}

func (filter_data *IDSRule) RunFilter(state map[string]bool, side int, data []byte, data_offset int) ([]byte, int, error) {
	// Iterate through the options -- stopping when an option fails

	// Handle each filter option
	for filter_option := filter_data.RuleOptionList.Front(); filter_option != nil; filter_option = filter_option.Next() {
		filter_data := filter_option.Value.(RuleOptionStruct)

		switch filter_data.option_type {
		case RULE_OPTION_SIDE:
			if side == RULE_SIDE_SERVER && filter_data.value_int != RULE_SIDE_SERVER {
				return nil, 0, nil
			} else if side == RULE_SIDE_CLIENT && filter_data.value_int != RULE_SIDE_CLIENT {
				return nil, 0, nil
			}

		case RULE_OPTION_REGEX:
			// Handle regex
			raw_data := data[data_offset:]
			Log(LOG_DEBUG, "REGEX [%s] CHECKING: %s", filter_data.value_regex.String(), string(raw_data))
			match_index := filter_data.value_regex.FindIndex(raw_data)

			if match_index != nil {
				Log(LOG_INFO, "REGEX MATCH: %d -> %d", match_index[0], match_index[1])
				data_offset += match_index[1]
			} else {
				return nil, 0, nil
			}

		case RULE_OPTION_MATCH:
			raw_data := data[data_offset:]

			if filter_data.value_int > 0 {
                          // Check if depth is less than the length of remaining data -- if that is the case -- only analyze up to depth... otherwise depth is either the length or larger -- don't do anything (analyze all the remaining data)
                          if filter_data.value_int < len(raw_data) {
			    raw_data = raw_data[:filter_data.value_int]
                          }
			}

			offset_index := strings.Index(string(raw_data), filter_data.value_str)

			if offset_index == -1 {
				return nil, 0, nil
			}

			data_offset += offset_index

			if filter_data.value_str2 != "" {
				if data_offset+len(filter_data.value_str2) > len(data) {
					return nil, 0, errors.New("Replace in match statement -- data overrun")
				}

				//data = append(data[:data_offset], append(append(raw_data[:offset_index], []byte(filter_data.value_str2)...), raw_data[offset_index+len(filter_data.value_str2):]...)...)
                                // Append data up to the first index of the replace match, then append the replaced string, and then append the data remaining
				data = append(data[:data_offset], append([]byte(filter_data.value_str2), data[data_offset+len(filter_data.value_str2):]...)...)
			}

			data_offset += len(filter_data.value_str)

			Log(LOG_INFO, "====MATCH: (%d,%d) string: %s", offset_index, data_offset, filter_data.value_str2)

		case RULE_OPTION_SKIP:
			if data_offset+filter_data.value_int > len(data) {
				return nil, 0, nil
			}

			data_offset += filter_data.value_int

		case RULE_OPTION_STATE:
			state_name := filter_data.value_str

			if filter_data.value_int == ATTRIBUTE_STATE_SET {
				Log(LOG_INFO, "STATE SET: %s", state_name)
				state[state_name] = true
			} else if filter_data.value_int == ATTRIBUTE_STATE_UNSET {
				Log(LOG_INFO, "STATE UNSET: %s", state_name)
				state[state_name] = false
			} else if filter_data.value_int == ATTRIBUTE_STATE_IS {
				if value, ok := state[state_name]; ok == true && value == true {
					Log(LOG_INFO, "STATE IS SET: %s", state_name)
				} else {
					return nil, 0, nil
				}
			} else if filter_data.value_int == ATTRIBUTE_STATE_NOT {
				if value, ok := state[state_name]; ok == false || value == false {
					Log(LOG_INFO, "STATE NOT SET: %s", state_name)
				} else {
					return nil, 0, nil
				}
			} else {
				return nil, 0, errors.New("Unknown state attribute")
			}

		default:
			return nil, 0, errors.New("Invalid filter option during evaluation")
		}
	}

	return data, data_offset, nil
}

func (c *Connection) NetworkFilter(data []byte) ([]byte, error) {

	offset := 0

	data_len := len(data)
	var scan_buffer []byte

	if c.side == RULE_SIDE_CLIENT {
		buff_len := len(c.filter.client_buffer)
		if data_len+buff_len > c.filter.buffer_size {
			// Truncate
			c.filter.client_buffer = c.filter.client_buffer[data_len:]
		}

		scan_buffer = c.filter.client_buffer
	} else if c.side == RULE_SIDE_SERVER {
		buff_len := len(c.filter.server_buffer)
		if data_len+buff_len > c.filter.buffer_size {
			// Truncate
			c.filter.server_buffer = c.filter.server_buffer[data_len:]
		}

		scan_buffer = c.filter.server_buffer
	}

	scan_buffer = append(scan_buffer, data...)

	flush_client := false
	flush_server := false

	// The offset scanned so far!
	scan_offset := 0

	// Recent match
	recent_match := list.New()

	// LOG scan buffer

	for {
		current_offset := scan_offset

		did_match := false
		// Iterate over all the filter rules
		for rule_item := c.filter.filter_list.Front(); rule_item != nil; rule_item = rule_item.Next() {
			rule_data := rule_item.Value.(IDSRule)

			new_state := make(map[string]bool, len(c.filter.state))

			for k, v := range c.filter.state {
				new_state[k] = v
			}

			offset = scan_offset

			ret, new_offset, err := rule_data.RunFilter(new_state, c.side, scan_buffer, scan_offset)

			if ret != nil && rule_data.rule_type == RULE_BLOCK {
				// Block matched
				Log(LOG_INFO, "blocking connection: %s", c.name)
				return nil, errors.New("Connection dropped")
			}

			if err != nil {
				// Error from running filter
				Log(LOG_ERROR, "Error: %s", err)
			}

			if ret == nil {
				// No matches
				Log(LOG_DEBUG, "filter did not match %s: %s ", rule_data.name, string(scan_buffer[scan_offset:]))
				scan_offset = offset
				continue
			}

			if rule_data.rule_type != RULE_ADMIT {
				// Log("MATCH! ", rule_data.name)
				recent_match.PushBack(rule_data.name)
				did_match = true
			}

			scan_buffer = ret
			scan_offset = new_offset

			if rule_data.flush != 0 {
				if rule_data.flush == RULE_SIDE_CLIENT {
					Log(LOG_DEBUG, "FLUSHING: %s SIDE CLIENT", c.name)
					flush_client = true
				} else if rule_data.flush == RULE_SIDE_SERVER {
					Log(LOG_DEBUG, "FLUSHING: %s SIDE SERVER", c.name)
					flush_server = true
				}
				scan_offset += len(scan_buffer[scan_offset:])
			}

			c.filter.state = new_state

			// a rule matched.  continued analysis should happen from the beginning of the list
			break
		}

		// match check
		if did_match == false {
			break
		}

		if current_offset == scan_offset {
			break
		}
	}

	orig_len := 0
	if c.side == RULE_SIDE_SERVER {
		orig_len = len(c.filter.server_buffer)
		c.filter.server_buffer = scan_buffer[scan_offset:]
		Log(LOG_DEBUG, "ORIG LEN: %d -- NEW LEN: %d", orig_len, len(c.filter.server_buffer))
	} else if c.side == RULE_SIDE_CLIENT {
		orig_len = len(c.filter.client_buffer)
		c.filter.client_buffer = scan_buffer[scan_offset:]
		Log(LOG_DEBUG, "ORIG LEN: %d -- NEW LEN: %d", orig_len, len(c.filter.client_buffer))
	}

	if flush_client == true {
		c.filter.client_buffer = nil
	}
	if flush_server == true {
		c.filter.server_buffer = nil
	}

	return scan_buffer[orig_len:], nil
}

func (c *Connection) HandleNegotiationClient(data_in []byte) []byte {
	if c.negotiation.state != NEGOTIATION_STATE_CLIENT_COUNT && c.negotiation.state != NEGOTIATION_STATE_CLIENT_CHUNK_HEADER && c.negotiation.state != NEGOTIATION_STATE_CLIENT_CHUNK_DATA {
		Log(LOG_DEBUG, "invalid negotiation state for client side")
		c.Close()
		return nil
	}

	c.negotiation.raw_client_data = append(c.negotiation.raw_client_data, data_in...)

	Log(LOG_DEBUG, "HandleNegotiationClient: raw_client_data length=%d", len(c.negotiation.raw_client_data))

	if c.negotiation.state == NEGOTIATION_STATE_CLIENT_COUNT {
		if len(c.negotiation.raw_client_data) < 4 {
			return nil
		}

		raw_client_size := c.negotiation.raw_client_data[:4]
		c.negotiation.raw_client_data = c.negotiation.raw_client_data[4:]
		c.negotiation.tlv_left = binary.LittleEndian.Uint32(raw_client_size)

		Log(LOG_DEBUG, "HandleNegotiationClient: state=CLIENT_COUNT, tlv_left=%d", c.negotiation.tlv_left)

		c.out_data <- raw_client_size

		c.negotiation.state = NEGOTIATION_STATE_CLIENT_CHUNK_HEADER
	}

	for {
		if c.negotiation.state == NEGOTIATION_STATE_CLIENT_CHUNK_HEADER {
			if c.negotiation.tlv_left == 0 {
				c.negotiation.state = NEGOTIATION_STATE_SERVER_DATA
				break
			}

			header_size := 8

			if len(c.negotiation.raw_client_data) < header_size {
				return nil
			}

			raw_chunk_header := c.negotiation.raw_client_data[:header_size]
			c.negotiation.raw_client_data = c.negotiation.raw_client_data[header_size:]
			c.negotiation.chunk_size = binary.LittleEndian.Uint32(raw_chunk_header[4:])

			Log(LOG_DEBUG, "HandleNegotiationClient: state=CLIENT_CHUNK_HEADER, chunk_size=%d", c.negotiation.chunk_size)
			c.out_data <- raw_chunk_header

			c.negotiation.state = NEGOTIATION_STATE_CLIENT_CHUNK_DATA
		}

		if c.negotiation.state == NEGOTIATION_STATE_CLIENT_CHUNK_DATA {
			chunk_size := c.negotiation.chunk_size
			if uint32(len(c.negotiation.raw_client_data)) < chunk_size {
				Log(LOG_DEBUG, "HandleNegotiationClient: state=CLIENT_CHUNK_DATA, raw_client_data length is less than chunk_size (%d < %d)", uint32(len(c.negotiation.raw_client_data)), chunk_size)
				return nil
			}

			chunk := c.negotiation.raw_client_data[:chunk_size]
			c.negotiation.raw_client_data = c.negotiation.raw_client_data[chunk_size:]
			c.negotiation.state = NEGOTIATION_STATE_CLIENT_CHUNK_HEADER

			Log(LOG_DEBUG, "HandleNegotiationClient: state=CLIENT_CHUNK_DATA, tlv_left=%d", c.negotiation.tlv_left)
			
			c.negotiation.tlv_left -= 1

			if c.negotiation.tlv_left == 0 {
				c.negotiation.state = NEGOTIATION_STATE_SERVER_DATA
			
				c.out_data <- chunk
				break
			}
			
			c.out_data <- chunk
		}
	}

	rest := c.negotiation.raw_client_data
	c.negotiation.raw_client_data = []byte{}

	return rest
}

func (c *Connection) HandleNegotiationServer(data_in []byte) []byte {
	if c.negotiation.state != NEGOTIATION_STATE_SERVER_DATA {
		Log(LOG_DEBUG, "invalid negotiation state for server side")
		c.Close()
		return nil
	}

	left := c.negotiation.server_data_left

	rest := data_in[left:]
	data_in = data_in[:left]

	left -= len(data_in)

	c.negotiation.server_data_left = left

	// Write out
	c.out_data <- data_in

	Log(LOG_DEBUG, "HandleNegotiationServer: left=%d, rest=%d, data_in=%d", left, len(rest), len(data_in))
	if left == 0 {
		Log(LOG_DEBUG, "Negotiation complete")
		*c.do_negotiate = false
		c.negotiation = nil
	}

	return rest
}

func (c *Connection) HandleNegotiation(data_in []byte) []byte {
	Log(LOG_DEBUG, "negotiation (%s:%X): %d - %s", c.do_negotiate, &c.negotiation, c.conn_socket, string(data_in))

	if c.side == RULE_SIDE_CLIENT {
		return c.HandleNegotiationClient(data_in)
	} else {
		return c.HandleNegotiationServer(data_in)
	}
}

func (c *Connection) Read(max_bytes_optional ...int) int {
	max_bytes := 0x1000
	if len(max_bytes_optional) > 0 {
		max_bytes = max_bytes_optional[0]
	}

	buffer := make([]byte, max_bytes)
	bytesRead, err := c.conn_socket.Read(buffer)

	if err != nil {
		Log(LOG_ERROR, "Read error: %s", err)
		c.Close()
		return -1
	}

	// Incoming data
	new_data := buffer[:bytesRead]

	// Log in debug mode
	Log(LOG_DEBUG, "read from %s: %s (%d bytes)", c.name, string(new_data), bytesRead)

	// Check for negotiation
	if *c.do_negotiate && c.negotiation != nil {
		new_data = c.HandleNegotiation(new_data)

		// Check if negotiation consumed all the data
		if len(new_data) == 0 {
			return 0
		}
	}

	// Check network filter
	output_data, err := c.NetworkFilter(new_data)

	if err != nil {
		c.Close()
		return -1
	}

	c.out_data <- output_data

	// Log packets
	c.RemoteLog(output_data)

	return bytesRead
}

func (c *Connection) Close() {
	c.close_conn <- true
}

func (c *Connection) RemoveMe() {
	for entry := c.ConnectionList.Front(); entry != nil; entry = entry.Next() {
		client := entry.Value
		if c == client {
			c.ConnectionList.Remove(entry)
		}
	}
}

func ConnectionReader(c *Connection) {
	for {
		bytesRead := c.Read()

		if bytesRead == -1 {
			return
		}
	}
}

func (c *Connection) RemoteLog(buf []byte) {
	if c.pcap_socket == nil {
		return
	}

	Log(LOG_DEBUG, "remote log: %d bytes written", len(buf))

	data_left := len(buf)
	data_written := 0
	for data_left > 0 {
		data_to_write := data_left
		if data_to_write > 1024 {
			data_to_write = 1024
		}

		var message_header = []interface{}{
			uint32(c.csid),
			uint32(c.connection_id),
			uint32(*c.pcap_message_id),
			uint16(data_to_write),
			uint8(c.side - 1),
		}

		message_output_buffer := new(bytes.Buffer)

		for _, v := range message_header {
			binary.Write(message_output_buffer, binary.LittleEndian, v)
		}

		Log(LOG_DEBUG, "[[PCAP]] Header is (len=%d): %s\n", len(message_output_buffer.Bytes()), hex.EncodeToString(message_output_buffer.Bytes()))

		c.pcap_socket.Write(append(message_output_buffer.Bytes(), buf[data_written:data_written+data_to_write]...))

		*c.pcap_message_id += 1
		data_left -= data_to_write
		data_written += data_to_write
	}
}

func ConnectionSender(c *Connection) {
	for {
		select {
		case buffer := <-c.in_data:
			c.conn_socket.Write([]byte(buffer))

		case <-c.close_conn:
			Log(LOG_DEBUG, "connection closed: %s", c.name)
			c.conn_socket.Close()
			c.RemoveMe()

			if c.pcap_socket != nil {
				c.pcap_socket.Close()
			}

			c.close_conn <- true
			return
		}
	}
}

func InitCommandLine() {

	flag.IntVar(&cmdline_listen_port, "listen_port", 1234, "Port to listen on")
	flag.StringVar(&cmdline_rules_filename, "rules", "", "Rules file for IDS")
	flag.StringVar(&cmdline_pcap_host, "pcap_host", "", "PCAP hostname for sending PCAP data")
	flag.IntVar(&cmdline_pcap_port, "pcap_port", 0, "PCAP port for sending PCAP data")
	flag.StringVar(&cmdline_outbound_host, "outbound_host", "", "Outbound host for cb-server")
	flag.IntVar(&cmdline_outbound_port, "outbound_port", 0, "Outbound port for cb-server")
	flag.BoolVar(&cmdline_negotiate, "negotiate", false, "Handle negotiation packet")
	flag.IntVar(&cmdline_loglevel, "loglevel", 0, "Logging level (0=All, 1=Info, 2=Warn, 3=Error, 4=None")
	flag.IntVar(&cmdline_buffer_size, "buffer_size", 100*1024, "Max size of inspection buffer")
	flag.UintVar(&cmdline_csid, "csid", 0, "Challenge set ID, integer")
        flag.UintVar(&cmdline_connection_id, "connection_id", 0, "Connection id starts at this number")
	flag.UintVar(&cmdline_max_connections, "max_connections", 0, "Max number of connections to accept, 0=unlimited")
	flag.Parse()
}

func main() {
	g_ruleList = list.New()

	// Init command line arguments
	InitCommandLine()

	Log(LOG_INFO, "Starting server on port %d.\n", cmdline_listen_port)

	if cmdline_rules_filename == "" || cmdline_rules_filename == "empty.rules" {
		Log(LOG_INFO, "Using empty rules filename\n")
	} else {
	        // Read the rules in -- only if they specified a rules file -- otherwise we will just use an empty rules list
		ReadIDSRules(cmdline_rules_filename)
	}

	// Remember connection list
	connectionList := list.New()

	// Optionally open
	listen_port_string := fmt.Sprintf(":%d", cmdline_listen_port)

	ln, err := net.Listen("tcp", listen_port_string)

	if err != nil {
		Log(LOG_ERROR, "Listen error: %s", err)
		return
	}

	defer ln.Close()

	// Count number of connections
	connections_seen := cmdline_connection_id

	for {
		conn_client, err := ln.Accept()

		if err != nil {
			Log(LOG_ERROR, "Client accept error: %s", err)
			continue
		}

		server_address := fmt.Sprintf("%s:%d", cmdline_outbound_host, cmdline_outbound_port)
		conn_server, err := net.Dial("tcp", server_address)

		if err != nil {
			Log(LOG_ERROR, "Failed to connect to server: %s", err)
			conn_client.Close()

			continue
		}

		// Create a pcap socket (if it is specified)
		var pcap_socket net.Conn = nil
		if cmdline_pcap_host != "" {
			pcap_address := fmt.Sprintf("%s:%d", cmdline_pcap_host, cmdline_pcap_port)
			pcap_socket, _ = net.Dial("udp", pcap_address)
		}

		// Create new network filter for this connection
		netFilter := &NetworkFilter{g_ruleList, nil, nil, nil, cmdline_buffer_size}

		// Accept a client connection and then connect to the server end

		Log(LOG_ERROR, "New client->server connection accepted!")

		close_chan := make(chan bool)

		pcap_message_id := new(uint32)
		*pcap_message_id = 0

		// server -> client
		server_to_client_data := make(chan []byte)

		// client -> server
		client_to_server_data := make(chan []byte)

		var negotiation_data *NegotiationData
		var do_negotiate_for_connection = false
		if cmdline_negotiate {
			negotiation_data = &NegotiationData{NEGOTIATION_STATE_CLIENT_COUNT, nil, 0, 4, 0}
			do_negotiate_for_connection = true
		} else {
			negotiation_data = nil
		}

		clientConnection := &Connection{"Client Listener", cmdline_csid, connections_seen, RULE_SIDE_CLIENT, server_to_client_data, client_to_server_data, conn_client, close_chan, connectionList, netFilter, &do_negotiate_for_connection, negotiation_data, pcap_socket, pcap_message_id}
		connectionList.PushBack(*clientConnection)

		go ConnectionReader(clientConnection)
		go ConnectionSender(clientConnection)

		serverConnection := &Connection{"Server Listener", cmdline_csid, connections_seen, RULE_SIDE_SERVER, client_to_server_data, server_to_client_data, conn_server, close_chan, connectionList, netFilter, &do_negotiate_for_connection, negotiation_data, pcap_socket, pcap_message_id}

		go ConnectionReader(serverConnection)
		go ConnectionSender(serverConnection)

		connections_seen += 1
		if cmdline_max_connections > 0 {
			if connections_seen >= cmdline_max_connections {
				Log(LOG_INFO, "Max connections reached: %d", connections_seen)
				break
			}
		}
	}
}
