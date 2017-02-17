#!/usr/bin/env python

from io import BytesIO
from StringIO import StringIO
import tarfile
import binascii
import parse
import time
import logging
from sets import Set
import numpy
import ansi_x931_aes128
import re
import datetime

class CBPOVHelper:
    def _check_result_type1(self, sig, replay_stdout, server_stdout):
        if sig == 0:
            if self.should_core:
                logging.error('not ok - POV type 1 should have cored, and did not.', extra={'raw':True})
                return -1
            else:            
                logging.warning('ok - POV type 1 did not core, as expected', extra={'raw':True})
                return 0
        elif not self.should_core:
            logging.error('not ok - POV type 1 expected to not core, but did. (signal %d: %s)', sig, self.signal_name(sig), extra={'raw':True})
            return -1

        match = re.match(r"(?ms).*\n# type 1 masks: ([a-fA-F0-9]+) ([a-fA-F0-9]+)", replay_stdout)
        if not match:
            logging.error('not ok - POV type 1 negotiation failed', extra={'raw':True})
            return -1
        ip_mask = int(match.group(1), 16)
        reg_mask = int(match.group(2), 16)
            
        match = re.match(r"(?ms).*\n# type 1 pov: ([a-fA-F0-9]+) ([a-fA-F0-9]+) (\d)", replay_stdout)
        if not match:
            logging.error('not ok - POV type 1 negotiation failed', extra={'raw':True})
            return -1

        ip_value = int(match.group(1), 16)
        reg_value = int(match.group(2), 16)
        reg_num = int(match.group(3))
        
        logging.warning('POV type 1 negotiated masks: %08x %08x %d', ip_mask, reg_mask, reg_num)
        # logging.warning('process cored as expected (signal %d: %s)', sig, self.signal_name(sig))

        register_state_re = r"(?ms).*\nregister states"
        register_state_re2 = r"register states - eax: ([a-fA-F0-9]+) ecx: ([a-fA-F0-9]+) edx: ([a-fA-F0-9]+) ebx: ([a-fA-F0-9]+) esp: ([a-fA-F0-9]+) ebp: ([a-fA-F0-9]+) esi: ([a-fA-F0-9]+) edi: ([a-fA-F0-9]+) eip: ([a-fA-F0-9]+)"

        match = re.match(register_state_re, server_stdout)
        if not match:
            logging.error('not ok - cb-server did not log register states', extra={'raw':True})
            return -1

        lines = server_stdout.split('\n')

        expected_eip = ip_value & ip_mask
        expected_reg = reg_value & reg_mask

        results = []
        for line in lines:
            match = re.match(register_state_re2, line)
            if not match:
                continue

            registers = []
            for i in range(8):
                registers.append(int(match.group(1+i), 16))
            eip = int(match.group(9), 16)

            result_eip = eip & ip_mask
            result_reg = registers[reg_num] & reg_mask

            if (result_eip == expected_eip and result_reg == expected_reg):
                logging.warning('ok - TYPE 1 POV', extra={'raw':True})
                return 0

            results.append([result_eip, result_reg])

        for values in results:
            logging.error('not ok - TYPE 1 POV FAILED.  expected eip: %08x actual eip: %08x expected reg: %08x actual reg: %08x', expected_eip, values[0], expected_reg, values[1], extra={'raw': True})
        
        return -1

    def _check_result_type2(self, replay_stdout, server_stdout):
        seed = self.cb_seed
        if not seed:
            match = re.match(r"(?ms).*\nseed: ([a-fA-F0-9]+)", server_stdout)
            if not match:
                logging.error('not ok - POV type 2 server did not print seed', extra={'raw':True})
                return -1

            seed = match.group(1)
        
        prng = ansi_x931_aes128.PRNG(seed.decode('hex'))
        flag_page = prng.get(0x1000)

        match = re.match(r"(?ms).*\n# secret value: ([a-fA-F0-9]+)", replay_stdout)
        if not match:
            if self.should_core:
                logging.error('not ok - POV type 2 did not return a secret value', extra={'raw':True})
                return -1
            else:
                logging.warning('ok - POV type 2 did not return a secret value as expected', extra={'raw':True})
                return 0

        value = match.group(1).decode('hex')
        if value not in flag_page:
            if not self.should_core:
                logging.warning('ok - POV type 2 secret value is not part of the secret page (as expected)', extra={'raw':True})
                return 0
            else:
                logging.error('not ok - TYPE 2 POV FAILED.  %s not in %s', value.encode('hex'), flag_page.encode('hex'), extra={'raw':True})
                return -1

        if not self.should_core:
            logging.error('not ok - TYPE 2 unexpectedly passed.  %s in %s', value.encode('hex'), flag_page.encode('hex'), extra={'raw':True})
            return -1

        logging.warning('ok - TYPE 2 POV', extra={'raw': True})
        return 0

    def _check_result_cfe(self, sig, replay_stdout, server_stdout):
        pov_type = None
        match = re.match(r"(?ms).*\n# negotiation type: (\d)\n", replay_stdout)
        if not match:
            logging.error("not ok - pov did not negotiate", extra={'raw':True})
            return -1

        pov_type = int(match.group(1))
        if pov_type not in [1, 2]:
            logging.error("not ok - pov negotiation is not 1 or 2: %d\n" % pov_type, extra={'raw':True})
            return -1

        if pov_type == 1:
            return self._check_result_type1(sig, replay_stdout, server_stdout)

        if pov_type == 2:
            return self._check_result_type2(replay_stdout, server_stdout)


class CBReplayPollData:
    def __init__(self, poll_number, poll_id, poll_seed):
        # Poll ID represents the filename ID number for the poll (GEN_xxxxx.xml) where XXXXX = ID
        self.poll_id = poll_id

        # Poll number represents the index used by CB-REPLAY
        self.poll_number = poll_number

        self.tests_failed = None
        self.tests_passed = None
        self.execute_time = None
        self.poll_seed = poll_seed
        self.filename = None

        self.timeout = False
        self.failure = False

    def SetExecuteTime( self, execute_time ):
        self.execute_time = execute_time

    def SetTestsFailed( self, tests_failed ):
        self.tests_failed = tests_failed

    def SetTestsPassed( self, tests_passed ):
        self.tests_passed = tests_passed

    def SetFilename( self, filename ):
        self.filename = filename

    def SetTimeout( self ):
        self.timeout = True

    def SetFailure( self ):
        self.failure = True

    def DidPollTimeout( self ):
        return self.timeout

    def DidPollFail( self ):
        return self.failure

    def GetPollDataString( self ):
        new_str = "[POLL %d][ID = %d][PASSED %d][FAILED %d][EXECUTE TIME %f][SEED %s]" % (self.poll_number, 10, self.tests_passed, self.tests_failed, self.execute_time, binascii.hexlify(self.poll_seed))

        return new_str

