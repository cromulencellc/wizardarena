#!/usr/bin/env python

# database.py
#
# Contains functionality for managing the backend database connection
#
#
import functools
import hashlib
import os
import shutil
import errno
import sys
import random
import logging
from database import WADBEngine
import time
import settings
from datetime import datetime
import binascii
import wa_container
import replay_helper
from Queue import Queue
from threading import Thread

# Get a logger for the engine
logger = logging.getLogger('WAEngine')

def RunTestWorker( q, db, docker, timeout ):
    while True:
        # Get the arguments for this test -- it will block here
        run_test_arguments = q.get()

        # Remember time for timeout enforcement
        start_time = time.time()

        # Start the worker container
        cs_id = run_test_arguments["cs_id"]

        # Connection ID is used by the IDS to start the connection ID number for each connection thru the IDS -- use this to parallelize connections
        connection_id = run_test_arguments["connection_id"]

        round_id = run_test_arguments["round_id"]
        team_id = run_test_arguments["team_id"]

        # Label the containers
        run_label = "RUN_RND%d_CSID%d_TID%d" % (round_id, cs_id, team_id)

        # MAKE SURE THAT the TEAM ID in the database matches with the IP addresses
        ids_pcap_host = "10.5.%d.2" % (team_id)

        retry_count = 3
        try_count = 0
        for _ in range(retry_count):
            # Record tries 
            try_count += 1

            # Attempt to retry start of this container
            try:
                #logger.info( "RUNTESTPOLL ARGS: {} {} {} {} {} {} {} {} {} {} {} {} {} {} {}".format(cs_id, connection_id, run_test_arguments["container_name"], run_test_arguments["throw_count"], run_test_arguments["round_seed"], run_test_arguments["round_secret"], run_label, run_test_arguments["ids_dir"], run_test_arguments["ids_rule_filename"], run_test_arguments["cb_dir"], run_test_arguments["cb_filename"], run_test_arguments["poll_source_dir"], run_test_arguments["pov_source_dir"], run_test_arguments["split_start_pos"], run_test_arguments["split_end_pos"], ids_pcap_host, settings.IDS_PCAP_PORT ) )

                time.sleep( 0.1 )

                run_results = docker.RunTestPolls( cs_id, connection_id, run_test_arguments["container_name"], run_test_arguments["throw_count"], run_test_arguments["round_seed"], run_test_arguments["round_secret"], run_label, run_test_arguments["ids_dir"], run_test_arguments["ids_rule_filename"], run_test_arguments["cb_dir"], run_test_arguments["cb_filename"], run_test_arguments["poll_source_dir"], run_test_arguments["pov_source_dir"], run_test_arguments["split_start_pos"], run_test_arguments["split_end_pos"], ids_pcap_host, settings.IDS_PCAP_PORT )

                # Continue until timed out
                force_stop = True
                while time.time() < (start_time+timeout):
                    # Monitor the container
                    container_info = docker.GetContainerInfo( run_results[2] )

                    if docker.IsContainerExited( container_info ):
                        force_stop = False
                        break
                    else:
                        time.sleep( 2 )

                if force_stop:
                    logger.error( "Engine::WORKER::Forced stop!!!" )

                # Wait for logs to catch up
                time.sleep( 4 )

                # Now get the logs of performance data!
                cbreplay_logs = docker.GetContainerLogs( run_results[2] )
                cbserver_logs = docker.GetContainerLogs( run_results[0] )
        
                cbreplay_results = replay_helper.CBReplayResults( cbreplay_logs )
                cbserver_results = replay_helper.CBServerResults( cbserver_logs )
                
                # ENABLE this to turn on detailed container logging
                '''
                log_path = "container_logs/" + run_test_arguments['container_name']
                with open( log_path+"_cbreplay.log", "w" ) as fh:
                        fh.write( cbreplay_logs )

                with open( log_path+"_cbserver.log", "w" ) as fh:
                        fh.write( cbserver_logs )
                '''

                # Kill all containers
                docker.KillAndRemoveContainer( run_results[0] )
                docker.KillAndRemoveContainer( run_results[1] )
                docker.KillAndRemoveContainer( run_results[2] )

                # Process logs
                test_helper = replay_helper.CBTestHelper( )

                test_helper.AddResults( cbreplay_results, cbserver_results )

                # Process POV's first
                for pov_item in test_helper.pov_result_list:
                    try:
                        pov_data = test_helper.pov_result_list[pov_item]
                    except KeyError:
                        logger.critical( "RunTestWorker::Failed with key error when getting pov item in pov_result_list!" )
                        continue

                    cb_seed = pov_data.cb_seed
                    pov_seed = pov_data.pov_seed

                    if ( pov_data.DidFail() ):
                        pov_success = False

                        fail_reason = pov_data.GetFailReason()

                        if ( fail_reason == "negotiation failed" ):
                            pov_error = "protocol" # Default to always protocol errors for negotiation failed
                        else:
                            pov_error = "unsuccessful" # Everything else, invalid registers, failed to crash, invalid type 2 data, etc.

                    else:
                        pov_success = True
                        pov_error = ""

                    pov_signal = pov_data.GetPOVSignal()
                    pov_type = pov_data.GetPOVType()
                    pov_extra_error = pov_data.GetExtraData()

                    # Parse POV Filename to get from team ID
                    pov_filename = pov_data.pov_filename

                    find_fromtid_pos = pov_filename.find('_FROMTID')
                    if ( find_fromtid_pos >= 0 ):
                        find_end_fromtid_pos = pov_filename.find( '_', find_fromtid_pos+8 )

                        if ( find_end_fromtid_pos >= 0 ):
                            pov_from_tid = int(pov_filename[find_fromtid_pos+8:find_end_fromtid_pos])
                        else:
                            logger.critical( "RunTestWorker::Failed to find end from TID for pov filename -- skipping!" )
                            continue
                    else:
                        logger.critical( "RunTestWorker::Failed to find from TID for pov filename -- skipping!" )
                        continue

                    db.AddProofFeedback( round_id, cs_id, team_id, pov_from_tid, cb_seed, pov_seed, pov_success, pov_error, pov_extra_error, pov_signal, pov_type )

                # Process POLL's next
                poll_count = 0
                for poll_item in test_helper.poll_result_list:
                    try:
                        poll_data = test_helper.poll_result_list[poll_item]
                    except KeyError:
                        logger.critical( "RunTestWorker::Failed with key error when getting poll item in poll_result_list!" )
                        continue

                    poll_seed = poll_data.poll_seed

                    poll_id = db.GetPollIDFromSeed( round_id, cs_id, poll_seed )

                    if poll_id is None:
                        logger.critical( "RunTestWorker::Failed to find poll in Pollers database entry? ignoring (round_id=%d, cs_id=%d, seed=%s)", round_id, cs_id, binascii.hexlify(poll_seed) )
                        continue

                    if poll_data.DidFail():
                        if poll_data.DidTimeout():
                            poll_status = "timeout"
                        elif poll_data.DidFailTests():
                            poll_status = "functionality"
                        elif poll_data.DidSignal():
                            poll_status = "connect"
                        else:
                            poll_status = "bad"
                    else:
                        poll_status = "success"

                    if poll_status == "success":
                        # Update with performance data
                        poll_performance_data = poll_data.GetPerformanceData()

                        performance_max_rss = poll_performance_data['max_rss']
                        performance_min_flt = poll_performance_data['min_flt']
                        performance_utime = poll_performance_data['utime']
                        performance_cpu_clock = poll_performance_data['cpu_clock']
                        performance_task_clock = poll_performance_data['task_clock']
                        performance_wall_time = poll_performance_data['wall_time']

                        db.AddPollFeedbackOnSuccess( poll_id, team_id, poll_status, performance_max_rss, performance_min_flt, performance_utime, performance_cpu_clock, performance_task_clock, performance_wall_time )

                    else:
                        db.AddPollFeedbackOnFailure( poll_id, team_id, poll_status )

                    poll_count += 1

                # Add Crashes
                challenge_binary_index_list = db.GetChallengeBinaryIndexIDList( cs_id )

                # Build a quick lookup for filename's to CB ID's
                if challenge_binary_index_list is None:
                    logger.critical( "RunTestWorker::Failed to get challenge binary ID index list -- entries do not exist for CS (cs_id=%d)?" % cs_id )
                else:
                    compare_list = { }
                    cs_filename = db.GetChallengeNameForID( cs_id )

                    if len(challenge_binary_index_list) == 1:
                        compare_list.update( {cs_filename: challenge_binary_index_list[0]['id'] } )
                    else:
                        # Multi binary service -- build a dictionary of filename's and CB ID's
                        for item in challenge_binary_index_list:
                            full_filename = ("%s_%d" % (cs_filename, item['index']))

                            compare_list.update( {full_filename: item['id'] } )

                    for crash_item in test_helper.crash_result_list:
                        cb_id = None

                        try:
                            cb_id = compare_list[crash_item['cb_filename']]
                        except KeyError:
                            logger.critical( "Error -- could not lookup filename for crashing file in compare list (filename=%s, signal=%d, cs_id=%d)" % (crash_item['cb_filename'], crash_item['signal'], cs_id) )
                            continue

                        # Add crash item to database by cb ID
                        db.AddCrashFeedback( round_id, team_id, cb_id, crash_item['signal'], crash_item['timestamp'] )

                # Indicate no docker errors
                container_start_fail = False

            except KeyError, e:
                logger.info( "Engine::WORKER::KeyError::Reason %s" % str(e) )

                time.sleep( 12 )

                docker.RemoveContainerByName( run_test_arguments["container_name"]+"_cbserver" )
                docker.RemoveContainerByName( run_test_arguments["container_name"]+"_cbreplay" )
                docker.RemoveContainerByName( run_test_arguments["container_name"]+"_cbids" )

                # Failed... to start
                container_start_fail = True

            except:
                logger.error( "Engine::WORKER::Failed to start RunTestPolls (container group) -- attempting LAST level recovery [EXCEPTION: %s]", sys.exc_info()[0] )

                time.sleep( 12 )

                docker.RemoveContainerByName( run_test_arguments["container_name"]+"_cbserver" )
                docker.RemoveContainerByName( run_test_arguments["container_name"]+"_cbreplay" )
                docker.RemoveContainerByName( run_test_arguments["container_name"]+"_cbids" )

                # Failed... to start
                container_start_fail = True

            if container_start_fail is True:
                time.sleep( 5 )
            else:
                break
                
        if try_count >= retry_count:
            logger.critical( "Engine::WORKER::Retries failed for RunTestPolls (container group) -- aborting recovery -- this task will be lost (%s)" % run_test_arguments["container_name"] )
            
        # Complete task
        q.task_done()

