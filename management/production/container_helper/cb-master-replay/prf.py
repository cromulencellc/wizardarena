#!/usr/bin/env python
import hashlib
import hmac
import struct

"""
P_hash(secret, seed) = 
HMAC_hash(secret, A(1) + seed) +
HMAC_hash(secret, A(2) + seed) +
HMAC_hash(secret, A(3) + seed) + ...

where + indicates concatenation.

A() is defined as:

A(0) = seed
A(i) = HMAC_hash(secret, A(i-1))
PRF(secret, label, seed) = P_<hash>(secret, label + seed)
"""
"""
# HKDF
def TLS_PRF( secret, label, seed, numbytes=48 ):
    PRK = hmac.new( secret, seed, hashlib.sha512 ).digest()

    out_prf = ''
    output_block = ''
    cur_bytes = 0
    counter = 0
    while cur_bytes < numbytes:
        output_block = hmac.new( PRK, output_block + label + struct.pack('I', counter ), hashlib.sha512 ).digest()
       
        out_prf += output_block

        cur_bytes += 64
        counter += 1

    return out_prf[:numbytes] 
"""

def TLS_PRF( secret, label, seed, numbytes=48 ):
    # The seed to use for P_hash(secret, seed) which is label + seed 
    concat_seed = label + seed

    A0 = concat_seed

    A1 = hmac.new( secret, A0, hashlib.sha512 ).digest()

    A_last = A1

    out_prf = ''

    cur_bytes = 0
    while cur_bytes < numbytes:
        out_prf += hmac.new( secret, A_last + concat_seed, hashlib.sha512 ).digest()

        A_last = hmac.new( secret, A_last, hashlib.sha512 ).digest()

        cur_bytes += 64

    return out_prf[:numbytes]
