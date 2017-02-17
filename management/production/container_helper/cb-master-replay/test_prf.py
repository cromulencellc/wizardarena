import prf
import binascii
import os

round_secret = os.urandom( 64 )
#round_secret = binascii.unhexlify( "96a087f0f0ee1a9309c2af8fbc25fd302026d22a5bcc18866f988b9ade222e01fbde24aab5b71dcec2209698997ea1a5" )

print "Round Secret: "
print binascii.hexlify( round_secret )

round_seed = os.urandom( 32 )
round_seed = binascii.unhexlify( "1115834a7121b4cd47d622800179c5e392f950d6cf3d167108e06bb0a86a5eb1" )

print "Round Seed: "
print binascii.hexlify( round_seed )

out_prf = prf.TLS_PRF( round_secret, "CROMU_00001 ROUND 1", round_seed, 48 )
out_prf2 = prf.TLS_PRF( round_secret, "CROMU_00002 ROUND 1", round_seed, 48 )

print "PRF 1: "
print binascii.hexlify( out_prf )

print "PRF 2: "
print binascii.hexlify( out_prf2 )

print "Creating a large amount of PRF data!!!"
large_prf_data = prf.TLS_PRF( round_secret, "CROMU_00003 ROUND 1", round_seed, 48*1024 )

print "Created length is: %d\n" % len(large_prf_data)

match_count = 0
pos = 4
while pos < len(large_prf_data)-4:
    find_string = large_prf_data[pos-4:pos]
    search_string = large_prf_data[pos:]

    find_pos = search_string.find( find_string )
    
    if ( find_pos != -1 ):
        match_count += 1
        print "FOUND 4-byte match %s == %s\n" % ( binascii.hexlify( find_string ), binascii.hexlify( search_string[find_pos:find_pos+4] ))

        print "STRING: %s\n" % (binascii.hexlify( large_prf_data[pos-12:pos+12]))
        print "STRING: %s\n" % (binascii.hexlify( large_prf_data[pos+find_pos-8:pos+find_pos+16]))
    pos += 1

print "Match count is: %d\n" % match_count

print "Bytearray of 1 is: ", binascii.hexlify( bytearray( (2,) ) )
