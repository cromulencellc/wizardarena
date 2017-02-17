#!/usr/bin/env python

# settings.py
#
# Contains global settings for the system
#
#

# Base directory which all engine data is stored on
ENGINE_BASE_DIRECTORY = "/mnt/wastorage/engine/"

# Team Interface incoming directory
TEAMINTERFACE_BASE_DIRECTORY = "/mnt/wastorage/engine/"

# The database address
ENGINE_DATABASE_HOST = "master1"

# The database name for the teaminterface database used by the Wizard Arena system
ENGINE_DATABASE_NAME = "teaminterface_dev"

# User the engine uses to access the database with
ENGINE_USER_NAME = "engine"

# Password for the database
ENGINE_PASSWORD = "labrat"

# Round execution time is the time available in a round for running engine tasks
# Round pause time is the pause time between rounds (this can be consumed) -- if the engine is running
# late
ENGINE_ROUND_EXECUTION_TIME = 270
ENGINE_ROUND_PAUSE_TIME = 30
ENGINE_ROUND_TOTAL_TIME = 300

# Round engine worker timeout
ENGINE_WORKER_TIMEOUT = 240

# ROUND SECRET and ROUND SEED KEY LENGTH
ROUND_SECRET_LENGTH = 64
ROUND_SEED_LENGTH = 32

# IDS/Firewall settings
# The NOTEAM should be any IP address that doesn't actually exist for a team (used by build_polls)
IDS_PCAP_HOST_NOTEAM = "10.5.20.2"

# PCAP destination port
IDS_PCAP_PORT = 1999


# DOCKER SETTINGS
DOCKER_HOST_ADDRESS = "master1:3000"
DOCKER_TLS_ENABLE = True
DOCKER_CERT_PATH = "certs/"

TOOL_FOLDER_PATH = "tools/"
IMAGE_FOLDER_PATH = "images/"
DOCKER_REPO_NAME = "master1:5000/cromu/"

# CONTAINER PROVISION FACTOR is how much of the available agent CPU cores to provision at once (0.9 = 90% of all cores, 1.5 = 150% of all cores -- effectively over provisioning)
CONTAINER_PROVISION_FACTOR = 1.25

# CONTAINER PARALLEL COUNT is how many containers for a cset to run in a parallel (this will split the polls/povs of a cset into a parallel set)
CONTAINER_PARALLEL_COUNT = 24

# Range for generating build polls
BUILD_POLLS_MIN_COUNT = 300
BUILD_POLLS_MAX_COUNT = 400

# The number of times to test the poll files
POLL_TEST_COUNT = 5

# Directory containing base challenge set build files
BASE_CHALLENGE_SET_BUILD_FOLDER = "challenge_base"

# Directory containing current game engine data
BASE_CHALLENGE_SET_GAME_FOLDER = "inprogress"

# Engine working folder (currently running round)
ENGINE_WORKING_FOLDER = "working"

# Teaminterface incoming folder
TEAMINTERFACE_INCOMING_FOLDER = "incoming"

def GetWorkingFolderDir( ):
    engine_working_folder = "%s%s" % (ENGINE_BASE_DIRECTORY, ENGINE_WORKING_FOLDER)

    return engine_working_folder

# The working directory is a copy of the current round's entries for all the TEAMS/CS'S that are to run for the current round
# IT IS replaced and recreated by the engine each run of a single round -- this ensures that no symbolic links are in
# place in the working folder to allow proper container execution
def GetWorkingIDSDir( team_id, cs_id ):
    ids_dir = "%s%s/%d/%d/ids/" % (ENGINE_BASE_DIRECTORY, ENGINE_WORKING_FOLDER, team_id, cs_id)

    return ids_dir

def GetWorkingCBDir( team_id, cs_id ):
    cb_dir = "%s%s/%d/%d/cb/" % (ENGINE_BASE_DIRECTORY, ENGINE_WORKING_FOLDER, team_id, cs_id)

    return cb_dir

def GetWorkingPOVDir( team_id, cs_id ):
    pov_dir = "%s%s/%d/%d/pov/" % (ENGINE_BASE_DIRECTORY, ENGINE_WORKING_FOLDER, team_id, cs_id)

    return pov_dir

def GetEngineInprogressRoundDir( round_id ):
    engine_inprogress_folder = "%s%s/%d" % (ENGINE_BASE_DIRECTORY, BASE_CHALLENGE_SET_GAME_FOLDER, round_id)

    return engine_inprogress_folder

def GetTeamInterfaceIncomingDir( ):
    teaminterface_incoming_dir = "%s%s" % (TEAMINTERFACE_BASE_DIRECTORY, TEAMINTERFACE_INCOMING_FOLDER)

    return teaminterface_incoming_dir

