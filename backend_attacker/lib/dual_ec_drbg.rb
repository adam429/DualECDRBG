$LOAD_PATH.unshift File.dirname(__FILE__) + '/..'

require 'lib/elliptic_curve.rb'
require 'lib/config.rb'

# a class to run the Dual_EC_DRBG algorithm
class DualECDRBG
    attr_accessor :ec_p, :ec_a, :ec_b, :p, :q, :truncate_number, :state

    # initialize the Dual_EC_DRBG with seed
    def initialize(seed)
        @state = seed

        # use secp256k1 elliptic curve
        @ec_p = Config::EC_P
        @ec_a = Config::EC_A
        @ec_b = Config::EC_B
        @ec = EllipticCurve.new(ec_a, ec_b, ec_p)

        @q = @ec.point(Config::EC_GX, Config::EC_GY)

        @p = Config::MULTIPLIER * @q
    end

    # convert the point to number
    def to_number(point)  
        return point.x.n
    end

    # truncate the number
    def truncate(number)
        return number & Config::TRUNCATE_MASK
    end

    # generate the next random number
    def next
        @next_state = to_number(@state * @p)
        output = truncate(to_number(@next_state * @q))
        @state = @next_state
        return output
    end
end

if __FILE__ == $0
    rand = DualECDRBG.new(12345)

    puts "rand.p = #{rand.p.to_s(16)}" 
    puts "rand.q = #{rand.q.to_s(16)}"   


    rand = DualECDRBG.new(12345)

    puts "rand.next = #{rand.next.to_s(16)}"
    puts "rand.next = #{rand.next.to_s(16)}"
    puts "rand.next = #{rand.next.to_s(16)}"
    puts "rand.next = #{rand.next.to_s(16)}"
end

