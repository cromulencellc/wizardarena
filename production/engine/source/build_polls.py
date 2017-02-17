#!/usr/bin/env python

# database.py
#
# Contains functionality for managing the backend database connection
#
#
import os
import sys
import random
import logging
from database import WADBEngine
import time
import settings
from datetime import datetime
import binascii
import wa_container
import prf
import replay_helper
from Queue import Queue
from threading import Thread

def BuildPollWorker( q, docker, timeout ):
    while True:
        poll_builder_arguments = q.get()

        start_time = time.time()

        # Start container
        container_id = docker.RunBuildPollsContainer( poll_builder_arguments["container_name"], poll_builder_arguments["poll_seed"], poll_builder_arguments["poll_save_dir"], poll_builder_arguments["poll_count"], poll_builder_arguments["poll_source_dir"] )

        # Continue until timed out
        force_stop = True
        while time.time() < (start_time+timeout):
            
            container_info = docker.GetContainerInfo( container_id )

            if docker.IsContainerRunning( container_info ):
                time.sleep( 2 )
            else:
                force_stop = False
                break

        '''
        gen_logs = docker.GetContainerLogs( container_id )

        out_file = "%s_genpoll.log" % poll_builder_arguments["container_name"]
        with open( out_file, "w" ) as fh:
            fh.write( gen_logs )
        '''

        # Stop container
        docker.KillAndRemoveContainer( container_id )

        # Complete task
        q.task_done()

def TestPollWorker( q, db, docker, timeout ):
    while True:
        poll_test_arguments = q.get()

        baseline_performance_data = replay_helper.PollBaselineHelper()

        # Track any discard poll files
        poll_discard_list = [ ]

        cs_id = poll_test_arguments["cs_id"]
        connection_id = poll_test_arguments["connection_id"]
        round_id = poll_test_arguments["round_id"]

        cur_run_idx = 0
        run_count = poll_test_arguments["run_count"]
        while cur_run_idx < run_count:
            container_name = "%s_RND%d_CSID%d_RUN%d" % (poll_test_arguments["container_name"], round_id, cs_id, cur_run_idx)

            # Can't use container_name here because it will contain the parallel count and throw off the RNG in cb-master-replay
            run_label = "TEST_%s_RND%d_CSID%d" % (poll_test_arguments["cs_name"], round_id, cs_id)

            # Record run start time
            start_time = time.time()
           
            retry_count = 4
            try_count = 0

            for _ in range(retry_count):
                # Record tries
                try_count += 1

                # Start containers
                try:
                    run_results = docker.RunTestPolls( cs_id, connection_id, container_name, 1, poll_test_arguments["round_seed"], "aabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccddaabbccdd", run_label, poll_test_arguments["ids_dir"], poll_test_arguments["ids_rule_filename"], poll_test_arguments["cb_dir"], poll_test_arguments["cb_filename"], poll_test_arguments["poll_source_dir"], poll_test_arguments["pov_source_dir"], poll_test_arguments["split_start_pos"], poll_test_arguments["split_end_pos"], settings.IDS_PCAP_HOST_NOTEAM, settings.IDS_PCAP_PORT )

                    # Wait for CB-MASTER-REPLAY to complete
                    # Continue until timed out
                    force_stop = True
                    while time.time() < (start_time+timeout):
                        container_info = docker.GetContainerInfo( run_results[2] )

                        if docker.IsContainerRunning( container_info ):
                            time.sleep( 2 )
                        else:
                            force_stop = False
                            break

                    if force_stop:
                        logging.error( "BuildPolls::TestPollWorker::Forcing stop for worker: %s" % container_name )

                    # Wait for container logs to catch up
                    time.sleep( 2 )

                    # Get logs from both the cb-replay container and cb-server (0 -> for cb-server and 2 -> cb-replay)
                    cbreplay_logs = docker.GetContainerLogs( run_results[2] )
                    #ids_logs = docker.GetContainerLogs( run_results[1] )
                    cbserver_logs = docker.GetContainerLogs( run_results[0] )
           
                    # Parse results
                    cbreplay_results = replay_helper.CBReplayResults( cbreplay_logs )
                    cbserver_results = replay_helper.CBServerResults( cbserver_logs )

                    # Container group succeeded
                    container_start_fail = False
                except:
                    print "RunTestPolls::Attempting last level recovery of container"

                    time.sleep( 4 )
                    docker.RemoveContainerByName( container_name+"_cbserver" )
                    docker.RemoveContainerByName( container_name+"_cbreplay" )
                    docker.RemoveContainerByName( container_name+"_cbids" )

                    container_start_fail = True

                if container_start_fail is True:
                    time.sleep( 4 )
                else:
                    break

            if try_count >= retry_count:
                print "CRITICAL ERROR:: Failed to recover retried container group"

                # Abandon
                q.task_done()

                continue



            '''
            out_file = "%s_cbreplay.log" % container_name
            with open( out_file, "w" ) as fh:
                fh.write( cbreplay_logs )

            out_file = "%s_ids.log" % container_name
            with open( out_file, "w" ) as fh:
                fh.write( ids_logs )

            out_file = "%s_cbserver.log" % container_name
            with open( out_file, "w" ) as fh:
                fh.write( cbserver_logs )
            '''


            docker.KillAndRemoveContainer( run_results[0] )
            docker.KillAndRemoveContainer( run_results[1] )
            docker.KillAndRemoveContainer( run_results[2] )

            # Add performance data
            poll_discard_list.append( baseline_performance_data.AddResults( cbreplay_results, cbserver_results ) )
            
            # Update the run index
            cur_run_idx += 1

        # Display results
        #baseline_performance_data.DisplayBaselineData()
        print "Discard list size=%d" % len(poll_discard_list)

        for poll_seed in baseline_performance_data.poll_baseline_list:
            performance_data = baseline_performance_data.poll_baseline_list[poll_seed]

            db.AddPollBaselinePerformance( cs_id, round_id, performance_data.poll_id, poll_seed, performance_data.GetWallTimeMean(), performance_data.GetWallTimeDeviation(), performance_data.GetMaxRSSMean(), performance_data.GetMaxRSSDeviation(), performance_data.GetMinorFaultsMean(), performance_data.GetMinorFaultsDeviation(), performance_data.GetUTimeMean(), performance_data.GetUTimeDeviation(), performance_data.GetTaskClockMean(), performance_data.GetTaskClockDeviation(), performance_data.GetCPUClockMean(), performance_data.GetCPUClockDeviation() )

        # Complete task
        q.task_done()