def GetTeamInterfaceIncomingRCBDir( team_id ):
    teaminterface_incoming_rcb_dir = "%s%s/%d/rcb/" % (TEAMINTERFACE_BASE_DIRECTORY, TEAMINTERFACE_INCOMING_FOLDER, team_id)

    return teaminterface_incoming_rcb_dir

def GetTeamInterfaceIncomingIDSDir( team_id ):
    teaminterface_incoming_ids_dir = "%s%s/%d/ids/" % (TEAMINTERFACE_BASE_DIRECTORY, TEAMINTERFACE_INCOMING_FOLDER, team_id)

    return teaminterface_incoming_ids_dir

def GetTeamInterfaceSaveRoundDir( round_id ):
    teaminterface_save_round_dir = "%srounds/%d" % (TEAMINTERFACE_BASE_DIRECTORY, round_id)

    return teaminterface_save_round_dir

def GetTeamInterfaceSaveRCBDir( round_id, team_id ):
    teaminterface_save_rcb_dir = "%srounds/%d/%d/rcb/" % (TEAMINTERFACE_BASE_DIRECTORY, round_id, team_id)

    return teaminterface_save_rcb_dir

def GetTeamInterfaceSaveIDSDir( round_id, team_id ):
    teaminterface_save_ids_dir = "%srounds/%d/%d/ids/" % (TEAMINTERFACE_BASE_DIRECTORY, round_id, team_id)

    return teaminterface_save_ids_dir

def GetTeamInterfaceSavePOVDir( round_id, team_id, cs_id ):
    teaminterface_save_pov_dir = "%srounds/%d/%d/pov/%d/" % (TEAMINTERFACE_BASE_DIRECTORY, round_id, team_id, cs_id)

    return teaminterface_save_pov_dir

def GetEmptyIDSDir( ):
    empty_ids_dir = "%spoll_test/ids/" % (ENGINE_BASE_DIRECTORY)

    return empty_ids_dir

def GetChallengeSetBuildPollDir( cs_shortname ):
    challenge_set_build_dir = "%s%s/%s/poller/for-release/" % (ENGINE_BASE_DIRECTORY, BASE_CHALLENGE_SET_BUILD_FOLDER, cs_shortname )

    return challenge_set_build_dir

def GetChallengeSetBuildCBDir( cs_shortname ):
    challenge_set_build_cb_dir = "%s%s/%s/bin/" % (ENGINE_BASE_DIRECTORY, BASE_CHALLENGE_SET_BUILD_FOLDER, cs_shortname )

    return challenge_set_build_cb_dir

# Helper function to get the save directory for the baseline poll datta
def GetPollsSaveDir( round_num, cs_id ):
    poll_save_dir = "%sbase_polls/%d/%d/" % (ENGINE_BASE_DIRECTORY, round_num, cs_id )

    return poll_save_dir

# Get IDS Directory
def GetIDSDir( round_num, team_id, cs_id ):
    ids_dir = "%s%s/%d/%d/%d/ids/" % (ENGINE_BASE_DIRECTORY, BASE_CHALLENGE_SET_GAME_FOLDER, round_num, team_id, cs_id)

    return ids_dir

def GetCBDir( round_num, team_id, cs_id ):
    cb_dir = "%s%s/%d/%d/%d/cb/" % (ENGINE_BASE_DIRECTORY, BASE_CHALLENGE_SET_GAME_FOLDER, round_num, team_id, cs_id)

    return cb_dir

def GetPOVDir( round_num, team_id, cs_id ):
    pov_dir = "%s%s/%d/%d/%d/pov/" % (ENGINE_BASE_DIRECTORY, BASE_CHALLENGE_SET_GAME_FOLDER, round_num, team_id, cs_id)

    return pov_dir

# This value will be multiplied by the standard deviation and used to calculate the baseline performance data, 3 sigma, is 99.97% of tests should fall in this range
SCORE_SIGMA_VALUE = 4.0

# SCORING SCALE TABLES
def IDSTimePenaltyCurve( value ):
    if ( value <= 0.0 ):
        return 0.0
    elif ( value <= 0.35 ):
        return (0.2 * value)
    else:
        return 0.07

def PerfScoreCurve( value ):
    if ( value <= 1.05 ):
        return 1.0
    elif ( value <= 1.21 ):
        return ((-2.142 * value) + 3.249)
    elif ( value <= 1.62 ):
        return pow( (value - 0.1), -4.0 )
    elif ( value < 2.0 ):
        return ((-0.493 * value) + 0.986)
    else:
        return 0.0

def FuncScoreCurve( value ):
    # Should never get higher than 1.0
    if ( value >= 1.0 ):
        return 1.0
    elif ( 0.4 <= value < 1.0 ):
        return pow( (2.0 - value), -4.0 )
    elif ( 0.0 < value < 0.4 ):
        return (0.381 * value)
    else:
        return 0.0