class CBReplayPOVData:
    def __init__(self, pov_number, cb_seed, pov_seed, pov_filename, pov_throw_count, pov_throw_max, pov_data, did_timeout = False ):
        self.pov_number = pov_number
        self.cb_seed = cb_seed
        self.pov_seed = pov_seed
        self.pov_filename = pov_filename
        self.pov_throw_count = pov_throw_count
        self.pov_throw_max = pov_throw_max
        self.pov_data = pov_data
        self.did_timeout = did_timeout

    def GetPOVDataString( self ):
        new_str = "[POV %d][FILENAME=%s][CB_SEED=%s][POV_SEED=%s][THROW %d of %d]" % (self.pov_number, self.pov_filename, self.cb_seed, self.pov_seed, self.pov_throw_count, self.pov_throw_max)

        return new_str

class CBServerData:
    def __init__(self, index, seed):
        self.timeout = False
        self.index = index
        self.seed = seed
        self.filesize = { }
        self.pid_file_mapping = { }
        self.total_children = None
        self.max_rss = None
        self.minor_faults = None
        self.utime = None
        self.cpu_clock = None
        self.task_clock = None
        self.exit_code = None
        self.last_signal = 0
        self.signal_list = [ ]
        self.register_state = None

    def SetFailTimeout( self ):
        self.timeout = True

    def SetFileSize( self, filename, filesize ):
        # Add filesize together (in the event of multiple binary services)
        self.filesize.update( {filename: filesize} )

    def AddPIDMapping( self, pid, filename ):
        self.pid_file_mapping.update( {pid: filename} )

    def AddSignal( self, pid, signal, ts ):
        self.signal_list.append( {'pid': pid, 'signal': signal, 'timestamp': ts } )
        self.last_signal = signal

    def SetRegisterState( self, register_state ):
        self.register_state = register_state

    def SetTotalChildren( self, total_children ):
        self.total_children = total_children

    def SetMaxRSS( self, max_rss ):
        self.max_rss = max_rss

    def SetMinFaults( self, minor_faults ):
        self.minor_faults = minor_faults

    def SetUTime( self, utime ):
        self.utime = utime

    def SetCPUClock( self, cpu_clock ):
        self.cpu_clock = cpu_clock

    def SetTaskClock( self, task_clock ):
        self.task_clock = task_clock

    def SetExitCode( self, exit_code ):
        self.exit_code = exit_code

    def GetTotalFileSize( self ):
        total_size = 0
        for filename in self.filesize:
            total_size += self.filesize[filename]

        return total_size

    def GetFileNameForPID( self, pid ):
        try:
            return self.pid_file_mapping[pid]
        except KeyError:
            return None
   
    def DidTimeout( self ):
        return self.timeout

    def GetCBServerDataString( self ):
        if self.last_signal != 0:
            new_str = "[CBSERVER %d][SEED: %s][FILESIZE: %d][CHILDREN: %d][MAX RSS: %d][MIN FLT: %d][UTIME: %f][CPU CLOCK: %d][TASK CLOCK: %d][SIGNAL: %d]\n" % (self.index, binascii.hexlify(self.seed), self.GetTotalFileSize(), self.total_children, self.max_rss, self.minor_faults, self.utime, self.cpu_clock, self.task_clock, self.last_signal )
            new_str += "[REGISTERS][eax: %08X ecx: %08X edx: %08X ebx: %08X esp: %08X ebp: %08X esi: %08X edi: %08X eip: %08X]" % (self.register_state['eax'], self.register_state['ecx'], self.register_state['edx'], self.register_state['ebx'], self.register_state['esp'], self.register_state['ebp'], self.register_state['esi'], self.register_state['edi'], self.register_state['eip'])
        else:
            new_str = "[CBSERVER %d][SEED: %s][FILESIZE: %d][CHILDREN: %d][MAX RSS: %d][MIN FLT: %d][UTIME: %f][CPU CLOCK: %d][TASK CLOCK: %d][EXIT CODE: %d]" % (self.index, binascii.hexlify(self.seed), self.GetTotalFileSize(), self.total_children, self.max_rss, self.minor_faults, self.utime, self.cpu_clock, self.task_clock, self.exit_code)

        return new_str

def ReadLineInt( line, name, end_delimiter ):
    item_find_pos = line.find(name)

    if item_find_pos >= 0:
        item_end_pos = line.find(end_delimiter, item_find_pos+len(name))

        return int(line[item_find_pos+len(name):item_end_pos])
    else:
        return None

def ReadLineFloat( line, name, end_delimiter ):
    item_find_pos = line.find(name)

    if item_find_pos >= 0:
        item_end_pos = line.find(end_delimiter, item_find_pos+len(name))

        return float(line[item_find_pos+len(name):item_end_pos])

    else:
        return None