class WAPollGenerator():
    def __init__(self):
        # Create db connection
        self.db = WADBEngine()

        # Create docker engine connection
        self.docker = wa_container.CBDockerEngine( settings.DOCKER_HOST_ADDRESS, settings.DOCKER_CERT_PATH, settings.TOOL_FOLDER_PATH, settings.IMAGE_FOLDER_PATH, settings.DOCKER_REPO_NAME ) 

    def GetAgentCoresAvailable(self):
        docker_info_data = self.docker.GetDockerInfo()

        docker_driver_status = docker_info_data['DriverStatus']

        swarm_cpu_count = docker_info_data['NCPU']

        #print "Swarm CPU Count=%d\n" % swarm_cpu_count

        return swarm_cpu_count

    def __call__(self, round_start, round_end, build_polls=True, poll_test_count=settings.POLL_TEST_COUNT):
        version = self.db.GetVersion()

        # Get CPUs available for the swarm
        swarm_cpu_count = self.GetAgentCoresAvailable()

        # Calculate the maximum containers to run -- with 80% provisioning factor
        max_containers_to_run = int((float(swarm_cpu_count) / 3.0) * settings.CONTAINER_PROVISION_FACTOR)

        # Calculate worker queue for testing polls
        q_polltest = Queue(maxsize=2000)

        for i in range(max_containers_to_run):
            # Invoke 90 second timeout on poll testing
            polltest_worker = Thread(target=TestPollWorker, args=(q_polltest, self.db, self.docker, 200 ))
            polltest_worker.setDaemon(True)
            polltest_worker.start()

        # Calculate build polls worker queue
        q_buildpolls = Queue(maxsize=2000)

        for i in range(max_containers_to_run):
            # Invoke 150 second timeout on building polls
            pollbuild_worker = Thread(target=BuildPollWorker, args=(q_buildpolls, self.docker, 200))
            pollbuild_worker.setDaemon(True)
            pollbuild_worker.start()

        # Run main engine
        print "Version is: %s\n" % version

        # Build Polls Loop
        build_start_time = time.time()
        print "Starting Build Polls engine, start time is: %s" % datetime.utcfromtimestamp(build_start_time).isoformat()

        # Start with first round -- regardless of whether or not if
        cur_round_number = round_start

        print "Starting with round %d.\n" % cur_round_number

        run_rounds = True
        while run_rounds:
            round_start_time = time.time()

            # Get round seed (it should always have one)
            round_seed = self.GetRoundSeed( cur_round_number )
    
            print "ROUND %d [MAX_CONTAINERS=%d] [seed=%s]" % (cur_round_number, max_containers_to_run, binascii.hexlify(round_seed))

            cs_id_list = self.db.GetActiveChallengeSetIDList(cur_round_number)
            
            if ( cs_id_list is None ):
                # Do nothing
		print "No active challenge sets for this round"
            else:

                # Only build polls if we specified to build them
                if build_polls:
                    print "Building poller XML files"
                    for cs_id in cs_id_list:

                        if cs_id == 3 or cs_id == 9:
                            print "Skipping cs_id=%d for ben's or lightning's service" % cs_id
                            continue

                        print "CS ID", cs_id

                        challenge_name = self.db.GetChallengeNameForID(cs_id)

                        challenge_seed_label_string = "%s ROUND %d CS ID %d" % (challenge_name, cur_round_number, cs_id)
                        poll_seed = prf.HKDF_HMAC_SHA512( round_seed, challenge_seed_label_string, 48 )

                        print "Building Polls for CS %s ID %d [poll_seed=%s]\n" % (challenge_name, cs_id, binascii.hexlify(poll_seed))

                        # Generate container name for building the polls
                        container_name = "TESTPOLL_%s_RND%d_CSID%d" % (challenge_name, cur_round_number, cs_id)

                        # Pause for docker to catch up
                        time.sleep( 0.05 )

                        q_buildpolls.put( {"container_name": container_name, "poll_seed": binascii.hexlify(poll_seed), "poll_save_dir": settings.GetPollsSaveDir( cur_round_number, cs_id ), "poll_count": random.randrange( settings.BUILD_POLLS_MIN_COUNT, settings.BUILD_POLLS_MAX_COUNT ), "poll_source_dir": settings.GetChallengeSetBuildPollDir( challenge_name )} )

                  
                    # Wait for poll builder workers to finish
                    q_buildpolls.join()
                else:
                    print "Skipping building poller XML files"

                # Now test them
                cs_id_list = self.db.GetActiveChallengeSetIDList(cur_round_number)
                for cs_id in cs_id_list:
                    cb_filename = self.db.GetChallengeNameForID(cs_id)
                    cs_name = cb_filename
                    cs_binary_index_list = self.db.GetChallengeBinaryIndexList(cs_id)

                    if cs_binary_index_list is None:
                        logging.critical( "Challenge set exists in database without challenge_binaries entry!?! (cs_id=%d)" % cs_id )
                        continue

                    print "Challenge Set Binary List Index: ", cs_binary_index_list

                    if len(cs_binary_index_list) > 1:
                        # Multi-binary challenge set
                        base_filename = cb_filename
                        cb_filename = ""
                        for binary_index in cs_binary_index_list:
                            cb_filename += ("%s_%d " % (base_filename, binary_index))

                    print "Testing Polls for CS %s ID %d\n" % (cs_name, cs_id)
                    print "Challenge Binary: %s%s" % (settings.GetChallengeSetBuildCBDir( cs_name ), cb_filename)


                    # Run containers in parallel
                    connection_id = 0
                    split_start_pos = 0
                    for i in range(settings.CONTAINER_PARALLEL_COUNT):
                        container_name = "BUILDPOLL_%s_%d" % (cs_name, i)

                        split_end_pos = int( ((i+1)/ float(settings.CONTAINER_PARALLEL_COUNT)) * 100.0 )
                    
                        # Pause for docker to catch up
                        time.sleep( 0.05 )

                        q_polltest.put( {"cs_name": cs_name, "container_name": container_name, "round_seed": binascii.hexlify(round_seed), "round_id": cur_round_number, "cs_id": cs_id, "connection_id": connection_id, "ids_dir": settings.GetEmptyIDSDir(), "ids_rule_filename": "empty.rules", "cb_dir": settings.GetChallengeSetBuildCBDir( cs_name ), "cb_filename": cb_filename, "poll_source_dir": settings.GetPollsSaveDir( cur_round_number, cs_id ), "pov_source_dir": None, "run_count": poll_test_count, "split_start_pos": split_start_pos, "split_end_pos": split_end_pos } )
                   
                        # Set start to previous end!
                        split_start_pos = split_end_pos

                        # Skip to 10000
                        connection_id += 10000

                # Wait for poll testing workers to finish
                q_polltest.join()

            # Get next round to execute
            next_round_number = self.db.GetNextRoundToRun(cur_round_number)

            if next_round_number is None:
                print "Terminating poll generator, no further rounds to execute (last round id=%d)\n" % cur_round_number
                break

            cur_round_number = next_round_number

    def GetRoundSeed( self, cur_round_id ):
        # First check for an already existing round seed
        round_seed = self.db.GetRoundSeed( cur_round_id )

        if round_seed is not None:
            return round_seed

        logging.critical("Round seed is none for round (%d), aborting engine!" % cur_round_id )
        sys.exit(-1)

    def CreateBaseImage( self ):
        self.docker.GenPollGeneratorBaseImage()         

    def RunBuildPollsContainer( self, container_name, poll_seed, poll_save_dir, poll_count, poll_source_dir ):
        container_id = self.docker.RunBuildPollsContainer( container_name, poll_seed, poll_save_dir, poll_count, poll_source_dir )

        while True:
            container_info = self.docker.GetContainerInfo( container_id )

            if self.docker.IsContainerRunning( container_info ):
                time.sleep( 1 )
            else:
                break

        container_info = self.docker.GetContainerInfo( container_id )

        '''
        print "IS RUNNING? ", self.docker.IsContainerRunning( container_info )
        print "STARTED AT: ", self.docker.GetContainerStartTime( container_info )
        print "FINISHED AT: ", self.docker.GetContainerEndTime( container_info )
        print "LOGS: ", self.docker.GetContainerLogs( container_id )
        '''
        return container_id, container_info


    def RunTestPollsContainer( self, round_id, csid, connection_id, container_name, ids_dir, ids_rule_filename, cb_dir, cb_filename, poll_source_dir, run_count ):

        # Track baseline performance data
        baseline_performance_data = replay_helper.PollBaselineHelper()

        # Track any discard poll files
        poll_discard_list = [ ]

        cur_run_idx = 0
        while cur_run_idx < run_count:
            run_results = self.docker.RunTestPolls( csid, connection_id, container_name+str(cur_run_idx), ids_dir, ids_rule_filename, cb_dir, cb_filename, poll_source_dir, 0, 100, settings.IDS_PCAP_HOST_NOTEAM, settings.IDS_PCAP_HOST_PORT )

            print "RUN TEST POLLS RESULTS: ", run_results
            # Wait for CB-MASTER-REPLAY to complete
            self.docker.WaitForContainerExit( run_results[2] )

            # Get logs from both the cb-replay container and cb-server (0 -> for cb-server and 2 -> cb-replay)
            cbreplay_logs = self.docker.GetContainerLogs( run_results[2] )
            cbserver_logs = self.docker.GetContainerLogs( run_results[0] )

            cbreplay_results = replay_helper.CBReplayResults( cbreplay_logs )
            cbserver_results = replay_helper.CBServerResults( cbserver_logs )

            print "Done waiting for cb-master-replay container.\n"

            self.docker.KillAndRemoveContainer( run_results[0] )
            self.docker.KillAndRemoveContainer( run_results[1] )
            self.docker.KillAndRemoveContainer( run_results[2] )

            # Add performance data
            poll_discard_list.append( baseline_performance_data.AddResults( cbreplay_results, cbserver_results ) )

            # Update run idx
            cur_run_idx += 1

        # Display results
        baseline_performance_data.DisplayBaselineData()

        for poll_seed in baseline_performance_data.poll_baseline_list:
            performance_data = baseline_performance_data.poll_baseline_list[poll_seed]

            self.db.AddPollBaselinePerformance( csid, round_id, performance_data.poll_id, poll_seed, performance_data.GetWallTimeMean(), performance_data.GetWallTimeDeviation(), performance_data.GetMaxRSSMean(), performance_data.GetMaxRSSDeviation(), performance_data.GetMinorFaultsMean(), performance_data.GetMinorFaultsDeviation(), performance_data.GetUTimeMean(), performance_data.GetUTimeDeviation(), performance_data.GetTaskClockMean(), performance_data.GetTaskClockDeviation(), performance_data.GetCPUClockMean(), performance_data.GetCPUClockDeviation() )

        return poll_discard_list
            
def main():
    log_level = logging.INFO

    logging.basicConfig(format='%(asctime)s - %(levelname)s : %(message)s', level=log_level, stream=sys.stderr)

    poll_generator = WAPollGenerator()

    poll_generator.CreateBaseImage()

    poll_generator( 1, 10, True )

    return

    ''' OLD
    q = Queue(maxsize=10)

    worker = Thread(target=TestPollWorker, args=(q, poll_generator.db, poll_generator.docker, 30 ))
    worker.setDaemon(True)
    worker.start()

    q.put( {"container_name": "build_polls_test", "round_id": 1, "cs_id": 1, "connection_id": 0, "ids_dir": "/wa_storage/data/test/ids/", "ids_rule_filename": "test_none.rules", "cb_dir": "/wa_storage/data/test/cb_dir/", "cb_filename": "TEST_0001", "poll_source_dir": "/wa_storage/data/test/out_polls/", "pov_source_dir": None, "run_count": 4 } )

    q.join()
    # Run main engine
    #poll_generator( 0, 10 )
    '''


if __name__ == "__main__":
    main()
