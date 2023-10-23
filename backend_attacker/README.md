# Dual_EC_DRBG attack 

## Install Ruby Library

```
bundle install
```

## Configuration 

In Config.rb you can setup the parameters

EC_P / EC_A / EC_B / EC_GX / EC_GY use a secp256k1 elliptic curve

MULTIPLIER is p = multiplier * q, attacker need brute force to calc MULTIPLIER
TRUNCATE_NUMBER is how many bytes we hide in output, attacker need brute force to restore the point in elliptic curve

```ruby
  ## secp256k1
  EC_P = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f
  EC_A = 0
  EC_B = 7
  EC_GX = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798
  EC_GY = 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8

  ## Dual_EC_DRBG
  MULTIPLIER = 0x429     # p = multiplier * q
  TRUNCATE_NUMBER = 2   # means 2*4 = 8 bits
  SIZE_NUMBER = 64      # 64*4 = 256 bits
```

## Run Attack in multi thread

run attack script 

```
cd multi_thread
ruby attack_multi_thread.rb
```

attack output

```
------------------------------------------
--- calc_multiplier in p=multiplier*q ----
------------------------------------------
calc multiplier time: 2.49433
p=multiplier*q | multiplier= 0x4290
------------------
--- Calc State ---
------------------
rand.next = 0xdc8b2ed1b08251f36973639f905f94b9cd4a5317b45e062e454ad8ab06bfaf
rand.next = 0x4a58e5827b7a2f18f12ead6bcdf7a42ef3553fe1d6df2976728f1ba82f9a4e
calc state time: 5.973156
state = 0xa3101d0b8c889dd1e93c4faf78cc7999d8ada3757fd9809a8cd5d0b8d8b1cef4
-------------------------------------
--- Predict Next 10 Random Number ---
-------------------------------------
predict rand.next = 0x5eb83eeb2e21924c3333e410c8d3e8f2313f4d9992555d20395625bef15e11
predict rand.next = 0x93d99eb37788a62cf68f6ba6facf1d5fdc35a9f705cf5ff3cf42c6c4bcdfd7
predict rand.next = 0x10b9ac4167163d62e35ff1552469d2f7683904b0d29b39f95a74a1a39a8580
predict rand.next = 0xf4d7507beebc864f6b365d2b97efc28a09705bed4ca48ee5ccdd2fa1de498f
predict rand.next = 0x198f61a154a2ab9154df1219426f870df876d979e652b57df0bb3b91bc3b4f
predict rand.next = 0x92f6cc36271d7bda5260d060d8d4b077f367b417d2e78056b6e8c4c0d622d5
predict rand.next = 0x26650924cb650aee0e0e998de6bdd3837b87f72f0d5fb338010ea0f9e5df9d
predict rand.next = 0xb177aba9e734cd867274f7b1d8ce433b0cd04a89a53fb2bb5dae2de4d6a8f0
predict rand.next = 0x1735286688d809564a0a905f180f6f5378dc82936f970ccd922eef218e18fa
predict rand.next = 0x518f0b0f652d6c8ae735c6852e57fa998994308173ff6fc05b9f07208a135f
--------------------
actual rand.next = 0x5eb83eeb2e21924c3333e410c8d3e8f2313f4d9992555d20395625bef15e11
actual rand.next = 0x93d99eb37788a62cf68f6ba6facf1d5fdc35a9f705cf5ff3cf42c6c4bcdfd7
actual rand.next = 0x10b9ac4167163d62e35ff1552469d2f7683904b0d29b39f95a74a1a39a8580
actual rand.next = 0xf4d7507beebc864f6b365d2b97efc28a09705bed4ca48ee5ccdd2fa1de498f
actual rand.next = 0x198f61a154a2ab9154df1219426f870df876d979e652b57df0bb3b91bc3b4f
actual rand.next = 0x92f6cc36271d7bda5260d060d8d4b077f367b417d2e78056b6e8c4c0d622d5
actual rand.next = 0x26650924cb650aee0e0e998de6bdd3837b87f72f0d5fb338010ea0f9e5df9d
actual rand.next = 0xb177aba9e734cd867274f7b1d8ce433b0cd04a89a53fb2bb5dae2de4d6a8f0
actual rand.next = 0x1735286688d809564a0a905f180f6f5378dc82936f970ccd922eef218e18fa
actual rand.next = 0x518f0b0f652d6c8ae735c6852e57fa998994308173ff6fc05b9f07208a135f
```