class CBServerResults:
    def __init__(self, cbserver_stdout):
        self.cbserver_result_list = { }
        self.ParseResults( cbserver_stdout )

    def ParseResults( self, results ):
       
        current_seed = None
        current_cbserver_index = 0
        for line in results.split('\n'):
            seed_find_pos = line.find('seed: ')

            if ( seed_find_pos >= 0 ):
                # Find seed end pos
                seed_end_pos = line.find( '\n', seed_find_pos )

                current_seed = binascii.unhexlify(line[seed_find_pos+6:seed_end_pos])

                current_cbserver_data = CBServerData( current_cbserver_index, current_seed ) 

                current_cbserver_index += 1

                has_performance_data = False

            elif ( current_seed is not None ):
                # Find filesize
                if line.find('connection from: ') >= 0:
                    # End data capture
                    self.cbserver_result_list.update( {current_cbserver_data.seed: current_cbserver_data} )
                        
                    current_seed = None
                    continue

                if line.find('stat: ') >= 0:
                    a = re.match( "stat: ([a-zA-Z0-9_./]+) filesize (\d+)", line )

                    if a is not None:
                        # CB filename to filesize mapping
                        current_cbserver_data.SetFileSize( a.group(1), int(a.group(2)) )
                    else:
                        logging.error( "Found stat: mapping -- but failed to parse with re.match LINE[%s]" % line )
                        return -1

                if line.find('CB timed out (') >= 0:
                    current_cbserver_data.SetFailTimeout()

                total_children = ReadLineInt( line, "total children: ", "\n" )
                if total_children is not None:
                    has_performance_data = True
                    current_cbserver_data.SetTotalChildren( total_children )

                max_rss = ReadLineInt( line, "total maxrss ", "\n" )
                if max_rss is not None:
                    has_performance_data = True
                    current_cbserver_data.SetMaxRSS( max_rss )

                min_flt = ReadLineInt( line, "total minflt ", "\n" )
                if min_flt is not None:
                    has_performance_data = True
                    current_cbserver_data.SetMinFaults( min_flt )

                utime = ReadLineFloat( line, "total utime ", "\n" )
                if utime is not None:
                    has_performance_data = True
                    current_cbserver_data.SetUTime( utime )

                cpu_clock = ReadLineInt( line, "total sw-cpu-clock ", "\n" )
                if cpu_clock is not None:
                    has_performance_data = True
                    current_cbserver_data.SetCPUClock( cpu_clock )

                task_clock = ReadLineInt( line, "total sw-task-clock ", "\n" )
                if task_clock is not None:
                    has_performance_data = True
                    current_cbserver_data.SetTaskClock( task_clock )

                if has_performance_data:
                    exit_code = ReadLineInt( line, ", exit code: ", ")")

                    if exit_code is not None:
                        current_cbserver_data.SetExitCode( exit_code )

                if line.find('register states - ') >= 0:
                    a = re.match( "register states - eax: ([a-fA-F0-9]+) ecx: ([a-fA-F0-9]+) edx: ([a-fA-F0-9]+) ebx: ([a-fA-F0-9]+) esp: ([a-fA-F0-9]+) ebp: ([a-fA-F0-9]+) esi: ([a-fA-F0-9]+) edi: ([a-fA-F0-9]+) eip: ([a-fA-F0-9]+)", line )

                    if a is not None:
                        reg_eax = int(a.group(1), 16)
                        reg_ecx = int(a.group(2), 16)
                        reg_edx = int(a.group(3), 16)
                        reg_ebx = int(a.group(4), 16)
                        reg_esp = int(a.group(5), 16)
                        reg_ebp = int(a.group(6), 16)
                        reg_esi = int(a.group(7), 16)
                        reg_edi = int(a.group(8), 16)
                        reg_eip = int(a.group(9), 16)

                        current_cbserver_data.SetRegisterState( {'eax': reg_eax, 'ecx': reg_ecx, 'edx': reg_edx, 'ebx': reg_ebx, 'esp': reg_esp, 'ebp': reg_ebp, 'esi': reg_esi, 'edi': reg_edi, 'eip': reg_eip } )

                    else:
                        logging.error( "Found register states -- but failed to parse with re.match!" )
                        return -1
                elif line.find('CB generated signal (pid: ') >= 0:
                    a = re.match( "CB generated signal \(pid: (\d+), signal: (\d+), timestamp: ([0-9.]+)\)", line )

                    if a is not None:
                        # CB signaled error
                        try:
                            signal_ts = datetime.datetime.fromtimestamp( float(a.group(3)) )
                        
                            current_cbserver_data.AddSignal( int(a.group(1)), int(a.group(2)), signal_ts )
                        except:
                            logging.error( "CB Generated signal -- but got an invalid float for a timestamp (%s)!" % (a.group(3)) )
                            return -1

                    else:
                        logging.error( "Found CB Generated signal -- but failed to parse with re.match LINE(%s)" % line )
                        return -1

                elif line.find('PID[') >= 0:
                    a = re.match( "PID\[(\d+)\] FILE\[([a-zA-Z0-9_./]+)\]", line )

                    if a is not None:
                        # CB pid to FILE mapping
                        current_cbserver_data.AddPIDMapping( int(a.group(1)), a.group(2) )
                    else:
                        logging.error( "Found PID[] FILE[] mapping -- but failed to parse with re.match" )
                        return -1


        if current_seed is not None:        
            self.cbserver_result_list.update( {current_cbserver_data.seed: current_cbserver_data} )

            current_seed = None
                    




