module Config 
  ## secp256k1
  EC_P = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f
  EC_A = 0
  EC_B = 7
  EC_GX = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
  EC_GY = 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8

  ## Dual_EC_DRBG
  MULTIPLIER = 0x4290     # p = multiplier * q
  TRUNCATE_NUMBER = 2   # means 2*4 = 8 bits
  SIZE_NUMBER = 64      # 64*4 = 256 bits

  ## Pre-calculate mask
  TRUNCATE_MASK = 16**(SIZE_NUMBER-TRUNCATE_NUMBER)-1  # 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
end