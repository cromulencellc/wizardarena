#!/usr/bin/env python

# rounds.py
#
# Contains functionality for managing the rounds
#
#
import argparse
import binascii
import settings
from database import WADBEngine
import ansi_x931_aes128
import hashlib
from database import WADBEngine

if __name__ == "__main__":
    parser = argparse.ArgumentParser( description="Run rounds to generate round entries in the Database -- this will allow population of the round seed from a magic phrase and it will generate the round seeds from a seeded PRNG" )
    required = parser.add_argument_group(title='required arguments')
    required.add_argument('--round_start', required=True, type=int, help='Start from this round number to the ending round number')
    required.add_argument('--round_end', required=True, type=int, help='End with this round number when populating the database')
    required.add_argument('--secret_phrase', required=True, type=str, help='This secret phrase is used to seed the round seeds')
    required.add_argument('--overwrite_db', required=False, type=bool, default=False, help='Set this to true to overwrite any DB entries')

    args = parser.parse_args()

    if ( args.round_start <= 0 ):
        raise Exception('Invalid starting round, must be 1 or greater')

    if ( args.round_end <= args.round_start ):
        raise Exception('Invalid ending round, must be greater than starting round')

    if ( args.secret_phrase == ''):
        raise Exception('Invalid secret phrase, cannot be an empty string')

    # Use the secret phrase to seed the database round seeds
    secret_phrase = args.secret_phrase
    
    # Calculate seed amount
    round_count = (args.round_end - args.round_start)

    seed_data_count = (round_count * 32)

    secret_phrase_hash = hashlib.sha384(secret_phrase).digest()
    print "Using sha256 hash of secret phrase (%s)" % binascii.hexlify(secret_phrase_hash)

    prng = ansi_x931_aes128.PRNG( secret_phrase_hash )

    prng_data = prng.get( seed_data_count )

    # Get a handle to the database
    wa_db = WADBEngine()

    print "Generating round data for rounds %d -> %d" % (args.round_start, args.round_end)
    cur_round = args.round_start
    seed_pos_start = 0
    while cur_round < args.round_end:
        round_seed = prng_data[seed_pos_start:seed_pos_start+32]
        print "ROUND[%d] using seed: %s" % (cur_round, binascii.hexlify( round_seed ))

        try:
            wa_db.AddRound( cur_round, '', round_seed )
        except:
            print "Failed to add round -- going to next"

        
        seed_pos_start += 32
        cur_round += 1