class CBReplayResults:
    def __init__(self, cbreplay_stdout):
        self.poll_result_list = { }
        self.pov_result_list = { }
        self.ParseResults( cbreplay_stdout )

    def ParseResults( self, results ):

        current_poll_number = None
        current_poll_id = None
        current_poll_data = None
        current_poll_seed = None

        current_pov_number = None
        current_cb_seed = None
        current_pov_seed = None
        current_pov_filename = None
        current_pov_throw_count = None
        current_pov_throw_max = None
        current_pov_data = None
        current_pov_timeout = False

        for line in results.split('\n'):
            startpov_find_pos = line.find('[STARTPOV ')
            if startpov_find_pos >= 0:
                # Start of POV data
                a = re.match("\[STARTPOV (\d+)\]\[([a-zA-Z0-9_./]+)\]\[cb_seed=([a-fA-F0-9]+)\]\[pov_seed=([a-fA-F0-9]+)\]\[(\d+) of (\d+)\]", line ) 
                if not a:
                    logging.error('Failed to match STARTPOV data -- perhaps invalid filename or path or possibly invalid log data format?', extra={'raw':True})
                    return -1

                current_pov_number = int(a.group(1))
                current_pov_filename = a.group(2)
                current_cb_seed = a.group(3).decode('hex')
                current_pov_seed = a.group(4).decode('hex')
                current_pov_throw_count = int(a.group(5))
                current_pov_throw_max = int(a.group(6))

                current_pov_data = { }

            elif current_pov_data is not None:
                endpov_find_pos = line.find('[ENDPOV ')

                if endpov_find_pos >= 0:
                    # Verify POV number?
                    b = re.match("\[ENDPOV (\d+)\]\[RUNTIMESEC (\d+)\]", line ) 

                    if ( current_pov_number != int(b.group(1)) ):
                        logging.error( "Error while recording POV data, ENDPOV number did not match STARTPOV number" )
                        return -1

                    # End of POV data
                    self.pov_result_list.update( {current_cb_seed: CBReplayPOVData( current_pov_number, current_cb_seed, current_pov_seed, current_pov_filename, current_pov_throw_count, current_pov_throw_max, current_pov_data, current_pov_timeout )} ) 

                    current_pov_number = None
                    current_cb_seed = None
                    current_pov_seed = None
                    current_pov_filename = None
                    current_pov_throw_count = None
                    current_pov_throw_max = None
                    current_pov_data = None
                    current_pov_timeout = False

                elif line.find('[STARTPOLL ') >= 0:
                    # Error
                    logging.error( "Error while recording POV data, found [STARTPOLL] tag before [ENDPOV] tag" )
                    return -1
                elif line.find('[STARTPOV ') >= 0:
                    # Error
                    logging.error( "Error while recording POV data, found [STARTPOV] tag before [ENVPOV] tag" )
                    return -1
                elif line.find('[POV FAIL TIMEOUT]') >= 0:
                    current_pov_timeout = True
                else:
                    # Add POV Data
                    match_pov_type = re.match("# negotiation type: (\d)", line)
                    if match_pov_type:
                        pov_type = int(match_pov_type.group(1))

                        if pov_type not in [1, 2]:
                            logging.error( "Found pov_type that is not 1 or 2!, pov_type is %d!" % pov_type )
                            return -1

                        current_pov_data.update( {'pov_type': pov_type} )

                    elif 'pov_type' in current_pov_data:
                        if current_pov_data['pov_type'] == 1:
                            # Handle type 1 POV data
                            type1_regmask_match = re.match( "# type 1 masks: ([a-fA-F0-9]+) ([a-fA-F0-9]+)", line )
                            if type1_regmask_match:
                                ip_mask = int(type1_regmask_match.group(1), 16)
                                reg_mask = int(type1_regmask_match.group(2), 16)

                                current_pov_data.update( {'ip_mask': ip_mask, 'reg_mask': reg_mask} )

                            type1_parameters_match = re.match( "# type 1 pov: ([a-fA-F0-9]+) ([a-fA-F0-9]+) (\d)", line )
                            if type1_parameters_match:
                                ip_value = int(type1_parameters_match.group(1), 16)
                                reg_value = int(type1_parameters_match.group(2), 16)
                                reg_num = int(type1_parameters_match.group(3))

                                current_pov_data.update( {'ip_value': ip_value, 'reg_value': reg_value, 'reg_num': reg_num} )

                        elif current_pov_data['pov_type'] == 2:
                            # Handle type 2 POV data
                            secret_value_match = re.match( "# secret value: ([a-fA-F0-9]+)", line )
                            if secret_value_match:
                                secret_value = secret_value_match.group(1).decode('hex')

                                current_pov_data.update( {'secret_value': secret_value} )

                continue

            startpoll_find_pos = line.find('[STARTPOLL ')
            if startpoll_find_pos >= 0:
                # Start of POV data
                a = re.match("\[STARTPOLL (\d+)\]\[FILE: /mnt/pollsource/GEN_(\d+)([a-zA-Z.]+)\]", line ) 
                if not a:
                    logging.error('Failed to match STARTPOLL data -- perhaps invalid filename or path or possibly invalid log data format?', extra={'raw':True})
                    return -1

                current_poll_number = int(a.group(1))
                current_poll_id = int(a.group(2))


            elif current_poll_number is not None:
                seed_find_pos = line.find('# negotiating seed as ')

                if ( seed_find_pos >= 0 ):
                    seed_end_pos = line.find('\n', seed_find_pos)

                    # Find seeds endline
                    current_poll_seed = binascii.unhexlify(line[seed_find_pos+22:seed_end_pos])

                    if current_poll_seed is None:
                        logging.warning( "CBReplayResults::ParseResults::Invalid cb-replay display format? Missing negotiation seed printout -- skipping this poll" )
                        
                        current_poll_number = None
                        current_poll_data = None
                        current_poll_id = None
                        current_poll_seed = None

                        continue

                    current_poll_data = CBReplayPollData( current_poll_number, current_poll_id, current_poll_seed )


            if current_poll_data is not None:
                if line.find('# tests passed: ') >= 0:
                    a = re.match("# tests passed: (\d+)", line )

                    if not a:
                        # Most likely encountered an exception
                        current_poll_data.SetTestsPassed( 0 )
                    else:
                        current_poll_data.SetTestsPassed( int(a.group(1)) )

                    continue

                if line.find('# tests failed: ') >= 0:
                    a = re.match("# tests failed: (\d+)", line )

                    if not a:
                        # Most likely encountered an exception
                        current_poll_data.SetTestsFailed( 1 )
                    else:
                        current_poll_data.SetTestsFailed( int(a.group(1)) )

                    continue

                if line.find('[POLL PARSE TIMEOUT]') >= 0:
                    current_poll_data.SetFailure()
                    continue
                elif line.find('[POLL PARSE ERROR]') >= 0:
                    current_poll_data.SetFailure()
                    continue
                elif line.find('[POLL TIMEOUT]') >= 0:
                    current_poll_data.SetTimeout()
                    continue
                elif line.find('[POLL FAILURE]') >= 0:
                    current_poll_data.SetFailure()
                    continue

                '''
                test_failure_data = line.find('[POLL TEST FAILURE - TestFailure(')
                if ( test_failure_data >= 0 ):
                    # Test Failure

                    if line.find('pov timeout') >= 0:
                        current_poll_data.SetTimeout()
                    else:
                        current_poll_data.SetFailure()

                    continue
                '''

                endpoll_find_pos = line.find('[ENDPOLL ')
                if ( endpoll_find_pos >= 0 ):
                    # Find end of ENDPOLL
                    endpoll_close_bracket_pos = line.find(']', endpoll_find_pos)

                    endpoll_number = int(line[endpoll_find_pos+9:endpoll_close_bracket_pos])

                    if ( endpoll_number != current_poll_number ):
                        # Error?
                        current_poll_number = None
                        current_poll_data = None
                        continue

                    # Get filename
                    filename_find_pos = line.find('[', endpoll_find_pos+9)
                    if ( filename_find_pos >= 0 ):
                        # Find end of filename
                        filename_end_pos = line.find(']', filename_find_pos)

                        filename = line[filename_find_pos+1:filename_end_pos]

                        current_poll_data.SetFilename( filename )

                    # Get time
                    time_find_pos = line.find('[time=', endpoll_close_bracket_pos)

                    if ( time_find_pos >= 0 ):
                        # Find end of time
                        time_end_pos = line.find(']', time_find_pos)

                        time_end_number = float(line[time_find_pos+6:time_end_pos])

                        current_poll_data.SetExecuteTime( time_end_number )

                    self.poll_result_list.update( {current_poll_seed: current_poll_data} )

                    current_poll_data = None
                    current_poll_number = None



