require './elliptic_curve.rb'
require './config.rb'

class DualECDRBG
    attr :ec_p, :ec_a, :ec_b, :p, :q, :truncate_number, :state
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

    def to_number(point)  
        return point.x.n
    end

    def truncate(number)
        return number & Config::TRUNCATE_MASK
    end

    def next
        r = to_number(@state * @p)
        @state = to_number(r * @p)
       
        return truncate(to_number(r * @q))
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