## Run http server 

run http_server script

```
cd http_server
ruby http_server.rb
```

output listen on 8000 port
```
[2023-10-23 20:22:33] INFO  WEBrick 1.7.0
[2023-10-23 20:22:33] INFO  ruby 3.2.0 (2022-12-25) [x86_64-darwin21]
[2023-10-23 20:22:33] INFO  WEBrick::HTTPServer#start: pid=56693 port=8000
```

## Run distribute cluster

start a node
```
cd 3_distribute_attacker
ruby attacker_distribute_cluster_server.rb
```

change the config.rb, put the nodes ip address to config
```ruby
  ## cluster node
  CLUSTER_NODES = [
     "druby://18.141.58.4:80",
     "druby://18.136.105.15:80",
     "druby://52.221.216.113:80",
     "druby://13.229.113.15:80",
  ]
```

run the client
```
cd 3_distribute_attacker
ruby attacker_distribute_cluster_client.rb
```

## Library

### Finite Field

```ruby
    a=FiniteField.new(8,23)
    b=FiniteField.new(13,23)

    puts "a= #{a}"      # a= 8 mod 23
    puts "-a = #{-a}"   # -a = 15 mod 23
    puts "b = #{b}"     # b = 13 mod 23
    puts "-b = #{-b}"   # -b = 10 mod 23
    puts "a+b = #{a+b}" # a+b = 21 mod 23
    puts "a-b = #{a-b}" # a-b = 18 mod 23
    puts "a*b = #{a*b}" # a*b = 12 mod 23
    puts "a/b = #{a/b}" # a/b = 13 mod 23
    puts "a.inverse = #{a.inverse}" # a.inverse = 3 mod 23
    puts "b.inverse = #{b.inverse}" # b.inverse = 16 mod 23
    puts "a+1 = #{a+1}" # a+1 = 9 mod 23
    puts "1+a = #{1+a}" # 1+a = 9 mod 23
    puts "a-2 = #{a-2}" # a-2 = 6 mod 23
    puts "2-a = #{2-a}" # 2-a = 17 mod 23
    puts "a*3 = #{a*3}" # a*3 = 1 mod 23
    puts "3*a = #{3*a}" # 3*a = 1 mod 23
    puts "a/4 = #{a/4}" # a/4 = 2 mod 23
    puts "4/a = #{4/a}" # 4/a = 12 mod 23
    puts "a**-1 = #{a**-1}"   # a**-1 = 3 mod 23
    puts "2**a = #{2**a}"     # 2**a = 3 mod 23
    puts "a**2 = #{a**2}"     # a**2 = 18 mod 23
    puts "a**b = #{a**b}"     # a**b = 18 mod 23
    puts "a.sqrt = #{a.sqrt}" # a.sqrt = [13, 10]
    puts "b.sqrt = #{b.sqrt}" # b.sqrt = [6, 17]
```

### Elliptic Curve

```ruby
    e = EllipticCurve.new(5, 1, 23)
    p = e.point(9,4)
    q = e.point(4,4)
    
    puts "e = #{e}"               # e = y^2 = x^3 + 5x + 1 mod 23
    puts "p = #{p}"               # p = (9, 4)
    puts "-p = #{-p}"             # -p = (9, 19)
    puts "p-p = #{p-p}"           # p-p = (infinity)
    puts "q = #{q}"               # q = (4, 4)
    puts "inf+q = #{p-p+q}"       # inf+q = (4, 4)
    puts "p+p+p+p = #{p+p+p+p}"   # p+p+p+p = (12, 8)
    puts "4*p = #{4*p}"           # 4*p = (12, 8)   
```

### Dual_EC_DRBG

```ruby
    rand = DualECDRBG.new(12345)  # 12345 is seed
    rand.next   # random number 1
    rand.next   # random number 2
    rand.next   # random number 3
    rand.next   # random number 4
    rand.next   # random number 5
```