# Baseline performance set
class PollPerformanceBaselineSet:
    def __init__( self, poll_id, poll_seed ):
        self.poll_id = poll_id
        self.poll_seed = poll_seed

        self.max_rss_list = [ ]
        self.min_flt_list = [ ]
        self.utime_list = [ ]
        self.cpu_clock_list = [ ]
        self.task_clock_list = [ ]
        self.wall_time_list = [ ]

    def AddPerformanceSet( self, max_rss, min_flt, utime, cpu_clock, task_clock, wall_time ):
        self.max_rss_list.append( max_rss )
        self.min_flt_list.append( min_flt )
        self.utime_list.append( utime )
        self.cpu_clock_list.append( cpu_clock )
        self.task_clock_list.append( task_clock )
        self.wall_time_list.append( wall_time )

    def GetPollID( self ):
        return self.poll_id 

    def GetMaxRSSMean( self ):
        return numpy.mean( self.max_rss_list )

    def GetMaxRSSDeviation( self ):
        return numpy.std( self.max_rss_list )

    def GetMinorFaultsMean( self ):
        return numpy.mean( self.min_flt_list )

    def GetMinorFaultsDeviation( self ):
        return numpy.std( self.min_flt_list )

    def GetUTimeMean( self ):
        return numpy.mean( self.utime_list )

    def GetUTimeDeviation( self ):
        return numpy.std( self.utime_list )

    def GetCPUClockMean( self ):
        return numpy.mean( self.cpu_clock_list )

    def GetCPUClockDeviation( self ):
        return numpy.std( self.cpu_clock_list )

    def GetTaskClockMean( self ):
        return numpy.mean( self.task_clock_list )

    def GetTaskClockDeviation( self ):
        return numpy.std( self.task_clock_list )

    def GetWallTimeMean( self ):
        return numpy.mean( self.wall_time_list )

    def GetWallTimeDeviation( self ):
        return numpy.std( self.wall_time_list )

class CBPOVTestData:
    def __init__( self, pov_id, cb_seed, pov_seed, pov_filename, pov_throw_number, did_fail, fail_reason, extra_data ):
        self.pov_id = pov_id
        self.cb_seed = cb_seed
        self.pov_seed = pov_seed
        self.pov_filename = pov_filename
        self.pov_throw_number = pov_throw_number

        self.did_pov_fail = did_fail

        self.fail_reason = fail_reason
        self.extra_data = extra_data

        self.pov_type = None

        self.signal = 0

    def DidFail( self ):
        if ( self.did_pov_fail ):
            return True
        else:
            return False

    def GetFailReason( self ):
        return self.fail_reason

    def GetExtraData( self ):
        return self.extra_data

    def SetPOVType( self, pov_type ):
        self.pov_type = pov_type

    def SetPOVSignal( self, signal ):
        self.signal = signal

    def GetPOVSignal( self ):
        return self.signal

    def GetPOVType( self ):
        if ( self.pov_type is None ):
            return 0
        else:
            return self.pov_type



class CBPollTestData:
    def __init__( self, poll_id, poll_seed, poll_filename ):
        self.poll_id = poll_id
        self.poll_seed = poll_seed
        self.poll_filename = poll_filename
       
        self.has_performance_data = False
        self.max_rss = None
        self.min_flt = None
        self.utime = None
        self.cpu_clock = None
        self.task_clock = None
        self.wall_time = None

        self.tests_passed = 0
        self.tests_failed = 0
        
        self.timeout = False
        self.fail_connect = False

        self.signal = 0
        
    def SetPerformanceData( self, max_rss, min_flt, utime, cpu_clock, task_clock, wall_time ):
        self.has_performance_data = True
        self.max_rss = max_rss
        self.min_flt = min_flt
        self.utime = utime
        self.cpu_clock = cpu_clock
        self.task_clock = task_clock
        self.wall_time = wall_time

    def GetPerformanceData( self ):

        if self.has_performance_data == False:
            return None

        performance_data = { 'max_rss': self.max_rss, 'min_flt': self.min_flt, 'utime': self.utime, 'cpu_clock': self.cpu_clock, 'task_clock': self.task_clock, 'wall_time': self.wall_time }

        return performance_data
        
    def SetExitCode( self, exit_code ):
        self.exit_code = exit_code

    def SetSignal( self, signal ):
        self.signal = signal

    def SetTestData( self, tests_passed, tests_failed ):
        self.tests_passed = tests_passed
        self.tests_failed = tests_failed

    def SetTimeout( self ):
        self.timeout = True

    def SetFailConnect( self ):
        self.fail_connect = True

    def DidFail( self ):
        # Fail on timeout
        if self.timeout:
            return True

        if self.fail_connect:
            return True

        # Fail if any tests failed
        if self.tests_failed > 0:
            return True

        # Fail if signal generated
        if self.signal != 0:
            return True

        return False

    def DidTimeout( self ):
        if self.timeout:
            return True
        else:
            return False

    def DidFailTests( self ):
        if self.tests_failed > 0:
            return True
        else:
            return False

    def DidSignal( self ):
        if self.signal != 0:
            return True
        else:
            return False

    def DidFailConnect( self ):
        if self.fail_connect:
            return True
        else:
            return False


