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
"""
def HKDF_HMAC_SHA512( secret, info, numbytes=48 ):
    T0 = ""
    T_last = T0

    out_prf = ''
    cur_bytes = 0
    ctr = 1
    while cur_bytes < numbytes:
        T_next = hmac.new( secret, T_last + info + struct.pack('<H', ctr), hashlib.sha512 ).digest()

        out_prf += T_next

        T_last = T_next

        cur_bytes += 64
        ctr += 1

    return out_prf[:numbytes]