class WAEngine():
    def __init__(self):
        # Create db connection
        self.db = WADBEngine()

        # Create docker engine connection
        self.docker = wa_container.CBDockerEngine( settings.DOCKER_HOST_ADDRESS, settings.DOCKER_CERT_PATH, settings.TOOL_FOLDER_PATH, settings.IMAGE_FOLDER_PATH, settings.DOCKER_REPO_NAME ) 

    def GetAgentCoresAvailable(self):
        docker_info_data = self.docker.GetDockerInfo()

        docker_driver_status = docker_info_data['DriverStatus']

        swarm_cpu_count = docker_info_data['NCPU']


        return swarm_cpu_count

    def SetFileExecutable( self, file_path ):
        try:
            mode = os.stat( file_path ).st_mode
            mode |= (mode & 0o444) >> 2    # copy R bits to X
            os.chmod( file_path, mode )
        except OSError as e:
            raise
             

    def ForceMoveFile( self, source, dest ):
        if not os.path.exists(os.path.dirname(dest)):
            try:
                os.makedirs(os.path.dirname(dest))
            except OSError as e:
                # IGNORE if it already exists
                if e.errno != errno.EEXIST:
                    raise

        try:
            os.renames( source, dest )
        except OSError as e:
            if e.errno == errno.ENOENT:
                logger.critical( "ENGINE::ForceMoveFile (scoot?) file %s does not exist -- won't be scooted -- this may cause a future engine failure" % (source) )
            else:
                raise

        return True

    def CreateResolvedSymlink( self, source, link_name ):
        try:
            if os.path.islink( source ):
                dest_link = os.readlink( source )
                os.symlink( dest_link, link_name )
            else:
                os.symlink( source, link_name )
        except OSError as e:
            raise

    def CreateWorkingFolder( self, round_id ):
        try:
            shutil.rmtree( settings.GetWorkingFolderDir() )
        except OSError as e:
            if e.errno == errno.ENOENT:
                pass
            else:
                raise

        try:
            shutil.copytree( settings.GetEngineInprogressRoundDir( round_id ), settings.GetWorkingFolderDir() )
        except OSError as e:
            if e.errno == errno.ENOENT:
                logger.info( "ENGINE::CreateWorkingFolder::No inprogress folder, most likely no challenges were enabled in this round?" )
            else:
                raise

    def ForceCreateSymlink( self, source, link_name ):
        # Force a symlink -- even if a file/link already exists -- replace it!
        try:
            self.CreateResolvedSymlink( source, link_name )
        except OSError as e:
            if e.errno == errno.EEXIST:
                os.remove( link_name )
                self.CreateResolvedSymlink( source, link_name )

    def MoveTeamInterfaceIncomingFolder( self, round_id ):
        # First remove the teaminterface save round dir -- if it exists
        try:
            shutil.rmtree( settings.GetTeamInterfaceSaveRoundDir( round_id ) )
        except OSError as e:
            if e.errno == errno.ENOENT:
                pass
            else:
                raise

        # Next move the incoming directory to the save round directory
        try:
            os.renames( settings.GetTeamInterfaceIncomingDir(), settings.GetTeamInterfaceSaveRoundDir( round_id ) )
        except OSError as e:
            if e.errno == errno.ENOENT:
                logger.info( "ENGINE::TransitionRound::MoveTeamInterfaceIncomingFolder::Error, missing teaminterface incoming/ folder, perhaps nothing was uploaded this round (round_id=%d)" % (round_id) )
            elif e.errno == errno.ENOTEMPTY:
                logger.critical( "ENGINE::TransitionRound::MoveTeamInterfaceIncomingFolder::Error, directory already exists for teaminterface round, it should have been removed!?! (round_id=%d)" % (round_id) )
                raise

            else:
                raise

    def DoSHA256File( self, filename, chunk_size=65536 ):
        file_digest = hashlib.sha256()
        try:
            with open( filename, 'rb' ) as f:
                [file_digest.update(chunk) for chunk in iter(functools.partial(f.read, chunk_size), '')]
        except OSError as e:
            if e.errno == errno.ENOENT:
                return None
            else:
                raise

        return file_digest.digest()

    def DoGetFileSize( self, filename ):
         try:
             st = os.stat( filename )
             return st.st_size
         except OSError as e:
             if e.errno == errno.ENOENT:
                 return None
             else:
                 raise

    def TransitionRound( self, last_round_number, next_round_number, scoot_to_folder = settings.GetTeamInterfaceIncomingDir( ) ):
        # last_round_number contains the round number for the round that was just executed
        # next_round_number contains the round number for the round that is about to begin

        # Check enablements for the next round to determine which CS's are enabled 
        team_id_list = self.db.GetTeamIDList()

        # Move the teaminterface/incoming folder off to the old round
        if last_round_number > 0:
            self.MoveTeamInterfaceIncomingFolder( last_round_number )

        # Clear out inprogress folder for next round
        try:
            shutil.rmtree( settings.GetEngineInprogressRoundDir( next_round_number ) )
        except OSError as e:
            if e.errno == errno.ENOENT:
                pass
            else:
                raise

        logger.info( "ENGINE::TransitionRound::[TRANSITION %d->%d]\n" % (last_round_number, next_round_number) )
        # Transition each team
        for team_id in team_id_list:
            #logger.info( "ENGINE::TransitionRound::[TRANSITION %d->%d] Transition Team ID: %d\n" % (last_round_number, next_round_number, team_id) )

            # Get the next round number for active challenges
            cs_id_list = self.db.GetActiveChallengeSetIDList(next_round_number)

            # Transition each challenge set
            for cs_id in cs_id_list:
                # OK start transition for this challenge set

                # First make any directories necessary...
                # CB DIRECTORY
                try:
                    cb_new_dir = settings.GetCBDir( next_round_number, team_id, cs_id )
                    os.makedirs( cb_new_dir )
                except OSError as e:
                    if e.errno == errno.EEXIST and os.path.isdir( cb_new_dir ):
                        pass
                    else:
                        raise

                # IDS DIRECTORY
                try:
                    ids_new_dir = settings.GetIDSDir( next_round_number, team_id, cs_id )
                    os.makedirs( ids_new_dir )
                except OSError as e:
                    if e.errno == errno.EEXIST and os.path.isdir( ids_new_dir ):
                        pass
                    else:
                        raise

                # POV DIRECTORY
                try:
                    pov_new_dir = settings.GetPOVDir( next_round_number, team_id, cs_id )
                    os.makedirs( pov_new_dir )
                except OSError as e:
                    if e.errno == errno.EEXIST and os.path.isdir( pov_new_dir ):
                        pass
                    else:
                        raise

                # Remember cs base filename
                cs_filename = self.db.GetChallengeNameForID( cs_id )
                if cs_filename is None:
                    logger.critical( "ENGINE::TransitionRound::Could not get name for challenge set? DB error" )
                    continue
               
                # Get list of binaries for CS
                cs_binary_index_list = self.db.GetChallengeBinaryIndexList( cs_id )

                if cs_binary_index_list is None:
                    logger.critical( "ENGINE::TransitionRound::Challenge set exists in database without challenge_binaries entry!?! (cs_id=%d)" % cs_id )
                    continue

                # Check if this is the first time challenge set has been enabled
                if self.db.WasCSEnabledForRound( cs_id, next_round_number ):
                    # Fetch CB's from challenge base directory -- and start
                    for orig_binary_index in cs_binary_index_list:
                        # Check for multibinary
                        orig_cb_filename = cs_filename
                        if len(cs_binary_index_list) > 1:
                            orig_cb_filename += "_%d" % orig_binary_index

                        # Now copy it
                        self.ForceCreateSymlink( settings.GetChallengeSetBuildCBDir( cs_filename ) + orig_cb_filename, settings.GetCBDir( next_round_number, team_id, cs_id ) + orig_cb_filename )

                    # Create a blank IDS rule (base rules are blank)
                    try:
                        open( settings.GetIDSDir( next_round_number, team_id, cs_id ) + "rules.ids", 'w' ).close()
                    except OSError as e:
                        logger.error( "ENGINE::TransitionRound::Creating empty IDS rules for newly enabled CS failed! (cs_id=%d, team_id=%d, round_id=%d)" % (cs_id, team_id, next_round_number) )

                    # SKIP remaining tasks -- there are no RCB's, IDS rules, or POV's
                    #logger.info( "ENGINE::TransitionRound::New CS (cs_id=%d) enabled next round (round_id=%d)" % (cs_id, next_round_number) )
                    continue

                # Check if this CS was enabled last round -- special case -- don't allow IDS/RCB's yet -- carry them over! (DO ALLOW POV)
                if self.db.WasCSEnabledForRound( cs_id, last_round_number ):
                    carryover_ids_rcb = True
                else:
                    carryover_ids_rcb = False

                # Transition Challenge Binaries
                # Make sure the availability is 0 if a replacement CB comes in for a specific CS for the last round
                cb_replacement_id_list = self.db.GetReplacementsIDListForTeamCS( last_round_number, cs_id, team_id )

                if cb_replacement_id_list is None:
                    logger.critical( "ENGINE::TransitionRound::Critical database error, cannot perform replacements transition. (round=%d, cs_id=%d, team_id=%d)" % (last_round_number, cs_id, team_id ) )
                elif len(cb_replacement_id_list) > 0:
                    # Replace binaries in engine inprogress folder -- NOTE: Engine worker thread will enforce availability of 0 on the next round by not spinning up this CS for this Team

                    rcb_replaced_index_list = [ ]
                    for cb_replacement_id in cb_replacement_id_list:
                        replacement_cb_data = self.db.GetReplacementCBDataForID( cb_replacement_id )

                        if replacement_cb_data is None:
                            logger.critical( "ENGINE::TransitionRound::Critical database error, GetReplacementCBDataForID failed?" )
                            continue

                        replacement_cb_id = replacement_cb_data[0]
                        replacement_cb_digest = binascii.unhexlify(replacement_cb_data[1])
                        replacement_cb_size = replacement_cb_data[2]
                        replacement_cb_index = replacement_cb_data[3]

                        if replacement_cb_index == 0:
                            # Single binary service
                            replacement_cb_filename = cs_filename
                        else:
                            replacement_cb_filename = "%s_%d" % (cs_filename, replacement_cb_index)

                        # Create symbolic link to the replacement CB in the engine inprogress folder -- check size/digest as well
                        # CHECK digest
                        replacement_cb_fullpath = settings.GetTeamInterfaceSaveRCBDir( last_round_number, team_id ) + replacement_cb_filename

                        file_digest = self.DoSHA256File( replacement_cb_fullpath )
                        if file_digest is None:
                            logger.critical( "ENGINE:TransitionRound::Critical error, could not digest RCB during transition (file=%s), file not found?" % (replacement_cb_fullpath) )
                            continue

                        if file_digest != replacement_cb_digest:
                            logger.critical( "ENGINE::TransitionRound::Critical error, file digest did not match digest in database for filename (file=%s, file_digest=%s, database_digest=%s), ignoring" % (replacement_cb_fullpath, binascii.hexlify(file_digest), binascii.hexlify(replacement_cb_digest)) )
                            continue

                        # CHECK size
                        file_size = self.DoGetFileSize( replacement_cb_fullpath )

                        if file_size is None:
                            logger.critical( "ENGINE:TransitionRound::Critical error, could not get RCB file size during transition (file=%s), file not found?" % (replacement_cb_fullpath) )
                            continue

                        if file_size != replacement_cb_size:
                            logger.critical( "ENGINE::TransitionRound::Critical error, file size did not match file size in database for filename (file=%s), ignoring" % (replacement_cb_fullpath) )
                            continue

                        if carryover_ids_rcb:

                            if self.db.CheckForFutureReplacementForID( replacement_cb_id, next_round_number ):
                                self.db.DeleteReplacementForID( replacement_cb_id )
                                logger.info( "ENGINE::TransitionRound::A replacement already exists for the next round during a scoot. This replacement will be removed (%d) and no scoot will occur" % (replacement_cb_id) )
                            else:
                                # THIS ensures that a newly released CS cannot be replaced in the round after it was released to allow one round of POV scoring on the original CB's
                               
                                # Update and database to indicate scoot!
                                self.db.ScootRCBToRound( replacement_cb_id, next_round_number )

                                # Move file to incoming/ for teaminterface -- make sure to create the directory if it doesn't already exist
                                self.ForceMoveFile( settings.GetTeamInterfaceSaveRCBDir( last_round_number, team_id ) + replacement_cb_filename, scoot_to_folder + ("/%d/rcb/" % team_id) + replacement_cb_filename )
                                #logger.info( "SCOOTING RCB (%s -> %s)" % (settings.GetTeamInterfaceSaveRCBDir( last_round_number, team_id ) + replacement_cb_filename, scoot_to_folder + ("/%d/rcb/" % team_id) + replacement_cb_filename) )

                        else:
                            # Perform replacement and record our replacement

                            # Set uploaded RCB to executable
                            self.SetFileExecutable( settings.GetTeamInterfaceSaveRCBDir( last_round_number, team_id ) + replacement_cb_filename )

                            # Create symlink to uploaded RCB
                            self.ForceCreateSymlink( settings.GetTeamInterfaceSaveRCBDir( last_round_number, team_id ) + replacement_cb_filename, settings.GetCBDir( next_round_number, team_id, cs_id ) + replacement_cb_filename )

                            # Add to the list of items we have already replaced
                            rcb_replaced_index_list.append( replacement_cb_index )

                    # Copy over last rounds remaining
                    for orig_binary_index in cs_binary_index_list:
                        # Check if the orig binary was replaced -- if it was skip it
                        if orig_binary_index in rcb_replaced_index_list:
                            continue

                        orig_cb_filename = cs_filename
                        if len(cs_binary_index_list) > 1:
                            orig_cb_filename += "_%d" % orig_binary_index

                        # Now copy it
                        self.ForceCreateSymlink( settings.GetCBDir( last_round_number, team_id, cs_id ) + orig_cb_filename, settings.GetCBDir( next_round_number, team_id, cs_id ) + orig_cb_filename )
                else:
                    # Carryover anything from the previous round (if it exists) using symlink's
                    if len(cs_binary_index_list) > 1:
                        # Multi-binary challenge set
                        base_filename = cs_filename
                        for binary_index in cs_binary_index_list:
                            cb_filename = ("%s_%d" % (base_filename, binary_index))

                            # Create a symlink in the next rounds cb directory to the previous rounds CB
                            self.ForceCreateSymlink( settings.GetCBDir( last_round_number, team_id, cs_id ) + cb_filename, settings.GetCBDir( next_round_number, team_id, cs_id ) + cb_filename )

                    else:
                        # Single binary challenge set
                        self.ForceCreateSymlink( settings.GetCBDir( last_round_number, team_id, cs_id ) + cs_filename, settings.GetCBDir( next_round_number, team_id, cs_id ) + cs_filename )



                # Transition Firewall (IDS) rule
                firewall_data = self.db.GetFirewallDataForTeamCSForRound( last_round_number, team_id, cs_id )

                if firewall_data:
                    firewall_id = firewall_data[0]
                    firewall_digest = binascii.unhexlify(firewall_data[1])

                    firewall_full_path = settings.GetTeamInterfaceSaveIDSDir( last_round_number, team_id ) + ("%d.ids" % cs_id)

                    firewall_file_digest = self.DoSHA256File( firewall_full_path )

                    if firewall_file_digest is not None:
                        if firewall_file_digest == firewall_digest:

                            if carryover_ids_rcb:
                                if self.db.CheckForFutureFirewallForID( firewall_id, next_round_number ):
                                    self.db.DeleteFirewallForID( firewall_id )
                                    logger.info( "ENGINE::TransitionRound::A firewall already exists for the next round during a scoot. This firewall will be removed (%d) and no scoot will occur" % (firewall_id) )
                                else:
                                    # Do not replace firewall data -- instead scoot it to the next round
                                    # Update and database to indicate scoot!
                                    self.db.ScootFirewallToRound( firewall_id, next_round_number )

                                    # Move file to incoming/ for teaminterface -- make sure to create the directory if it doesn't already exist
                                    self.ForceMoveFile( settings.GetTeamInterfaceSaveIDSDir( last_round_number, team_id ) + ("%d.ids" % cs_id), scoot_to_folder + ("/%d/ids/" % team_id) + ("%d.ids" % cs_id) )
                                    
                                    #logger.info( "SCOOTING FIREWALL (%s -> %s)" % (settings.GetTeamInterfaceSaveIDSDir( last_round_number, team_id ) + ("%d.ids" % cs_id), scoot_to_folder + ("/%d/ids/" % team_id) + ("%d.ids" % cs_id)) )


                            else:
                                # Replace firewall data
                                self.ForceCreateSymlink( firewall_full_path, settings.GetIDSDir( next_round_number, team_id, cs_id ) + "rules.ids" )
                        else: 
                            logger.critical( "ENGINE::TransitionRound::Critical error, file digest for firewall rule did not match digest in database for filename (file=%s), ignoring" % (firewall_full_path) )
                    else: 
                        logger.critical( "ENGINE:TransitionRound::Critical error, could not digest Firewall during transition (file=%s), file not found?" % (firewall_full_path) )

                else:
                    firewall_data = self.db.GetActiveFirewallDataForTeamCS( last_round_number, team_id, cs_id )

                    if firewall_data:
                        firewall_digest = binascii.unhexlify(firewall_data[1])

                        # Get path
                        firewall_file_path = settings.GetIDSDir( last_round_number, team_id, cs_id ) + "rules.ids"

                        # Check digest
                        firewall_file_digest = self.DoSHA256File( firewall_file_path )

                        # Transition old firewall data
                        self.ForceCreateSymlink( firewall_file_path, settings.GetIDSDir( next_round_number, team_id, cs_id ) + "rules.ids" )

                # Transition POV's
                proof_list = self.db.GetProofDataForTeamCS( last_round_number, team_id, cs_id )

                proof_replace_list = []
                for proof_data in proof_list:
                    proof_id = proof_data[0]
                    proof_digest = binascii.unhexlify(proof_data[1])
                    proof_from_tid = proof_data[2]
                    proof_throws = proof_data[3]

                    # REMINDER: Proofs are in incoming by "FROM TEAM ID" \rounds\<rnd id>\<team id>\pov\<cs id>\<target team id>.pov
                    # SO WE NEED TO FIND proofs targetting this TEAM_ID FROM FROM_TID
                    proof_full_path = settings.GetTeamInterfaceSavePOVDir( last_round_number, proof_from_tid, cs_id ) + ("%d.pov" % team_id)

                    proof_file_digest = self.DoSHA256File( proof_full_path )

                    if proof_file_digest is not None:
                        if proof_file_digest == proof_digest:
                            if proof_from_tid != team_id:
                                # Replacement Proof Data
                                # Set uploaded RCB to executable
                                self.SetFileExecutable( proof_full_path )
                                
                                # Create symlink to it in engine inprogress folder 
                                self.ForceCreateSymlink( proof_full_path, settings.GetPOVDir( next_round_number, team_id, cs_id ) + ("pov_FROMTID%d_THROW%d.pov" % (proof_from_tid, proof_throws)) )

                                #logger.info( "ENGINE::TransitionRound[%d -> %d]::Replacing POV for team_id=%d, from_id=%d, cs_id=%d, [%s -> %s]" % (last_round_number, next_round_number, team_id, proof_from_tid, cs_id, proof_full_path, settings.GetPOVDir( next_round_number, team_id, cs_id ) + ("pov_FROMTID%d_THROW%d.pov" % (proof_from_tid, proof_throws))) )

                                # Add to replace list (from TID)
                                proof_replace_list.append( proof_id )
                            else:
                                logger.critical( "ENGINE::TransitionRound::Critical error, POV thrown from team to the same target team_id (proof_id=%d), ignoring" % (proof_id) )

                        else:
                            logger.critical( "ENGINE::TransitionRound::Critical error, POV file digest did not match digest in database for filename (file=%s), ignoring" % (proof_full_path) )
                    else:
                        logger.critical( "ENGINE::TransitionRound::Critical error, Could not digest POV file during transition (file=%s), file not found?" % (proof_full_path) )

                # Transition any POV's that haven't already been transitioned from the last round to this round
                possible_transition_pov_id_list = self.db.GetActiveProofIDListForTeamCS( last_round_number, team_id, cs_id )
                #possible_transition_pov_id_list = self.db.GetActiveProofIDListForTeamCS_updated( last_round_number, team_id, cs_id, team_id_list )

                for possible_transition_proof_id in possible_transition_pov_id_list:
                    if possible_transition_proof_id in proof_replace_list:
                        continue

                    transition_proof_data = self.db.GetProofDataForID( possible_transition_proof_id )

                    if transition_proof_data is None:
                        logger.critical( "ENGINE::TransitionRound::Critical error, could not look up Proof Data for ID (proof_id=%d)" % possible_transition_proof_id )
                        continue

                    transition_proof_id = transition_proof_data[0]
                    transition_proof_digest = binascii.unhexlify(transition_proof_data[1])
                    transition_proof_from_tid = transition_proof_data[2]
                    transition_proof_throws = transition_proof_data[3]

                    if transition_proof_from_tid == team_id:
                        logger.error( "ENGINE::TransitionRound::Proof being thrown against self for proof_id=%d, ignoring" % transition_proof_id )
                        continue

                    # Check for any other POVs to move
                    proof_full_path = settings.GetPOVDir( last_round_number, team_id, cs_id ) + ("pov_FROMTID%d_THROW%d.pov" % (transition_proof_from_tid, transition_proof_throws))

                    # Check file digest
                    proof_file_digest = self.DoSHA256File( proof_full_path )

                    if proof_file_digest is not None:
                        if proof_file_digest == transition_proof_digest:
                            # Transition Proof to next round
                            self.ForceCreateSymlink( proof_full_path, settings.GetPOVDir( next_round_number, team_id, cs_id ) + ("pov_FROMTID%d_THROW%d.pov" % (transition_proof_from_tid, transition_proof_throws)) )

                            #logger.info( "ENGINE::TransitionRound[%d -> %d]::TRANSITIONING POV for team_id=%d, target_id=%d, cs_id=%d, [%s -> %s]" % (last_round_number, next_round_number, transition_proof_from_tid, team_id, cs_id, proof_full_path, settings.GetPOVDir( next_round_number, team_id, cs_id ) + ("pov_FROMTID%d_THROW%d.pov" % (transition_proof_from_tid, transition_proof_throws))) )
                        else:
                            logger.critical( "ENGINE::TransitionRound::Critical error, POV file (TRANSITION) digest did not match digest in database for filename (file=%s), ignoring" % (proof_full_path) )
                    else:
                        logger.critical( "ENGINE::TransitionRound::Critical error, Could not digest (TRANSITION) POV file during transition (file=%s), file not found?" % (proof_full_path) )

                


        return

    def ScoreRound( self, round_number ):
        # round_number => This contains the round to score on
        # Score each team for this round
        team_id_list = self.db.GetTeamIDList()

        # Count total number of teams (for scoring)
        team_total_count = len(team_id_list)

        if team_total_count <= 1:
            logger.critical( "Team total count is 1 or less, skipping scoring, engine cannot score without more teams! (team_total_count=%d)" % team_total_count )
            return

        # Score each team one at a time
        for team_id in team_id_list:
            logger.info( "ENGINE::ScoreRound::SCORING Team ID: %d\n" % team_id )

            cs_id_list = self.db.GetActiveChallengeSetIDList(round_number)

            # Score each challenge set
            for cs_id in cs_id_list:
                # Score each CS individually in 3 fields, A,S,E
                availability = 1.0  # 0-1.0 with 1.0 being 100% availability and better than or equal to baseline performance
                security = 2        # [1,2] 1 = someone proved a pov against this CS, 2 = no one proved a pov against this CS
                evaluation = 2.0    # 1.0-2.0 with 1.0 being score against no one, 2.0 = proved against every other team

                # First check security score
                proof_against_count = self.db.GetSuccessfulPOVCountForTargetTeamID( round_number, cs_id, team_id )

                if proof_against_count > 0:
                    # If anyone proved a vulnerability on this challenge_set against this team, set security to 1
                    security_score = 1
                else:
                    # No one proved a vulnerability on this challenge_set against this team, set security to 2
                    security_score = 2

                # Score evaluation now -- determine how many teams THIS team proved PoV's on for this challenge_set against other teams out of the total number of teams!
                # Evaluation score
                proof_against_others_count = self.db.GetSuccessfulPOVTeamCountAgainstOthersButTeamID( round_number, cs_id, team_id )

                # Score based on E = 1 + (x/(NUM TEAMS - 1))
                evaluation_score = 1.0 + (float(proof_against_others_count) / float(team_total_count-1))

                # Availability score
                # Availability consists of Performance and Retained Functionality
                # First calculate retained functionality percentage
                polls_passed = self.db.GetPollsPassedForTeam( round_number, cs_id, team_id )
                polls_failed = self.db.GetPollsFailedForTeam( round_number, cs_id, team_id )
                polls_total = polls_passed + polls_failed

                if polls_total == 0:
                    logger.critical( "ENGINE::ScoreRound::Calculating functionality score but polls_total is 0" )

                    # No polls -- set functionality score to 0
                    func_score_final = 0.0

                else:
                    if polls_passed > polls_total:
                        logger.critical( "ENGINE::ScoreRound::Calculating functionality score but polls_passed is greater than polls_total (%d > %d)" % (polls_passed, polls_total) )
                        
                        polls_passed = polls_total

                    # Calculate the total retained functionality
                    retained_functionality = float(polls_passed) / float(polls_total)

                    # Apply curve and calculate function score
                    func_score_final = settings.FuncScoreCurve( retained_functionality )

                # Now calculate the most difficult one to calculate -- PERFORMANCE
                # OK calculate in one pass -- for every poll -- the file size, execution time, and memory usage

                # CB Round Score = Availability * Security * Evaluation
                # Availability = min( PerfScore, FuncScore )
                #
                # overhead(file_size) = (file_size(RCB) / file_size(PATCHED REFERENCE CB)) - 1
                # overhead(minor_faults) = (minor_faults(RCB) / minor_faults(PATCHED REFERENCE CB)) - 1
                # overhead(max_rss) = (max_rss(RCB) / max_rss(PATCHED REFERENCE CB)) - 1
                # overhead(cpu_time) = (cpu_time(RCB) / max_rss(PATCHED REFERENCE CB)) - 1
                # 
                # FileSizeFactor = 1 + (0.25 * overhead(file_size))
                # FileSizeOverhead = (file_size(RCB) / file_size(PATCHED CB)) - 1 (20% grace factor)
                # MemUseOverhead = (mem_use(RCB) / mem_use(PATCHED CB)) - 1       (5% grace factor)
                # ExecTimeOverhead = (exec_time(RCB) / exec_time(PATCHED CB)) - 1 (5% grace factor)

                # Get the filesize overhead -- ONLY need to calculate one time
                filesize = self.db.GetCurrentFileSizeForCSForTeam( round_number, cs_id, team_id )

                if filesize is None:
                    # Get the original CB's file size
                    filesize = self.db.GetOriginalFileSizeForCS( cs_id )

                if filesize is None:
                    logger.critical( "ENGINE::ScoreRound::Current file size for CB is None and so is original CB? Is this challenge_set missing a challenge binaries entry??? (warning, filesize_overhead will be 0 and therefore availability will not be affected by filesize) (cs_id=%d, team_id=%d, round_id=%d)" % (cs_id, team_id, round_number) )
               
                    # Don't penalize them
                    filesize_overhead = 0.0
                else:
                    filesize_reference_base = self.db.GetReferencePatchedFileSizeForCS( cs_id )

                    if filesize_reference_base is None:
                        logger.critical( "ENGINE::ScoreRound::Current filesize_reference_base is None, is CB missing challenge_binaries entry for challenge set? (warning, filesize_overhead will be 0 and therefore availabliity will be 0) (cs_id=%d)" % (cs_id) )

                        # Don't penalize them
                        filesize_overhead = 0.0
                    elif filesize_reference_base == 0:
                        logger.critical( "ENGINE::ScoreRound::Current filesize_reference_base is 0, is CB missing challenge_binaries entry 0? (cs_id=%d)" % (cs_id) )

                        # Don't penalize them
                        filesize_overhead = 0.0

                    elif filesize < filesize_reference_base:

                        # Don't penalize them
                        filesize_overhead = 0.0

                    else:
                        filesize_overhead = (float(filesize) / float(filesize_reference_base)) - 1.0
                
                poll_performance_data = self.db.GetPollPerformanceData( round_number, cs_id, team_id )

                perf_score_sum = 0.0
                perf_score_count = 0

                for poll_item in poll_performance_data:
                    poll_base_mean_wall_time = poll_item[1]
                    poll_base_stddev_wall_time = poll_item[2]
                    poll_wall_time = poll_item[3]
                    poll_base_mean_max_rss = poll_item[4]
                    poll_base_stddev_max_rss = poll_item[5]
                    poll_max_rss = poll_item[6]
                    poll_base_mean_min_flt = poll_item[7]
                    poll_base_stddev_min_flt = poll_item[8]
                    poll_min_flt = poll_item[9]
                    poll_base_mean_cpu_clock = poll_item[10]
                    poll_base_stddev_cpu_clock = poll_item[11]
                    poll_cpu_clock = poll_item[12]

                    # Calculate!
                    poll_exec_time_cpu_clock_base = (2.0*float(poll_base_mean_cpu_clock) + (settings.SCORE_SIGMA_VALUE * poll_base_stddev_cpu_clock))
                    poll_exec_time_wall_time_base = (2.0*float(poll_base_mean_wall_time) + (settings.SCORE_SIGMA_VALUE * poll_base_stddev_wall_time))

                    # Get each exec times
                    exec_time_cpu_clock_overhead = 0.0
                    if poll_exec_time_cpu_clock_base > 0.0:
                        # Make sure it is higher than the base before calculating overhead!
                        if poll_cpu_clock > poll_exec_time_cpu_clock_base:
                            exec_time_cpu_clock_overhead = (float(poll_cpu_clock) / float(poll_exec_time_cpu_clock_base)) - 1.0
                    else:
                        logger.error( "ENGINE::RoundScore::poll_exec_time_cpu_clock_base is 0.0 or less! (%f)" % poll_exec_time_cpu_clock_base )

                    # Calculate wall time exec overhead
                    exec_time_wall_time_overhead = 0.0
                    if poll_exec_time_wall_time_base > 0.0:
                        # Make sure it is higher than the base before calculating overhead!
                        if poll_wall_time > poll_exec_time_wall_time_base:
                            exec_time_wall_time_overhead = (float(poll_wall_time) / float(poll_exec_time_wall_time_base)) - 1.0
                    else:
                        logger.error( "ENGINE::RoundScore::poll_exec_time_wall_time_base is 0.0 or less! (%f)" % poll_exec_wall_time__base )

                    # Calculate the execution time factor
                    exec_time_factor = 1.0 + exec_time_cpu_clock_overhead + settings.IDSTimePenaltyCurve( exec_time_wall_time_overhead )

                    # Next memory overhead
                    # Max RSS
                    poll_mem_use_max_rss_base = (2.0*float(poll_base_mean_max_rss) + (settings.SCORE_SIGMA_VALUE * poll_base_stddev_max_rss))

                    mem_use_max_rss_overhead = 0.0
                    if poll_mem_use_max_rss_base > 0.0:
                        # Make sure it is higher than the base before calculating overhead!
                        if poll_max_rss > poll_mem_use_max_rss_base:
                            mem_use_max_rss_overhead = (float(poll_max_rss) / float(poll_mem_use_max_rss_base)) - 1.0
                    else:
                        logger.error( "ENGINE::RoundScore::poll_mem_use_max_rss_base is 0.0 or less! (%f)" % poll_mem_use_max_rss )

                    # Minor faults
                    poll_mem_use_min_flt_base = (2.0*float(poll_base_mean_min_flt) + (settings.SCORE_SIGMA_VALUE * poll_base_stddev_min_flt))

                    mem_use_min_flt_overhead = 0.0
                    if poll_mem_use_min_flt_base > 0.0:
                        # Make sure it is higher than the base before calculating overhead!
                        if poll_min_flt > poll_mem_use_min_flt_base:
                            mem_use_min_flt_overhead = (float(poll_min_flt) / float(poll_mem_use_min_flt_base)) - 1.0
                    else:
                        logger.critical( "ENGINE::RoundScore::poll_mem_use_min_flt_base is 0.0 or less! (%f)" % poll_mem_use_min_flt )

                    # Calculate the memory use factor
                    mem_use_factor = 1.0 + (0.5 * (mem_use_max_rss_overhead + mem_use_min_flt_overhead))

                    # Last is filesize overhead!
                    filesize_factor = 1.0 + (0.25 * filesize_overhead)

                    # OK now calculate PerfFactor
                    perf_factor = max( filesize_factor, mem_use_factor, exec_time_factor )

                    perf_score = settings.PerfScoreCurve( perf_factor )

                    if ( perf_score > 1.0 ):
                        logger.critical( "ENGINE::RoundScore::perf_score was greater than one for item (%f)" % (perf_score) )
                        
                        perf_score = 1.0

                    # Sum all the performance scores
                    perf_score_sum += perf_score
                    perf_score_count += 1

                # Find the average perf_score for all the performance scores
                if perf_score_count <= 0:
                    logger.critical( "ENGINE::RoundScore::perf_score_count is 0, no polls scored?" )

                    perf_score_final = 1.0
                else:
                    perf_score_final = (float(perf_score_sum) / float(perf_score_count))

                # Calculate availability score as the minimum of functionality score and performance score
                availability_score = min( perf_score_final, func_score_final )

                # Calculalte Team Challenge Set Score = A * S * E
                team_cs_score = (float(availability_score) * float(security_score) * float(evaluation_score))

                # Record score data -- this will also update the teams folder to increment the team score
                self.db.AddTeamCSScore( round_number, team_id, cs_id, availability_score, security_score, evaluation_score, perf_score_final, func_score_final, team_cs_score )

    def RunRound( self, last_round_number, round_id, max_containers_to_run, round_seed, round_secret, round_end_time ):
        # Run a single round of engine work
        # Update database of round start time
        self.db.SetRoundStartTime(datetime.fromtimestamp(time.time()), round_id)

        # First create engine working folder
        self.CreateWorkingFolder( round_id )

        # First set up threads for workers!
        q_engineworkers = Queue(maxsize=5000)

        for i in range(max_containers_to_run):
            # Invoke engine workers -- with maximum 180 second timeouts
            engine_worker = Thread(target=RunTestWorker, args=(q_engineworkers, self.db, self.docker, settings.ENGINE_WORKER_TIMEOUT))
            engine_worker.setDaemon(True)
            engine_worker.start()


        # DO ROUND STUFF
        # For each Team
        # --> For each CS available
        # ----> For each POV
        # ------> Run container
        team_id_list = self.db.GetTeamIDList()

        # Build list of containers to run -- randomize it
        logger.info( "ENGINE::RunRound::Run" )

        # Track round time
        exceeded_round_time = False

        # These items will be randomized, this is to ensure that teams/csets are deployed to the infrastructure in a random order
        q_items = []
        for team_id in team_id_list:

            cs_id_list = self.db.GetActiveChallengeSetIDList(round_id)
            for cs_id in cs_id_list:
                #logger.info( "ENGINE::RunRound::Run (team_id=%d, cs_id=%d\n" % (team_id, cs_id) )

                # Check if the CS was not just enabled...
                if last_round_number != 0 and not self.db.WasCSEnabledForRound( cs_id, last_round_number ):
                    # CHECK IF THIS CS had an RCB or Firewall fielded in the previous round
                    if self.db.WasRCBFieldedInRoundForCS( team_id, cs_id, last_round_number ):
                        # Down...
                        #logger.info( "ENGINE::RunRound::CS For Team DOWN due to fielded RCB in last round (team_id=%d, cs_id=%d)" % (team_id, cs_id) )
                        continue

                    if self.db.WasFirewallFieldedInRoundForCS( team_id, cs_id, last_round_number ):
                        # Down...
                        #logger.info( "ENGINE::RunRound::CS For Team DOWN due to fielded IDS in last round (team_id=%d, cs_id=%d)" % (team_id, cs_id) )
                        continue
                else:
                    logger.info( "ENGINE::RunRound::CS (cs_id=%d) was just enabled last round... ignoring check to bring down availability due to uploaded RCB or IDS rule." % (cs_id) )


                # Get IDS filename
                ids_digest = self.db.GetIDSDigest( round_id, team_id, cs_id )

                # Always rules.ids -- doesn't have to exist 
                ids_filename = "rules.ids"

                cb_filename = self.db.GetChallengeNameForID( cs_id )

                if cb_filename is None:
                    logger.critical( "Could not get name for challenge set? DB error" )
                    return None

                cs_binary_index_list = self.db.GetChallengeBinaryIndexList( cs_id )

                if cs_binary_index_list is None:
                    logger.critical( "Challenge set exists in database without challenge_binaries entry!?! (cs_id=%d)" % cs_id )
                    continue

                if len(cs_binary_index_list) > 1:
                    # Multi-binary challenge set
                    base_filename = cb_filename
                    cb_filename = ""
                    for binary_index in cs_binary_index_list:
                        cb_filename += ("%s_%d " % (base_filename, binary_index))

                # Run containers in parallel
                connection_id = 0
                split_start_pos = 0

                for i in range(settings.CONTAINER_PARALLEL_COUNT):
                    # Container name for this container -- used by docker
                    container_name = "ENGINE_ROUND%d_TEAM%d_CSID%d_%d" % (round_id, team_id, cs_id, i)

                    # Set end position for splitting container work load
                    split_end_pos = int( ((i+1)/float(settings.CONTAINER_PARALLEL_COUNT)) * 100.0 )
                    
                    # Queue up this container for processing
                    # throw_count -- represents the maximum number of throws possible per POV
                    q_items.append( {"container_name": container_name, "round_id" : round_id, "cs_id" : cs_id, "connection_id": connection_id, 'team_id': team_id, "ids_dir": settings.GetWorkingIDSDir( team_id, cs_id ), "ids_rule_filename" : ids_filename, "cb_dir" : settings.GetWorkingCBDir( team_id, cs_id ), "cb_filename" : cb_filename, "poll_source_dir": settings.GetPollsSaveDir( round_id, cs_id ), "pov_source_dir": settings.GetWorkingPOVDir( team_id, cs_id ), "throw_count" : 10, "round_seed" : binascii.hexlify(round_seed), "round_secret" : binascii.hexlify(round_secret), "split_start_pos": split_start_pos, "split_end_pos": split_end_pos } )

                    # Set start to previous end position
                    split_start_pos = split_end_pos

                    # Update connection_id
                    connection_id += 10000

        # Randomize queue items
        queue_index_list = range( len(q_items) )

        random.shuffle( queue_index_list )

        # Now queue up the workers
        for item_idx in queue_index_list:
            time.sleep( 0.1 )
            q_engineworkers.put( q_items[item_idx] )

        # Wait for all workers to finish
        q_engineworkers.join()

        # Wait for round time to end -- if we finished early
        cur_time = time.time()

        if ( cur_time < round_end_time ):
            logger.info( "Waiting for round end time, all tasks completed" )
            exceeded_round_time = False
        else:
            logger.info( "Round exceeded round end time" )
            exceeded_round_time = True

        while cur_time < round_end_time:
            time.sleep(1)
            cur_time = time.time()

        # Set round end time
        self.db.SetRoundEndTime(datetime.fromtimestamp(cur_time), round_id)

        return exceeded_round_time


    def __call__(self):
        version = self.db.GetVersion()

        logger.info( "WA Database version is: %s\n" % version )

        # Engine loop
        engine_start_time = time.time()
        logger.info( "Starting Wizard Arena Round Engine, start time is: %s" % datetime.utcfromtimestamp(engine_start_time).isoformat() )

        round_start_time = engine_start_time

        # Get the current round for the DB to run
        cur_round_number = self.db.GetStartRoundID()

        # Check if there are any rounds to run!
        if cur_round_number is None:
            logger.error( "Database either empty or no starting round found in the database. Exiting!\n" )
            return

        # Get the last round that the DB ran
        last_round_number = self.db.GetLastRoundID(cur_round_number)

        if last_round_number is None:
            logger.info( "ENGINE::Last round number in DB is None, using 0" )
            last_round_number = 0

        # Set next_round_number to None
        next_round_number = None

        # Log engine start
        logger.info( "ENGINE::Starting with round %d.\n" % cur_round_number )

        # Check for ROUND 1... FIRST start of system
        if last_round_number == 0:
            logger.info( "ENGINE::First start (last_round_number == 0)... Preparing engine for startup by calling TransitionRound (last_round_id=%d, cur_round_id=%d)" % (last_round_number, cur_round_number ) )
            self.TransitionRound( 0, cur_round_number )

        # Track the threads for running the engine workers
        engine_threads = []

        run_rounds = True
        while run_rounds:
            round_start_time = time.time()
            round_end_time = round_start_time+settings.ENGINE_ROUND_EXECUTION_TIME


            # Get round seed (if it has one) and round secret
            round_seed = self.GetRoundSeed( cur_round_number )
            round_secret = self.GetRoundSecret( cur_round_number )
    
            swarm_cpu_count = self.GetAgentCoresAvailable()

            # Calculate the maximum containers to run -- with 80% provisioning factor
            max_containers_to_run = int((float(swarm_cpu_count) / 3.0) * settings.CONTAINER_PROVISION_FACTOR)


            logger.info( "ROUND %d START [MAX_CONTAINERS=%d] [%s to expected end time %s] [seed=%s secret=%s]" % (cur_round_number, max_containers_to_run, datetime.utcfromtimestamp(round_start_time).isoformat(),datetime.utcfromtimestamp(round_end_time).isoformat(),binascii.hexlify(round_seed),binascii.hexlify(round_secret)) )

            # Run the round (run engine containers on the swarm)
            run_exceeded_time = self.RunRound( last_round_number, cur_round_number, max_containers_to_run, round_seed, round_secret, round_end_time )

            # Start intermission counter
            round_intermission_start_time = time.time()
            round_intermission_end_time = round_intermission_start_time + settings.ENGINE_ROUND_PAUSE_TIME
            
            # Score the round
            self.ScoreRound( cur_round_number )
        
            # Get next round to execute
            next_round_number = self.db.GetNextRoundToRun(cur_round_number)

            if next_round_number is None:
                logger.info( "Terminating engine, no further rounds to execute (last round id=%d)\n" % cur_round_number )
                break

            # Advance round number -- remember last round number for transition
            last_round_number = cur_round_number
            cur_round_number = next_round_number

            # Perform round transition
            self.TransitionRound( last_round_number, cur_round_number )
           
            # Wait for intermission complete
            if run_exceeded_time:
                logger.info( "Skipping intermission end time, round exceeded run time -- moving to next" )
                time.sleep( 10 )
            else:
                cur_time = time.time()
                if ( cur_time < round_intermission_end_time ):
                    logger.info( "Waiting for intermission end time, all tasks completed" )
                else:
                    logger.info( "Intermission exceed intermission time!" )

                while cur_time < round_intermission_end_time:
                    time.sleep(1)
                    cur_time = time.time()

        # Set round end time

    def GetRoundSeed( self, cur_round_id ):
        # First check for an already existing round seed
        round_seed = self.db.GetRoundSeed( cur_round_id )

        if round_seed is not None:
            if len(round_seed) != 32:
                logger.critical( "Round seed must be 32-bytes, database entry is %d bytes, aborting engine!" % len(round_seed) )
                sys.exit(-1)

            return round_seed

        logger.critical("Round seed is none for round (%d), aborting engine!" % cur_round_id )
        sys.exit(-1)

    def GetRoundSecret( self, cur_round_id ):
        # First check for an already existing round secret
        round_secret = self.db.GetRoundSecret( cur_round_id )

        if round_secret is not None and len(round_secret) == settings.ROUND_SECRET_LENGTH:
            return round_secret

        # Round secret is NONE -- generate a new round secret -- this is should be random data from a good entropy source
        round_secret = os.urandom( settings.ROUND_SECRET_LENGTH )

        # ROUND SECRET should always be 64-bytes in length (HMAC blocksize is 64-bytes)
        if len(round_secret) != settings.ROUND_SECRET_LENGTH:
            logger.critical("Round secret key material generation failed, trying again!!!")
            
        round_secret = os.urandom( settings.ROUND_SECRET_LENGTH ) 

        if len(round_secret) != settings.ROUND_SECRET_LENGTH:
            logger.critical("Round secret key material try2 failed -- aborting engine!")
            sys.exit(-1)

        # ROUND secret generated -- add it to the database
        self.db.SetRoundSecret( round_secret, cur_round_id )

        return round_secret

