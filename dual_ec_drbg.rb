require './elliptic_curve.rb'

class DualECDRBG
    attr :ec_p, :ec_a, :ec_b, :p, :q, :truncate_number, :state
    def initialize(seed)
        @state = seed

        # use secp256k1 elliptic curve
        @ec_p = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f
        @ec_a = 0
        @ec_b = 7
        @ec = EllipticCurve.new(ec_a, ec_b, ec_p)

        @q = @ec.point(0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798,
                       0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8)

        @p = 0x29 * @q
        @truncate_number = 2  # means 2*4 = 8 bits
    end

    def to_number(point)  
        return point.x.n
    end

    def truncate(number, truncate_number)
        mask = ("F" * (number.to_s(16).size-truncate_number)).to_i(16)

        output = number & mask
        
        return output
    end

    def next
        r = to_number(@state * @p)
        @state = to_number(r * @p)

        output_point = r * @q
        # puts "@state = #{ @state.to_s(16) }"
        # puts "output_point = #{output_point.to_s(16)}"
     
        output = truncate(to_number(output_point),@truncate_number)

        return output
    end
end

if __FILE__ == $0
    rand = DualECDRBG.new(12345)

    puts "rand.p = #{rand.p.to_s(16)}"
    puts "rand.q = #{rand.q.to_s(16)}"   

    puts "rand.next = #{rand.next.to_s(16)}"
    puts "rand.next = #{rand.next.to_s(16)}"
    puts "rand.next = #{rand.next.to_s(16)}"
    puts "rand.next = #{rand.next.to_s(16)}"
end