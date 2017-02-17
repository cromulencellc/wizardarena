#!/usr/bin/env python

# database.py
#
# Contains functionality for managing the backend database connection
#
#

import psycopg2
import settings
import logging
import binascii

class WADBNotConnectedException(Exception):
    pass

class WADBErrorException(Exception):
    pass

class WADBEngine():
    def __init__(self):
        self.ConnectDB()

    def ConnectDB( self ):
        # Initialize WADBEngine
        try:
            self.db_con = psycopg2.connect("dbname='%s' user='%s' host='%s' password='%s'" % (settings.ENGINE_DATABASE_NAME, settings.ENGINE_USER_NAME, settings.ENGINE_DATABASE_HOST, settings.ENGINE_PASSWORD) )
        except psycopg2.Error as e:
            logging.critical('Could not connect to database (%s).' % (repr(e)))
            raise WADBErrorException( "Failed to connect to database (error: %s)" % repr(e) )
            self.db_con = None

    def GetVersion(self):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT version()")
        except:
            logging.critical('Could not execute SQL version() for GetVersion()')
            raise WADBErrorException( "Could not execute SQL version() for GetVersion()" )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None
        else:
            return result_data[0]

    def GetTeamIDList(self):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT id FROM teams")
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetTeamIDList()')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchall()
        if result_data is None:
            return None
        else:
            team_id_list = []
            for item in result_data:
                team_id_list.append( item[0] )

            return team_id_list

    def GetActiveChallengeSetIDList(self, cur_round_id):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT challenge_set_id FROM enablements WHERE round_id=%s", (cur_round_id,) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetActiveChallengeSetIDList')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchall()
        if result_data is None:
            return None
        else:
            cs_id_list = []
            for item in result_data:
                cs_id_list.append( item[0] )

            return cs_id_list
            '''
             if len(result_data) == 0:
                 return None
             return result_data[0]
            '''

    def GetStartRoundID(self):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT id FROM rounds WHERE finished_at is null ORDER BY id ASC")
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetStartRoundID')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None
        else:
            return result_data[0]

    def GetLastRoundID(self, cur_round_id):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT MAX(id) FROM rounds WHERE finished_at is not NULL AND id < %s" % (cur_round_id,))
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetLastRoundID')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None
        else:
            return result_data[0]


    def SetRoundStartTime(self, time, round_id):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("UPDATE rounds SET started_at = %s WHERE id = %s", (time,round_id) )

            self.db_con.commit()
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL SetRoundStartTime')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        return True

    def SetRoundEndTime(self, time, round_id):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("UPDATE rounds SET finished_at = %s WHERE id = %s", (time,round_id) )

            self.db_con.commit()
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL SetRoundEndTime')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        return True

    # Checks if a firewall already exists for a challenge_set_id for a team during a specific (usually) future round
    # Used by the engine to prevent a scoot from overwriting a future firewall
    # NOTE: This is only used by verification due to round timing
    def CheckForFutureFirewallForID( self, firewall_id, round_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT id FROM firewalls WHERE challenge_set_id = (SELECT challenge_set_id FROM firewalls WHERE id = %s) AND round_id = %s AND team_id = (SELECT team_id FROM firewalls WHERE id = %s)", (firewall_id, round_id, firewall_id) )
        except psycopg2.Error as e:
            logging.critical("Could not execute SQL CheckForFutureFirewallForID")
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None

        return result_data[0]
    
    # Used by the engine to delete an old scoot from overwriting a future firewall
    # NOTE: This is only used by verification due to round timing
    def DeleteFirewallForID( self, firewall_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("DELETE FROM firewalls WHERE id = %s", (firewall_id,) )
            
            self.db_con.commit()
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL DeleteFirewallForID')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        return None

    # Checks if a replacement already exists for a challenge_binary_id for a team during a specific (usually) future round
    # Used by the engine to prevent a scoot from overwriting a future replacement
    # NOTE: This is only used by verification due to round timing
    def CheckForFutureReplacementForID( self, replacement_id, round_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT id FROM replacements WHERE challenge_binary_id = (SELECT challenge_binary_id FROM replacements WHERE id = %s) AND round_id = %s AND team_id = (SELECT team_id FROM replacements WHERE id = %s)", (replacement_id, round_id, replacement_id) )
        except psycopg2.Error as e:
            logging.critical("Could not execute SQL CheckForFutureReplacementForID")
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None

        return result_data[0]

    # Used by the engine to delete an old scoot from overwriting a future replacement
    # NOTE: This is only used by verification due to round timing
    def DeleteReplacementForID( self, replacement_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("DELETE FROM replacements WHERE id = %s", (replacement_id,) )
            
            self.db_con.commit()
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL DeleteReplacementForID')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        return None

    def GetNextRoundToRun(self, cur_round_id):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT id FROM rounds WHERE id > %s AND started_at is null ORDER BY id ASC", (cur_round_id,) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetNextRoundToRun')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None

        return result_data[0]

    def GetRoundSeed( self, cur_round_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT seed FROM rounds WHERE id = %s", (cur_round_id,) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetRoundSeed')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None
        
        return result_data[0]

    def GetRoundSecret( self, cur_round_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT secret FROM rounds WHERE id = %s", (cur_round_id,) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetRoundSecret')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None

        return result_data[0]

    def SetRoundSecret( self, round_secret, cur_round_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("UPDATE rounds SET secret = %s WHERE id = %s", (psycopg2.Binary(round_secret),cur_round_id) )

            self.db_con.commit()
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL SetRoundSecret')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        return True

    def GetIDSDigest( self, round_id, team_id, cs_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT digest FROM firewalls WHERE team_id = %s AND round_id = %s AND challenge_set_id = %s", (team_id, round_id, cs_id))
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetIDSDigest')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None
       
        return result_data[0]

    # Scoot an RCB entry to the next round (scoot_to_round_id) -- used when a challenge set is first enabled (first released) and an RCB is uploaded.
    # This will push that upload into the next round so that the CS has at least one round available for original CB's to be POV'ed
    def ScootRCBToRound( self, replacements_id, scoot_to_round_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("UPDATE replacements SET round_id = %s, scoot = true WHERE id = %s", (scoot_to_round_id, replacements_id) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL ScootRCBToRound')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        return True

    # Scoot a firewall entry to the next round (scoot_to_round_id) -- used when a challenge set is first enabled (first released) and a Firewall entry is uploaded.
    # This will push that upload into the next round so that the CS has at least one round available for original CB's to be POV'ed
    def ScootFirewallToRound( self, firewall_id, scoot_to_round_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("UPDATE firewalls SET round_id = %s, scoot = true WHERE id = %s", (scoot_to_round_id, firewall_id) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL ScootFirewallToRound')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        return True

    # WasRCBFieldedInRoundForCS -- check if an RCB was uploaded for a team and cs during a round_id 
    def WasRCBFieldedInRoundForCS( self, team_id, cs_id, round_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT COUNT(id) FROM replacements WHERE challenge_binary_id IN (SELECT id FROM challenge_binaries WHERE challenge_set_id = %s) AND round_id = %s AND team_id = %s", (cs_id, round_id, team_id) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL WasRCBFieldedInRound')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return False

        if result_data[0] > 0:
            return True
        else:
            return False

    # WasFirewallFieldedInROundForCS -- check if a firewall was uploaded for a team and cs during a round_id
    def WasFirewallFieldedInRoundForCS( self, team_id, cs_id, round_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT COUNT(id) FROM firewalls WHERE challenge_set_id = %s AND team_id = %s AND round_id = %s", (cs_id, team_id, round_id) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL WasFirewallFieldedInRoundForCS')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return False

        if result_data[0] > 0:
            return True
        else:
            return False

    # Check if CS was enabled last round
    def WasCSEnabledForRound( self, cs_id, round_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT MIN(round_id) FROM enablements WHERE challenge_set_id = %s", (cs_id, ))
        except psycopg2.Error as e:
            logging.critical( "Could not execute SQL WasCSEnabledForRound")
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return False

        if result_data[0] is None:
            return False

        # If the minimum enabled round for the challenge_set is the round_id then yes it was just enabled!
        if result_data[0] == round_id:
            return True
        else:
            return False


    def GetChallengeNameForID( self, cs_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT shortname FROM challenge_sets WHERE id = %s", (cs_id,) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetChallengeNameForID')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None
       
        return result_data[0]

    def GetActiveProofIDListForTeamCS_updated( self, round_id, target_id, cs_id, team_id_list ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        id_list = []
        try:
            for from_tid in team_id_list:
                if from_tid == target_id:
                    continue

                con_cursor.execute("SELECT id FROM proofs WHERE round_id = (SELECT MAX(round_id) FROM proofs WHERE round_id <= %s AND challenge_set_id = %s AND target_id = %s AND team_id = %s) AND challenge_set_id = %s AND target_id = %s AND team_id = %s", (round_id, cs_id, target_id, from_tid, cs_id, target_id, from_tid ) )

                result_data = con_cursor.fetchone()
                if result_data is None:
                    continue
                else:
                    id_list.append( result_data[0] )

        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetActiveProofIDListForTeamCS')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        return id_list

    def GetActiveProofIDListForTeamCS( self, round_id, team_id, cs_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT id FROM proofs WHERE round_id = (SELECT MAX(round_id) FROM proofs WHERE round_id <= %s AND challenge_set_id = %s AND target_id = %s) AND challenge_set_id = %s AND target_id = %s", (round_id, cs_id, team_id, cs_id, team_id) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetActiveProofIDListForTeamCS')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchall()

        if result_data is None:
            return []
        else:
            index_list = []
            for item in result_data:
                index_list.append( item[0] )

            return index_list

    def GetProofDataForID( self, proof_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT id, digest, team_id, throws FROM proofs WHERE id = %s", (proof_id,) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetProofDataForID')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()

        return result_data

    def GetProofDataForTeamCS( self, round_id, team_id, cs_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT id, digest, team_id, throws FROM proofs WHERE round_id = %s AND challenge_set_id = %s AND target_id = %s", (round_id, cs_id, team_id) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetProofDataForTeamCS' )
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchall()

        return result_data

    # Used to get firewall data for a team and CS that was added at a specific round -- this would be used by the engine to determine if a firewall
    # was just uploaded
    def GetFirewallDataForTeamCSForRound( self, round_id, team_id, cs_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT id, digest FROM firewalls WHERE round_id = %s AND team_id = %s AND challenge_set_id = %s", (round_id, team_id, cs_id) )
        except psycopg2.Error as e:
            logging.critical( "Could not execute SQL GetFirewallDataForTeamCS" )
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None

        return result_data

    # Used to get active firewall data up to the most recent in progress
    def GetActiveFirewallDataForTeamCS( self, last_round_id, team_id, cs_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT id, digest FROM firewalls WHERE round_id = (SELECT MAX(round_id) FROM firewalls WHERE round_id < %s AND challenge_set_id = %s AND team_id = %s) AND challenge_set_id = %s AND team_id = %s", (last_round_id, cs_id, team_id, cs_id, team_id) )
        except psycopg2.Error as e:
            logging.critical( "Could not execute SQL GetActiveFirewallDataForTeamCS" )
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None

        return result_data

    def GetReplacementCBDataForID( self, replacement_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT replacements.id AS id, replacements.digest AS digest, replacements.size AS size, challenge_binaries.index AS index FROM replacements, challenge_binaries WHERE replacements.id = %s AND challenge_binaries.id = replacements.challenge_binary_id", (replacement_id,) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetReplacementCBDataForID')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None

        return result_data

    # This function will return the sum of all challenge_binaries sizes for the reference patched CB (patched_size)
    def GetReferencePatchedFileSizeForCS( self, cs_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT SUM(patched_size) FROM challenge_binaries WHERE challenge_set_id = %s", (cs_id,) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetReferencePatchedFileSizeForCS')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None
       
        return result_data[0]


    ''' SQL to get active replacements for a challenge_set:
    SELECT DISTINCT ON (r0.challenge_binary_id) r0.id, r0.digest, r0.size, r0.team_id, r0.round_id, r0.challenge_binary_id, r0.inserted_at, r0.updated_at FROM replacements AS r0 WHERE (((r0.team_id = 1) AND (r0.round_id <= 2)) AND r0."challenge_binary_id" IN (SELECT id FROM challenge_binaries WHERE challenge_set_id = 3)) ORDER BY r0.challenge_binary_id, r0.updated_at DESC, r0.id DESC;
    '''

    # Uses the database to get the current file size for the original CS (used if there are no replacements)
    def GetOriginalFileSizeForCS( self, cs_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute( "SELECT SUM(size) FROM challenge_binaries WHERE challenge_set_id = %s", (cs_id,) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetOriginalFileSizeForCS')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None

        return result_data[0]

    # Uses the database to get the current file size for a CS for a Team
    def GetCurrentFileSizeForCSForTeam( self, round_id, cs_id, team_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT SUM(size) FROM (SELECT DISTINCT ON (r0.challenge_binary_id) r0.id, r0.size as size FROM replacements AS r0 WHERE (((r0.team_id = %s) AND (r0.round_id < %s)) AND r0.challenge_binary_id IN (SELECT id FROM challenge_binaries WHERE challenge_set_id = %s)) ORDER BY r0.challenge_binary_id, r0.updated_at DESC, r0.id DESC) AS foo", (team_id, round_id, cs_id) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetCurrentFileSizeForCSForTeam')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None

        return result_data[0]


    # This function extracts the performance data metrics for successful polls
    def GetPollPerformanceData( self, round_id, cs_id, team_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT pollers.id, pollers.mean_wall_time, pollers.stddev_wall_time, poll_feedbacks.wall_time, pollers.mean_max_rss, pollers.stddev_max_rss, poll_feedbacks.max_rss, pollers.mean_min_flt, pollers.stddev_min_flt, poll_feedbacks.min_flt, pollers.mean_cpu_clock, pollers.stddev_cpu_clock, poll_feedbacks.cpu_clock FROM pollers, poll_feedbacks WHERE pollers.id = poll_feedbacks.poller_id AND pollers.challenge_set_id = %s AND pollers.round_id = %s AND poll_feedbacks.team_id = %s AND poll_feedbacks.status = 'success'", (cs_id, round_id, team_id) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetPollPerformanceData')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchall()

        # A list of lists...
        return result_data
    
    def GetPollCountForCS( self, round_id, cs_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT COUNT(id) FROM pollers WHERE challenge_set_id = %s AND round_id = %s", (cs_id, round_id) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetPollCountForCS')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None
       
        return result_data[0]
   
    def GetPollsPassedForTeam( self, round_id, cs_id, team_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT COUNT(id) FROM poll_feedbacks WHERE poller_id IN (SELECT id FROM pollers WHERE challenge_set_id = %s AND round_id = %s) AND team_id = %s AND status = 'success'", (cs_id, round_id, team_id) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetPollsPassedForTeam')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None
       
        return result_data[0]

    def GetPollsFailedForTeam( self, round_id, cs_id, team_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT COUNT(id) FROM poll_feedbacks WHERE poller_id IN (SELECT id FROM pollers WHERE challenge_set_id = %s AND round_id = %s) AND team_id = %s AND status != 'success'", (cs_id, round_id, team_id) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetPollsFailedForTeam')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None
       
        return result_data[0]


    # Use this to return the number of successful PoV's against all other teams (this only counts distinct teams) for a round
    # NOTE: this ignores the ignore_team_id -- so we don't count ourselves for a successful PoV against ourself
    def GetSuccessfulPOVTeamCountAgainstOthersButTeamID( self, round_id, cs_id, team_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT COUNT(DISTINCT target_id) FROM proofs WHERE challenge_set_id = %s AND team_id = %s AND target_id != %s AND id IN (SELECT proof_id FROM proof_feedbacks WHERE round_id = %s AND successful = True)", (cs_id, team_id, team_id, round_id) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetSuccessfulPOVTeamCountAgainstOthersButTeamID')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None
       
        return result_data[0]

    # Use this to return the number of successful PoV's against a specific target team ID for a challenge_set and round ID
    def GetSuccessfulPOVCountForTargetTeamID( self, round_id, cs_id, target_team_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT COUNT(id) as proof_against_count FROM proof_feedbacks WHERE proof_id IN (SELECT id FROM proofs WHERE challenge_set_id = %s AND target_id = %s) AND successful = true AND round_id = %s", (cs_id, target_team_id, round_id) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetSuccessfulPOVCountForTargetTeamID')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None
       
        return result_data[0]

    def GetReplacementsIDListForTeamCS( self, round_id, cs_id, team_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT id FROM replacements WHERE round_id = %s AND challenge_binary_id IN (SELECT id FROM challenge_binaries WHERE challenge_set_id = %s) AND team_id = %s", (round_id, cs_id, team_id) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetReplacementsIDListForTeamCS')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchall()
        if result_data is None:
            return []
        else:
            index_list = []
            for item in result_data:
                index_list.append( item[0] )

            return index_list

    def GetChallengeBinaryIndexList( self, cs_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT index FROM challenge_binaries WHERE challenge_set_id = %s ORDER BY index ASC", (cs_id,) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetChallengeBinaryIndexList')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchall()
        if result_data is None:
            return None
        else:
            index_list = []
            for item in result_data:
                index_list.append( item[0] )

            return index_list
    
    def GetChallengeBinaryIndexIDList( self, cs_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT index, id FROM challenge_binaries WHERE challenge_set_id = %s ORDER BY index ASC", (cs_id,) )
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetChallengeBinaryIndexList')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchall()
        if result_data is None:
            return None
        else:
            index_list = []
            for item in result_data:
                index_list.append( { 'index': item[0], 'id': item[1] } )

            return index_list

    def GetPollIDFromSeed( self, round_id, cs_id, poll_seed ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute( 'SELECT id FROM pollers WHERE round_id = %s AND challenge_set_id = %s AND seed = %s', (round_id, cs_id, psycopg2.Binary( poll_seed )) )

        except psycopg2.Error as e:
            logging.critical("Could not execute SQL command for GetPollIDFromSeed")
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None

        return result_data[0]

    def AddCrashFeedback( self, round_id, team_id, challenge_binary_id, signal, timestamp ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute( 'INSERT INTO crashes( signal, team_id, round_id, challenge_binary_id, timestamp, inserted_at, updated_at ) VALUES ( %s, %s, %s, %s, %s, now(), now() )', ( signal, team_id, round_id, challenge_binary_id, timestamp ) )

            self.db_con.commit()
        
        except psycopg2.Error as e:
            logging.critical("Could not execute SQL command to AddCrashFeedback")
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        return True

    def AddPollFeedbackOnSuccess( self, poll_id, team_id, poll_status, max_rss, min_flt, utime, cpu_clock, task_clock, wall_time ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute( 'INSERT INTO poll_feedbacks( wall_time, max_rss, min_flt, utime, task_clock, cpu_clock, status, team_id, poller_id, inserted_at, updated_at ) VALUES ( %s, %s, %s, %s, %s, %s, %s, %s, %s, now(), now() )', (wall_time, max_rss, min_flt, utime, task_clock, cpu_clock, poll_status, team_id, poll_id ) )

            self.db_con.commit()

        except psycopg2.Error as e:
            logging.critical("Could not execute SQL command to AddPollFeedbackOnSuccess")
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        return True

    def AddTeamCSScore( self, round_id, team_id, cs_id, availability_score, security_score, evaluation_score, perf_score, func_score, team_score ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute( 'INSERT INTO scores( round_id, team_id, challenge_set_id, availability, security, evaluation, performance, functionality, inserted_at, updated_at  ) VALUES ( %s, %s, %s, %s, %s, %s, %s, %s, now(), now() )', (round_id, team_id, cs_id, availability_score, security_score, evaluation_score, perf_score, func_score) )

            con_cursor.execute( 'UPDATE teams SET score = score + %s WHERE id = %s', (team_score, team_id) )

            self.db_con.commit()

        except psycopg2.Error as e:
            logging.critical("Could not execute SQL command to AddTeamCSScore (%s)" % (repr(e)) )
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        return True

    def AddPollFeedbackOnFailure( self, poll_id, team_id, poll_status ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute( 'INSERT INTO poll_feedbacks( status, team_id, poller_id, inserted_at, updated_at ) VALUES ( %s, %s, %s, now(), now() )', (poll_status, team_id, poll_id ) )

            self.db_con.commit()

        except psycopg2.Error as e:
            logging.critical("Could not execute SQL command to AddPollFeedbackOnFailure (%s)" % (repr(e)) )
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        return True


    def AddProofFeedback( self, round_id, cs_id, team_id, from_tid, cb_seed, pov_seed, pov_success, pov_error, pov_extra_error, pov_signal, pov_type ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            # Get the last active proof for this proof_feedback
            con_cursor.execute( 'SELECT MAX(id) AS id FROM proofs WHERE team_id = %s AND round_id < %s AND challenge_set_id = %s AND target_id = %s', (from_tid, round_id, cs_id, team_id) )

            result_data = con_cursor.fetchone()
            if result_data is None:
                logging.error( "AddProofFeedback::Database entry for proofs did not exist for POV, but one was added by engine! (team_id=%d, round_id=%d, challenge_set_id=%d, target_id=%d)" % (from_tid, round_id, cs_id, team_id) )
                return None

            proof_id = result_data[0]
            if proof_id is None:
                logging.error( "AddProofFeedback::Database entry for proofs did not exist for POV, but one was added by engine, ignoring this PoV! (team_id=%d, round_id=%d, challenge_set_id=%d, target_id=%d)" % (from_tid, round_id, cs_id, team_id) )
                return None

            con_cursor.execute( "INSERT INTO proof_feedbacks (throw, successful, error, error_extra, signal, proof_id, round_id, type, seed, pov_seed, inserted_at, updated_at ) SELECT COALESCE(MAX(throw),0)+1, %s, %s, %s, %s, %s, %s, %s, %s, %s, now(), now() FROM proof_feedbacks WHERE proof_id = %s AND round_id = %s", (pov_success, pov_error, pov_extra_error, pov_signal, proof_id, round_id, pov_type, psycopg2.Binary(cb_seed), psycopg2.Binary(pov_seed), proof_id, round_id) )

            #print con_cursor.mogrify( "INSERT INTO proof_feedbacks (throw, successful, error, signal, proof_id, round_id, type, seed, pov_seed, inserted_at, updated_at ) SELECT COALESCE(MAX(throw),0)+1, %s, %s, %s, %s, %s, %s, %s, %s, now(), now() FROM proof_feedbacks WHERE proof_id = %s AND round_id = %s", (pov_success, pov_error, pov_signal, proof_id, round_id, pov_type, psycopg2.Binary(cb_seed), psycopg2.Binary(pov_seed), proof_id, round_id) )
            self.db_con.commit()
        except psycopg2.Error as e:
            logging.critical("Could not execute SQL command to AddProofFeedback" )
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        return True

    def AddPollBaselinePerformance( self, cs_id, round_id, file_id, seed, mean_wall_time, stddev_wall_time, mean_max_rss, stddev_max_rss, mean_min_flt, stddev_min_flt, mean_utime, stddev_utime, mean_task_clock, stddev_task_clock, mean_cpu_clock, stddev_cpu_clock ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("INSERT INTO pollers (seed, mean_wall_time, stddev_wall_time, mean_max_rss, stddev_max_rss, mean_min_flt, stddev_min_flt, mean_utime, stddev_utime, mean_task_clock, stddev_task_clock, mean_cpu_clock, stddev_cpu_clock, round_id, challenge_set_id, file_id, inserted_at, updated_at) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,now(),now())", (psycopg2.Binary(seed), mean_wall_time, stddev_wall_time, mean_max_rss, stddev_max_rss, mean_min_flt, stddev_min_flt, mean_utime, stddev_utime, mean_task_clock, stddev_task_clock, mean_cpu_clock, stddev_cpu_clock, round_id, cs_id, file_id) )
            #con_cursor.execute("INSERT INTO pollers (seed, mean_wall_time, stddev_wall_time, mean_max_rss, stdddev_max_rss, mean_min_flt, stddev_min_flt, mean_utime, stddev_utime, mean_task_clock, stddev_task_clock, mean_cpu_clock, stddev_cpu_clock, round_id, challenge_set_id, file_id, inserted_at, updated_at) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,now(),null) ON CONFLICT (round_id, challenge_set_id) DO UPDATE SET mean_wall_time=%s, stddev_wall_time=%s, mean_max_rss=%s, stddev_max_rss=%s, mean_min_flt=%s, stddev_min_flt=%s, mean_utime=%s, stddev_utime=%s, mean_task_clock=%s, stddev_task_clock=%s, mean_cpu_clock=%s, stddev_cpu_clock=%s, file_id=%s", (psycopg2.Binary(seed), mean_wall_time, stddev_wall_time, mean_max_rss, stddev_max_rss, mean_min_flt, stddev_min_flt, mean_utime, stddev_utime, mean_task_clock, stddev_task_clock, mean_cpu_clock, stddev_cpu_clock, round_id, cs_id, file_id, mean_wall_time, stddev_wall_time, mean_max_rss, stddev_max_rss, mean_min_flt, stddev_min_flt, mean_utime, stddev_utime, mean_task_clock, stddev_task_clock, mean_cpu_clock, stddev_cpu_clock, file_id) )

            self.db_con.commit()
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL AddPollBaselinePerformance')
            raise WADBErrorException( "SQL error: %s" % repr(e) )

        return True

###################################
#                                 #
# ADDED FOR VERIFICATION PURPOSES #
#                                 #
################################### 

    def AddChallengeSet( self, cgc_id, cs_name, cs_shortname ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()
        new_id = None

        try:
            con_cursor.execute("INSERT INTO challenge_sets (name, shortname, inserted_at, updated_at) VALUES (%s,%s,now(),now()) RETURNING id", (cs_name, cs_shortname))
            new_id = con_cursor.fetchone()[0]
           
            con_cursor.execute("INSERT INTO challenge_set_aliases (cgc_id, challenge_set_id, inserted_at, updated_at) VALUES (%s,%s,now(),now())", (cgc_id, new_id))

            self.db_con.commit()
        except psycopg2.Error as e:
            print con_cursor.mogrify("INSERT INTO challenge_sets (name, shortname, inserted_at, updated_at) VALUES (%s,%s,now(),now())", (cs_name, cs_shortname))
            print "new_id: ", new_id
            print con_cursor.mogrify("INSERT INTO challenge_set_aliases (cgc_id, challenge_set_id, inserted_at, updated_at) VALUES (%s,%s,now(),now())", (cgc_id, new_id))
            logging.critical('Could not execute SQL AddChallengeSet')
            raise

        return True

    def AddChallengeBinaryInfo( self, csid, cb_name, cb_num_of_binaries, cb_size, cb_patched_size ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()
        
        try:
            con_cursor.execute("INSERT INTO challenge_binaries (index, size, challenge_set_id, inserted_at, updated_at, patched_size) VALUES ( %s,%s,(SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s),(SELECT inserted_at FROM challenge_sets WHERE name = %s),(SELECT updated_at FROM challenge_sets WHERE name = %s),%s)", (cb_num_of_binaries, cb_size, csid, cb_name, cb_name, cb_patched_size))
            self.db_con.commit()
        except psycopg2.Error as e:
            print con_cursor.mogrify("INSERT INTO challenge_binaries (index, size, challenge_set_id, inserted_at, updated_at, patched_size) VALUES ( %s,%s,(SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s),(SELECT inserted_at FROM challenge_sets WHERE name = %s),(SELECT updated_at FROM challenge_sets WHERE name = %s),%s)", (cb_num_of_binaries, cb_size, csid, cb_name, cb_name, cb_patched_size))
            logging.critical('Could not execute SQL AddChallengeBinaryInfo')
            raise

        return True

    def AddTeam( self, team_id, name, score ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("INSERT INTO teams (id,name,inserted_at,updated_at,score) VALUES (%s,%s,now(),now(),%s)", (team_id, name, score))
            self.db_con.commit()
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL AddTeam')
            raise

        return True

    def AddProof( self, digest, team_id, round_id, csid, target_id, throws ):
      if self.db_con is None:
          raise WADBNotConnectedException("DB not connected")

      con_cursor = self.db_con.cursor()

      try:
          con_cursor.execute("INSERT INTO proofs (digest, team_id, round_id, challenge_set_id, target_id, throws, inserted_at, updated_at) VALUES (%s,%s,%s,(SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s),%s,%s,now(),now())", (digest, team_id, round_id, csid, target_id, throws))
          self.db_con.commit()
      except psycopg2.Error as e:
          logging.critical('Could not execute SQL AddProof')
          raise

      return True

    def AddRound( self, round_id, secret, seed):
      if self.db_con is None:
          raise WADBNotConnectedException("DB not connected")

      con_cursor = self.db_con.cursor()

      try:
          con_cursor.execute("INSERT INTO rounds (id, inserted_at, updated_at, secret, seed) VALUES (%s,now(),now(),%s,%s)", (round_id, psycopg2.Binary(secret), psycopg2.Binary(seed)) )
          self.db_con.commit()
      except psycopg2.Error as e:
          logging.critical('Could not execute SQL AddRound')
          raise

      return True

    def AddFirewall(self, digest, team_id, round_id, csid):
      if self.db_con is None:
          raise WADBNotConnectedException("DB not connected")

      con_cursor = self.db_con.cursor()

      try:
          con_cursor.execute("INSERT INTO firewalls (digest, team_id, round_id, challenge_set_id, inserted_at, updated_at) VALUES (%s,%s,%s,(SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s),now(),now()) ON CONFLICT (team_id, round_id, challenge_set_id) DO UPDATE SET (digest) = (%s)", (digest, team_id, round_id, csid, digest))
          self.db_con.commit()
      except psycopg2.Error as e:
          logging.critical('Could not execute SQL AddFirewall')
          raise

      return True

    def AddReplacement(self, digest, team_id, round_id, csid, index, size):
      if self.db_con is None:
          raise WADBNotConnectedException("DB not connected")

      con_cursor = self.db_con.cursor()

      try:
          con_cursor.execute("INSERT INTO replacements (digest, team_id, round_id, inserted_at, updated_at, challenge_binary_id, size) VALUES (%s,%s,%s,now(),now(),(SELECT id FROM challenge_binaries WHERE challenge_set_id = (SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s) AND index = %s),%s) ON CONFLICT (team_id, round_id, challenge_binary_id) DO UPDATE SET (digest) = (%s)", (digest, team_id, round_id, csid, index, size, digest))
          
          self.db_con.commit()
      except psycopg2.Error as e:
          logging.critical('Could not execute SQL AddReplacement: %s' % e)
          raise

      return True

    def AddEnablement( self, round_id, csid ):
      if self.db_con is None:
          raise WADBNotConnectedException("DB not connected")

      con_cursor = self.db_con.cursor()

      try:
          con_cursor.execute("INSERT INTO enablements (round_id, challenge_set_id, inserted_at, updated_at) VALUES (%s, (SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s), now(), now())", (round_id, csid))

          self.db_con.commit()
      except psycopg2.Error as e:
          logging.critical('Could not execute SQL AddReplacement')
          raise

      return True

    def GetChallengeSetIDMapping( self, cgc_id ):
      if self.db_con is None:
          raise WADBNotConnectedException("DB not connected")

      con_cursor = self.db_con.cursor()

      try:
          con_cursor.execute("SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s", (cgc_id,) )
      except psycopg2.Error as e:
          logging.critical('Could not execute SQL GetChallengeSetIDMapping')
          raise

      result_data = con_cursor.fetchone()
      if result_data is None:
          return None

      return result_data[0]

    def ClearTables( self ):
      if self.db_con is None:
          raise WADBNotConnectedException("DB not connected")

      con_cursor = self.db_con.cursor()

      try:
          con_cursor.execute("TRUNCATE teams CASCADE")
          con_cursor.execute("TRUNCATE rounds CASCADE")
          con_cursor.execute("TRUNCATE challenge_sets CASCADE")

          self.db_con.commit()
      except psycopg2.Error as e:
          logging.critical('Could not execute SQL ClearTables')
          raise

      return True

    def GetLastReplacementUpload( self, team_id, round_id, csid ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT DISTINCT ON (r0.challenge_binary_id) r0.id, r0.digest, r1.index, r0.size, r0.team_id, r0.round_id, r0.challenge_binary_id, r0.inserted_at, r0.updated_at FROM replacements AS r0, challenge_binaries as r1 WHERE (((r0.team_id = %s) AND (r0.round_id <= %s)) AND r0.challenge_binary_id IN (SELECT id FROM challenge_binaries WHERE challenge_set_id = (SELECT challenge_set_id from challenge_set_aliases WHERE cgc_id = %s))) ORDER BY r0.challenge_binary_id, r0.updated_at DESC, r0.id DESC", 
                                (team_id, round_id, csid))
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetLastReplacementUpload')
            raise

        result_data = con_cursor.fetchall()
        if result_data is None:
            return None
        else:
            rcb_list = []
            for item in result_data:
                rcb_list.append( item )

            return rcb_list

    def GetLastFirewallUpload( self, team_id, round_id, csid ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected")

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT id, digest FROM firewalls WHERE round_id = (SELECT MAX(round_id) FROM firewalls WHERE round_id < %s AND challenge_set_id = (SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s) AND team_id = %s) AND challenge_set_id = (SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s) AND team_id = %s", 
                                (round_id, csid, team_id, csid, team_id))
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetLastFirewallUpload')
            raise

        result_data = con_cursor.fetchone()
        if result_data is None:
            return None

        return result_data
     
    def DeleteRoundsOnward( self, round_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected");

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("DELETE FROM poll_feedbacks WHERE poller_id IN (SELECT id FROM pollers WHERE round_id >= %s)", (round_id,))
            con_cursor.execute("DELETE FROM pollers WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM proof_feedbacks WHERE proof_id IN (SELECT id FROM proofs WHERE round_id >= %s)", (round_id,))
            con_cursor.execute("DELETE FROM proofs WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM firewalls WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM evaluations WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM container_reports WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM crashes WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM enablements WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM replacements WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM scores WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM rounds WHERE id >= %s", (round_id,))

            self.db_con.commit()
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL DeleteRoundsForward')
            raise

        return True

    def DeleteSingleRound( self, round_id ):
        if self.db_con is None:
            raise WADBNotConnectedException("DB not connected");

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("DELETE FROM poll_feedbacks WHERE poller_id IN (SELECT id FROM pollers WHERE round_id = %s)", (round_id,))
            con_cursor.execute("DELETE FROM proof_feedbacks WHERE proof_id IN (SELECT id FROM proofs WHERE round_id = %s)", (round_id,))
            con_cursor.execute("DELETE FROM poll_feedbacks WHERE poller_id IN (SELECT id FROM pollers WHERE round_id = %s)", (round_id,))
            con_cursor.execute("DELETE FROM evaluations WHERE round_id = %s", (round_id,))
            con_cursor.execute("DELETE FROM container_reports WHERE round_id = %s", (round_id,))
            con_cursor.execute("DELETE FROM crashes WHERE round_id = %s", (round_id,))
            con_cursor.execute("DELETE FROM scores WHERE round_id = %s", (round_id,))

            self.db_con.commit()
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL DeleteSingleRound')
            raise

        return True


class CFEDBEngine():
    def __init__(self):
        self.ConnectDB()

    def ConnectDB( self ):
        # Initialize #VDBEngine
        try:
            self.db_con = psycopg2.connect("dbname='%s' user='%s' host='%s' password='%s'" % (settings.VERIFY_DATABASE_NAME, settings.ENGINE_USER_NAME, settings.ENGINE_DATABASE_HOST, settings.ENGINE_PASSWORD) )
        except psycopg2.Error as e:
            logging.critical('Could not connect to database (%s).' % (repr(e)))
            self.db_con = None

    def AddChallengeSet( self, cgc_id, cs_name, cs_shortname ):
        if self.db_con is None:
            return None

        con_cursor = self.db_con.cursor()
        new_id = None

        try:
            con_cursor.execute("INSERT INTO challenge_sets (name, shortname, inserted_at, updated_at) VALUES (%s,%s,now(),now()) RETURNING id", (cs_name, cs_shortname))
            new_id = con_cursor.fetchone()[0]
           
            con_cursor.execute("INSERT INTO challenge_set_aliases (cgc_id, challenge_set_id, inserted_at, updated_at) VALUES (%s,%s,now(),now())", (cgc_id, new_id))

            self.db_con.commit()
        except psycopg2.Error as e:
            print con_cursor.mogrify("INSERT INTO challenge_sets (name, shortname, inserted_at, updated_at) VALUES (%s,%s,now(),now())", (cs_name, cs_shortname))
            print "new_id: ", new_id
            print con_cursor.mogrify("INSERT INTO challenge_set_aliases (cgc_id, challenge_set_id, inserted_at, updated_at) VALUES (%s,%s,now(),now())", (cgc_id, new_id))
            logging.critical('Could not execute SQL AddChallengeSet')
            raise

        return True

    def AddChallengeBinaryInfo( self, csid, cb_name, cb_num_of_binaries, cb_size, cb_patched_size ):
        if self.db_con is None:
            return None

        con_cursor = self.db_con.cursor()
        
        try:
            con_cursor.execute("INSERT INTO challenge_binaries (index, size, challenge_set_id, inserted_at, updated_at, patched_size) VALUES ( %s,%s,(SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s),(SELECT inserted_at FROM challenge_sets WHERE name = %s),(SELECT updated_at FROM challenge_sets WHERE name = %s),%s)", (cb_num_of_binaries, cb_size, csid, cb_name, cb_name, cb_patched_size))
            self.db_con.commit()
        except psycopg2.Error as e:
            print con_cursor.mogrify("INSERT INTO challenge_binaries (index, size, challenge_set_id, inserted_at, updated_at, patched_size) VALUES ( %s,%s,(SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s),(SELECT inserted_at FROM challenge_sets WHERE name = %s),(SELECT updated_at FROM challenge_sets WHERE name = %s),%s)", (cb_num_of_binaries, cb_size, csid, cb_name, cb_name, cb_patched_size))
            logging.critical('Could not execute SQL AddChallengeBinaryInfo')
            raise

        return True

    def AddTeam( self, team_id, name, score ):
        if self.db_con is None:
            return None

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("INSERT INTO teams (id,name,inserted_at,updated_at,score) VALUES (%s,%s,now(),now(),%s)", (team_id, name, score))
            self.db_con.commit()
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL AddTeam')
            raise

        return True

    def AddProof( self, digest, team_id, round_id, csid, target_id, throws ):
      if self.db_con is None:
          return None

      con_cursor = self.db_con.cursor()

      try:
          con_cursor.execute("INSERT INTO proofs (digest, team_id, round_id, challenge_set_id, target_id, throws, inserted_at, updated_at) VALUES (%s,%s,%s,(SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s),%s,%s,now(),now())", (digest, team_id, round_id, csid, target_id, throws))
          self.db_con.commit()
      except psycopg2.Error as e:
          logging.critical('Could not execute SQL AddProof')
          raise

      return True

    def AddRound( self, round_id, secret, seed):
      if self.db_con is None:
          return None

      con_cursor = self.db_con.cursor()

      try:
          con_cursor.execute("INSERT INTO rounds (id, inserted_at, updated_at, secret, seed) VALUES (%s,now(),now(),%s,%s)", (round_id, secret, seed) )
          self.db_con.commit()
      except psycopg2.Error as e:
          logging.critical('Could not execute SQL AddRound')
          raise

      return True

    def AddFirewall(self, digest, team_id, round_id, csid):
      if self.db_con is None:
          return None

      con_cursor = self.db_con.cursor()

      try:
          con_cursor.execute("INSERT INTO firewalls (digest, team_id, round_id, challenge_set_id, inserted_at, updated_at) VALUES (%s,%s,%s,(SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s),now(),now()) ON CONFLICT (team_id, round_id, challenge_set_id) DO UPDATE SET (digest) = (%s)", (digest, team_id, round_id, csid, digest))
          self.db_con.commit()
      except psycopg2.Error as e:
          logging.critical('Could not execute SQL AddFirewall')
          raise

      return True


    def AddReplacement(self, digest, team_id, round_id, csid, index, size):
      if self.db_con is None:
          return None

      con_cursor = self.db_con.cursor()

      try:
          con_cursor.execute("INSERT INTO replacements (digest, team_id, round_id, inserted_at, updated_at, challenge_binary_id, size) VALUES (%s,%s,%s,now(),now(),(SELECT id FROM challenge_binaries WHERE challenge_set_id = (SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s) AND index = %s),%s) ON CONFLICT (team_id, round_id, challenge_binary_id) DO UPDATE SET (digest) = (%s)", (digest, team_id, round_id, csid, index, size, digest))
          
          self.db_con.commit()
      except psycopg2.Error as e:
          logging.critical('Could not execute SQL AddReplacement: %s' % e)
          raise

      return True

    def AddEnablement( self, round_id, csid ):
      if self.db_con is None:
          return None

      con_cursor = self.db_con.cursor()

      try:
          con_cursor.execute("INSERT INTO enablements (round_id, challenge_set_id, inserted_at, updated_at) VALUES (%s, (SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s), now(), now())", (round_id, csid))

          self.db_con.commit()
      except psycopg2.Error as e:
          logging.critical('Could not execute SQL AddReplacement')
          raise

      return True

    def GetChallengeSetIDMapping( self, cgc_id ):
      if self.db_con is None:
          return None

      con_cursor = self.db_con.cursor()

      try:
          con_cursor.execute("SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s", (cgc_id,) )
      except psycopg2.Error as e:
          logging.critical('Could not execute SQL GetChallengeSetIDMapping')

      result_data = con_cursor.fetchone()
      if result_data is None:
          return None

      return result_data[0]

    def ClearTables( self ):
      if self.db_con is None:
          return None

      con_cursor = self.db_con.cursor()

      try:
          con_cursor.execute("TRUNCATE teams CASCADE")
          con_cursor.execute("TRUNCATE rounds CASCADE")
          con_cursor.execute("TRUNCATE challenge_sets CASCADE")

          self.db_con.commit()
      except psycopg2.Error as e:
          logging.critical('Could not execute SQL ClearTables')
          raise

      return True

    def GetTeamIDList(self):
        if self.db_con is None:
            return None

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("SELECT id FROM teams")
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL GetTeamIDList()')
            return None

        result_data = con_cursor.fetchall()
        if result_data is None:
            return None
        else:
            team_id_list = []
            for item in result_data:
                team_id_list.append( item[0] )

            return team_id_list

    def UpdateScore( self, team_id, score ):
       if self.db_con is None:
           return None

       con_cursor = self.db_con.cursor()

       try:
           con_cursor.execute("UPDATE teams SET score = %s, updated_at = now() WHERE id = %s", (score, team_id))
           self.db_con.commit()

       except psycopg2.Error as e:
           logging.critical('Could not execute SQL UpdateScore')
           raise

       return True

    def AddScoreResult( self, security, availability, evaluation, team_id, round_id, cgc_id, performance ):
      if self.db_con is None:
          return None

      con_cursor = self.db_con.cursor()

      try:
          con_cursor.execute("INSERT INTO scores (security, availability, evaluation, team_id, round_id, inserted_at, updated_at, challenge_set_id, performance) VALUES (%s,%s,%s,%s,%s,now(),now(),(SELECT challenge_set_id FROM challenge_set_aliases WHERE cgc_id = %s),%s)", (security, availability, evaluation, team_id, round_id, cgc_id, performance))
          self.db_con.commit()
      except psycopg2.Error as e:
          logging.critical('Could not execute SQL AddScoreResult')
          raise

      return True

    def DeleteRound( self, round_id ):
        if self.db_con is None:
          return None

        con_cursor = self.db_con.cursor()

        try:
            con_cursor.execute("DELETE FROM poll_feedbacks WHERE poller_id IN (SELECT id FROM pollers WHERE round_id >= %s)", (round_id,))
            con_cursor.execute("DELETE FROM pollers WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM proof_feedbacks WHERE proof_id IN (SELECT id FROM proofs WHERE round_id >= %s)", (round_id,))
            con_cursor.execute("DELETE FROM proofs WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM poll_feedbacks WHERE poller_id IN (SELECT id FROM pollers WHERE round_id >= %s)", (round_id,))
            con_cursor.execute("DELETE FROM pollers WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM firewalls WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM evaluations WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM container_reports WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM crashes WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM enablements WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM replacements WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM scores WHERE round_id >= %s", (round_id,))
            con_cursor.execute("DELETE FROM rounds WHERE id >= %s", (round_id,))

            self.db_con.commit()
        except psycopg2.Error as e:
            logging.critical('Could not execute SQL DeleteRound')
            raise

        return True