def TestSimple():
    q = Queue(maxsize=100)

    test_engine = WAEngine()

    worker = Thread(target=RunTestWorker, args=(q, test_engine.db, test_engine.docker, 160 ))
    worker.setDaemon(True)

    round_num = 1
    cs_id = 1
    team_id = 1

    q.put( {"container_name": "test_engine", "round_id" : round_num, "cs_id" : cs_id, 'team_id': team_id, "ids_dir": settings.GetIDSDir( round_num, team_id, cs_id ), "ids_rule_filename" : "empty.rules", "cb_dir" : settings.GetCBDir( round_num, team_id, cs_id ), "cb_filename" : "test", "poll_source_dir": settings.GetPollsSaveDir( round_num, cs_id ), "pov_source_dir": settings.GetPOVDir( round_num, team_id, cs_id ), "throw_count" : 1, "round_seed" : "aabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccdd", "round_secret" : "aabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccdd" } )

    worker.start()
    
    raw_input("Running test, press any key to stop")

    return

def main():
    log_level = logging.INFO

    engine_log_handler = logging.FileHandler('engine.log')
    engine_log_formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
    
    engine_log_handler.setFormatter(engine_log_formatter)
    engine_log_handler.setLevel( log_level )

    stdout_log_handler = logging.StreamHandler()
    stdout_log_handler.setLevel( log_level )

    engine_logger = logging.getLogger('WAEngine')
    engine_logger.addHandler( stdout_log_handler )
    engine_logger.addHandler( engine_log_handler )
    engine_logger.setLevel( log_level )

    # Create main engine instance
    main_engine = WAEngine()

    # Run main engine
    main_engine()


if __name__ == "__main__":
    main()