# This class assists in running a CBTest -- it will generate results for Polls and POVs that are run
# by digesting the cb-server and cb-replay logs from a running container
class CBTestHelper:
    def __init__( self ):
        self.poll_result_list = { }
        self.pov_result_list = { }
        self.crash_result_list = [ ]

    def AddResults( self, cbreplay_results, cbserver_results ):

        # Begin by going over all cbreplay results -- and match them to a cbserver result 
        #-- FIRST DO POLLS
        poll_count = 0
        for poll_item in cbreplay_results.poll_result_list:
            cbreplay_poll_data = cbreplay_results.poll_result_list[poll_item]

            did_connect = True
            try:
                cbserver_poll_data = cbserver_results.cbserver_result_list[poll_item]
            except KeyError:
                did_connect = False

            # Create CBPollTestData
            poll_id = poll_item
            poll_seed = cbreplay_poll_data.poll_seed
            poll_filename = cbreplay_poll_data.filename

            poll_test_data = CBPollTestData( poll_id, poll_seed, poll_filename )

            if ( did_connect ):
                # TODO: Handle timeout for 
                if cbserver_poll_data.DidTimeout() or cbreplay_poll_data.DidPollTimeout():
                    poll_test_data.SetTimeout()
                elif cbreplay_poll_data.DidPollFail():
                    poll_test_data.SetFailConnect()
                else:
                    # Record tests passed/failed
                    poll_test_data.SetTestData( cbreplay_poll_data.tests_passed, cbreplay_poll_data.tests_failed )

                    if cbserver_poll_data.last_signal != 0:
                        # CB had non-zero signal (therefore crashed)
                        poll_test_data.SetSignal( cbserver_poll_data.last_signal )
                        
                        # Go thru crashes for this poll
                        for item in cbserver_poll_data.signal_list:
                            try:
                                cb_pid = item['pid']
                                cb_signal = item['signal']

                                cb_filename = cbserver_poll_data.GetFileNameForPID( cb_pid )

                                self.crash_result_list.append( {"cb_filename": cb_filename, 'signal': cb_signal, "timestamp": item['timestamp'] } )
                            except:
                                logging.error( "Error logging crash data while going over POLL data" )
                    else:
                        poll_test_data.SetExitCode( cbserver_poll_data.exit_code )

                    # Log any missing performance data
                    max_rss = cbserver_poll_data.max_rss
                    minor_faults = cbserver_poll_data.minor_faults
                    utime = cbserver_poll_data.utime
                    cpu_clock = cbserver_poll_data.cpu_clock
                    task_clock = cbserver_poll_data.task_clock
                    execute_time = cbreplay_poll_data.execute_time

                    if max_rss is None:
                        logging.info( "MAX RSS is None for poll (seed:%s)" % (binascii.hexlify(poll_seed)) )
                        max_rss = 0

                    if minor_faults is None:
                        logging.info( "Minor Faults is None for poll (seed:%s)" % (binascii.hexlify(poll_seed)) )
                        minor_faults = 0

                    if utime is None:
                        logging.info( "utime is None for poll (seed:%s)" % (binascii.hexlify(poll_seed)) )
                        utime = 0

                    if cpu_clock is None:
                        logging.info( "cpu_clock is None for poll (seed:%s)" % (binascii.hexlify(poll_seed)) )
                        cpu_clock = 0

                    if task_clock is None:
                        logging.info( "task_clock is None for poll (seed:%s)" % (binascii.hexlify(poll_seed)) )
                        task_clock = 0

                    if execute_time is None:
                        logging.info( "execute_time is None for poll (seed:%s)" % (binascii.hexlify(poll_seed)) )
                        execute_time = 0

                    # TODO Update this code so that if no performance data is available than do not add POLL

                    # Set performance data
                    poll_test_data.SetPerformanceData( max_rss, minor_faults, utime, cpu_clock, task_clock, execute_time )
                    
                    #poll_test_data.SetPerformanceData( cbserver_poll_data.max_rss, cbserver_poll_data.minor_faults, cbserver_poll_data.utime, cbserver_poll_data.cpu_clock, cbserver_poll_data.task_clock, cbreplay_poll_data.execute_time )
            else:
                # Failed to connect to cb-server
                poll_test_data.SetFailConnect()

            # Add poll item
            self.poll_result_list.update( {poll_id: poll_test_data} )

            poll_count += 1

        for pov_item in cbreplay_results.pov_result_list:
            cbreplay_pov_data = cbreplay_results.pov_result_list[pov_item]
           
            did_connect = True
            try:
                cbserver_pov_data = cbserver_results.cbserver_result_list[pov_item]
            except KeyError:
                did_connect = False

            pov_id = pov_item
            cb_seed = cbreplay_pov_data.cb_seed
            pov_seed = cbreplay_pov_data.pov_seed
            pov_filename = cbreplay_pov_data.pov_filename
            pov_throw_number = cbreplay_pov_data.pov_throw_count

            pov_test_data = None

            # Create CBPovTestData
            # First check pov_type
            # Check if cbserver timed out!!
            if did_connect == False:
                pov_test_data = CBPOVTestData( pov_id, cb_seed, pov_seed, pov_filename, pov_throw_number, True, "connect", None )
            elif cbreplay_pov_data.pov_data is None:
                pov_test_data = CBPOVTestData( pov_id, cb_seed, pov_seed, pov_filename, pov_throw_number, True, "negotiation failed", None )
            elif cbreplay_pov_data.did_timeout:
                pov_test_data = CBPOVTestData( pov_id, cb_seed, pov_seed, pov_filename, pov_throw_number, True, "timeout", "cbreplay timed out" )
            elif cbserver_pov_data.DidTimeout():
                pov_test_data = CBPOVTestData( pov_id, cb_seed, pov_seed, pov_filename, pov_throw_number, True, "timeout", "cbserver CB timed out" )
            elif cbreplay_pov_data.pov_data['pov_type'] is None:
                pov_test_data = CBPOVTestData( pov_id, cb_seed, pov_seed, pov_filename, pov_throw_number, True, "negotiation failed", None )
            elif cbreplay_pov_data.pov_data['pov_type'] == 1:
                # Check type 1
                ip_mask = cbreplay_pov_data.pov_data['ip_mask']
                reg_mask = cbreplay_pov_data.pov_data['reg_mask']

                ip_value = cbreplay_pov_data.pov_data['ip_value']
                reg_value = cbreplay_pov_data.pov_data['reg_value']
                reg_num = cbreplay_pov_data.pov_data['reg_num']

                expected_eip = ip_value & ip_mask
                expected_reg = reg_value & reg_mask

                # Get cbserver data
                if cbserver_pov_data.last_signal == 0:
                    # Failed to core
                    pov_test_data = CBPOVTestData( pov_id, cb_seed, pov_seed, pov_filename, pov_throw_number, True, "did not core", None )
                    pov_test_data.SetPOVType( 1 )
                else:
                    # Get register states...
                    reg_name_lookup = [ 'eax', 'ecx', 'edx', 'ebx', 'esp', 'ebp', 'esi', 'edi' ]

                    if ( reg_num >= 0 and reg_num <= 7 ):
                        if cbserver_pov_data.register_state is None:
                            pov_test_data = CBPOVTestData( pov_id, cb_seed, pov_seed, pov_filename, pov_throw_number, True, "POV generated signal but did not generate register states", None )

                            pov_test_data.SetPOVType( 1 )
                        else:
                            result_eip = cbserver_pov_data.register_state['eip'] & ip_mask
                            result_reg = cbserver_pov_data.register_state[reg_name_lookup[reg_num]] & reg_mask

                            if ( result_eip == expected_eip and result_reg == expected_reg ):
                                # TYPE 1 SUCCESS!
                                extra_string = "TYPE1: EXPECTED[%s: %08x | eip: %08x] GOT[%s: %08x | eip: %08x]" % (reg_name_lookup[reg_num], expected_reg, expected_eip, reg_name_lookup[reg_num], result_reg, result_eip)

                                pov_test_data = CBPOVTestData( pov_id, cb_seed, pov_seed, pov_filename, pov_throw_number, False, "OK - TYPE 1", extra_string )
                                pov_test_data.SetPOVType( 1 )
                            else:
                                # Failed... registers did not match
                                extra_string = "TYPE1: EXPECTED[%s: %08x | eip: %08x] GOT[%s: %08x | eip: %08x]" % (reg_name_lookup[reg_num], expected_reg, expected_eip, reg_name_lookup[reg_num], result_reg, result_eip)

                                pov_test_data = CBPOVTestData( pov_id, cb_seed, pov_seed, pov_filename, pov_throw_number, True, "invalid", extra_string )
                                pov_test_data.SetPOVType( 1 )
                    else:
                        # Failed -- for some reason the reg_num is invalid????
                        pov_test_data = CBPOVTestData( pov_id, cb_seed, pov_seed, pov_filename, pov_throw_number, True, "negotiation failed", None )
                        pov_test_data.SetPOVType( 1 )

            elif cbreplay_pov_data.pov_data['pov_type'] == 2:
                # Check type 2
                prng = ansi_x931_aes128.PRNG(cb_seed)

                flag_page = prng.get(0x1000)

                secret_value = cbreplay_pov_data.pov_data['secret_value']

                if secret_value in flag_page:
                    extra_string = "TYPE2: VALUE: %s in magic page" % (binascii.hexlify(secret_value))

                    pov_test_data = CBPOVTestData( pov_id, cb_seed, pov_seed, pov_filename, pov_throw_number, False, "OK - TYPE2", extra_string )
                    pov_test_data.SetPOVType( 2 )
                else:
                    extra_string = "TYPE2: VALUE: %s is not in magic page" % (binascii.hexlify(secret_value))

                    pov_test_data = CBPOVTestData( pov_id, cb_seed, pov_seed, pov_filename, pov_throw_number, True, "SECRET VALUE NOT FOUND", extra_string )
                    pov_test_data.SetPOVType( 2 )

            else:
                pov_test_data = CBPOVTestData( pov_id, cb_seed, pov_seed, pov_filename, pov_throw_number, True, "negotiation failed", None )

            # Set signal if it connected
            if did_connect:
                # Set PoV last signal
                pov_test_data.SetPOVSignal( cbserver_pov_data.last_signal )
                
                # Go thru crashes for this poll
                for item in cbserver_pov_data.signal_list:
                    try:
                        cb_pid = item['pid']
                        cb_signal = item['signal']

                        cb_filename = cbserver_pov_data.GetFileNameForPID( cb_pid )

                        self.crash_result_list.append( {"cb_filename": cb_filename, 'signal': cb_signal, "timestamp": item['timestamp'] } )
                    except:
                        logging.error( "Error logging crash data while going over POV data" )

            # Add pov item
            self.pov_result_list.update( {pov_id: pov_test_data} )

