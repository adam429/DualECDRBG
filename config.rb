module Config 
  ## secp256k1
  EC_P = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f
  EC_A = 0
  EC_B = 7
  EC_GX = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
  EC_GY = 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8

  ## Dual_EC_DRBG
  MULTIPLIER = 0x429     # p = multiplier * q
  TRUNCATE_NUMBER = 2    # means 4*4 = 16 bits
  SIZE_NUMBER = 64      # 64*4 = 256 bits

  ## Pre-calculate mask
  TRUNCATE_MASK = 16**(SIZE_NUMBER-TRUNCATE_NUMBER)-1  # 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

  ## multi-thread
  CALC_MUL_BATCH_SIZE = 1000
  CALC_STATE_BATCH_SIZE = 16

  ## cluster node
  CLUSTER_NODES = [
     "druby://18.141.58.4:80",
     "druby://18.136.105.15:80",
     "druby://52.221.216.113:80",
     "druby://13.229.113.15:80",
  ]

  # CLUSTER_NODES = ["druby://localhost:80"]

  NODE_PROCESS = 96
  NODE_MUL_BATCH_SIZE = NODE_PROCESS * CALC_MUL_BATCH_SIZE
  NODE_STATE_BATCH_SIZE = NODE_PROCESS * CALC_STATE_BATCH_SIZE 
end