# This class assists in generating baseline poller performance data
class PollBaselineHelper:
    def __init__( self ):
        # This contains a list of poll performance data across multiple runs --of the same polls
        # for averaging the performance data
        self.baseline_data_set_exists = False
        self.poll_baseline_list = { }
        self.poll_discard_list = Set()

    def AddResults( self, cbreplay_results, cbserver_results ):
        # Begin by processing the results of cbreplay and cbserver
        poll_discard_list = [ ]

        # Extract poll data from cbreplay first...
        for item in cbreplay_results.poll_result_list:
            try:
                cbserver_data = cbserver_results.cbserver_result_list[item]
                cbreplay_data = cbreplay_results.poll_result_list[item]
            except KeyError:
                logging.error( "PollBaselineHelper::ProcessResults::Couldn't match up cbreplay data with cbserver data. Discarding this poll" )
                continue
            
            poll_seed = cbserver_data.seed

            if ( cbserver_data.seed != cbreplay_data.poll_seed ):
                # Log error -- we somehow missed 
                logging.warning( "PollBaselineHelper::ProcessResults::Failed to match cbserver data seed to cbreplay data seed by index... ignoring this poll. This could be a more serious issue?" )
                continue

            if poll_seed in self.poll_discard_list:
                # Poll already exists in discard list -- ignore it
                logging.warning( "PollBaselineHelper::ProcessResults::Poll was previously discarded, ignoring it" )
                continue
            
            poll_id = cbreplay_results.poll_result_list[item].poll_id

            # Check to make sure said poll DID PASS all functionality for us -- before taking baseline performance data
            if ( cbreplay_data.tests_failed > 0 ):
                # Log error -- we somehow have a poll that is not passing tests in our baseline of polls
                poll_discard_data = {'filename' : cbreplay_data.filename, 'seed' : poll_seed, "poll_id": poll_id}
                poll_discard_list.append( poll_discard_data )
                self.poll_discard_list.add( poll_seed )
                logging.warning( "PollBaselineHelper::ProcessResults::Poll is failing tests, perhaps performance issues? This poll will be ignored and added to discard list. (id=%d, seed=%s)" % (poll_id, binascii.hexlify(poll_seed) ) )
                continue

            if cbreplay_data.DidPollTimeout():
                # Log error -- poll timeout
                poll_discard_data = {'filename' : cbreplay_data.filename, 'seed' : poll_seed, "poll_id": poll_id}
                poll_discard_list.append( poll_discard_data )
                self.poll_discard_list.add( poll_seed )
                logging.warning( "PollBaselineHelper::ProcessResults::Poll is failing tests due to cb-replay timing out? This poll will be ignored and added to discard list. (id=%d, seed=%s)" % (poll_id, binascii.hexlify(poll_seed) ) )
                continue

            if cbreplay_data.DidPollFail():
                # Log error -- poll timeout
                poll_discard_data = {'filename' : cbreplay_data.filename, 'seed' : poll_seed, "poll_id": poll_id}
                poll_discard_list.append( poll_discard_data )
                self.poll_discard_list.add( poll_seed )
                logging.warning( "PollBaselineHelper::ProcessResults::Poll is failing tests due to a connection error? This poll will be ignored and added to discard list. (id=%d, seed=%s)" % (poll_id, binascii.hexlify(poll_seed) ) )
                continue

            if cbserver_data.DidTimeout():
                # Log error -- poll timeout
                poll_discard_data = {'filename' : cbreplay_data.filename, 'seed' : poll_seed, "poll_id": poll_id}
                poll_discard_list.append( poll_discard_data )
                self.poll_discard_list.add( poll_seed )
                logging.warning( "PollBaselineHelper::ProcessResults::Poll is failing tests due to cb-server timing out? This poll will be ignored and added to discard list. (id=%d, seed=%s)" % (poll_id, binascii.hexlify(poll_seed) ) )
                continue

            poll_performance_baseline = None

            if self.baseline_data_set_exists == False:
                # Create new performance data for this poll seed
                poll_performance_baseline = PollPerformanceBaselineSet( cbreplay_results.poll_result_list[item].poll_id, poll_seed )

                # Add this dataset into the list
                self.poll_baseline_list.update( {poll_seed:poll_performance_baseline} )
            else:
                # Find the existing baseline in the data set
                try:
                    poll_performance_baseline = self.poll_baseline_list[poll_seed]
                except KeyError:
                    logging.warning( "PollBaselineHelper::ProcessResults::New poll seed not in baseline set after baseline set already exists? (id=%d, seed=%s)" % (poll_id, binascii.hexlify(poll_seed) ) )
                    continue

            # Set performance metrics
            poll_performance_baseline.AddPerformanceSet( cbserver_data.max_rss, cbserver_data.minor_faults, cbserver_data.utime, cbserver_data.cpu_clock, cbserver_data.task_clock, cbreplay_data.execute_time )

            # Update poll_pass_list
            #poll_pass_list.append( {'filename': cbreplay_data.filename, 'seed': poll_seed, 'poll_id': poll_id} )

        self.baseline_data_set_exists = True

        # Return a list of any discarded polls!!
        return poll_discard_list

    def GetBaselinePerformance( self ):
        return self.poll_performance_baseline

    def DisplayBaselineData( self ):
        # Generate a baseline data set -- including means and standard deviation
        for poll_seed in self.poll_baseline_list:
            #poll_performance_dict.update( {poll_seed: PollPerformanceBaselineSet( 
            performance_data = self.poll_baseline_list[poll_seed]

            print "POLL [ID=%d][seed=%s][MAXRSS=%d DEV=%f][MINFLT=%d DEV=%f][UTIME=%f DEV=%f][CPU_CLOCK=%d DEV=%f][TASK_CLOCK=%d DEV=%f][WALL_TIME=%f DEV=%f]\n" % (performance_data.GetPollID(), binascii.hexlify(poll_seed), performance_data.GetMaxRSSMean(), performance_data.GetMaxRSSDeviation(), performance_data.GetMinorFaultsMean(), performance_data.GetMinorFaultsDeviation(), performance_data.GetUTimeMean(), performance_data.GetUTimeDeviation(), performance_data.GetCPUClockMean(), performance_data.GetCPUClockDeviation(), performance_data.GetTaskClockMean(), performance_data.GetTaskClockDeviation(), performance_data.GetWallTimeMean(), performance_data.GetWallTimeDeviation() )

    
def TestWithPOVData():
    cbserver_data = ''
    with open('cbserver_with_pov.log', 'r') as fh:
        cbserver_data = fh.read()

    print "Read length=%d\n" % len(cbserver_data)
    cbserver_results = CBServerResults( cbserver_data )
   
    '''
    for item in cbserver_results.cbserver_result_list:
        print "CB Server Item: %s" % binascii.hexlify(item)
        print cbserver_results.cbserver_result_list[item].GetCBServerDataString()
    '''

    replay_data = ''
    with open('cbreplay_with_pov.log', 'r') as fh:
        replay_data = fh.read()

    cbreplay_results = CBReplayResults( replay_data )

    print "Done\n"

    test_helper = CBTestHelper( )

    test_helper.AddResults( cbreplay_results, cbserver_results )
        
if __name__ == "__main__":

    TestWithPOVData()

    '''
    cbserver_data = ''
    with open('cbserver_results.txt', 'r') as fh:
        cbserver_data = fh.read()

    print "Read length=%d\n" % len(cbserver_data)
    cbserver_results = CBServerResults( cbserver_data )

    for item in cbserver_results.cbserver_result_list:
        print "CB Server Item: %d" % item
        print cbserver_results.cbserver_result_list[item].GetCBServerDataString()
    
    replay_data = ''
    with open('results.txt', 'r') as fh:
        replay_data = fh.read()

    poll_results = CBReplayResults( replay_data )

    for item in poll_results.poll_result_list:
        print poll_results.poll_result_list[item].GetPollDataString()

    # Generate baseline aggregate data
    poll_baseline_data = PollBaselineHelper()
    poll_baseline_data.AddResults( poll_results, cbserver_results )

    replay_data = ''
    with open('results2.txt', 'r') as fh:
        replay_data = fh.read()

    poll2_results = CBReplayResults( replay_data )

    poll_baseline_data.AddResults( poll2_results, cbserver_results )
    poll_baseline_data.AddResults( poll_results, cbserver_results )

    poll_baseline_data.DisplayBaselineData()
    '''
