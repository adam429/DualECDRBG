$LOAD_PATH.unshift File.dirname(__FILE__) + '/..'

require 'lib/dual_ec_drbg.rb'
require 'lib/config.rb'

# Brute force to find multiplier
def calc_multiplier(p,q)
    timestamp = Time.now

    kq = q

    k=1
    loop do 
        break if p == kq
        kq = kq + q
        k+=1
    end 

    puts "calc multiplier time: #{Time.now - timestamp}"

    return k
end    

# dual_ec_drbg emulate function
def to_number(point)  
    return point.x.n
end

# dual_ec_drbg emulate function
def truncate(number)
    return number & Config::TRUNCATE_MASK
end

# brute force to find state
def calcState(rand_output1,rand_output2,multiplier,rand)
    timestamp = Time.now

    # step 1 - untruncate
    (16**Config::TRUNCATE_NUMBER).times do |x|
        restore_x = (x << (Config::SIZE_NUMBER - Config::TRUNCATE_NUMBER)*4) + rand_output1


        begin
            y = FiniteField.new((restore_x**3 + Config::EC_A*restore_x + Config::EC_B) % Config::EC_P,Config::EC_P).sqrt
        rescue RuntimeError
            next
        end
        
        # step 2 - find point from x coordinate
        point = [
            EllipticCurve.new(Config::EC_A,Config::EC_B,Config::EC_P).point(restore_x,y[0]),
            EllipticCurve.new(Config::EC_A,Config::EC_B,Config::EC_P).point(restore_x,y[1])
        ]


        # step 3 - calculate state
        states = [
            to_number(point[0] * multiplier),
            to_number(point[1] * multiplier)
        ]
    
        state = states[0] if states[0]==states[1] 
        raise "states[0] != states[1]" if states[0]!=states[1]

        predict = truncate(to_number(rand.q * state))

        if predict == rand_output2
            puts "calc state time: #{Time.now - timestamp}"
            return state
        end
   
    end
end

# predict next random number
def predict_next(state,p,q)
    ec = EllipticCurve.new(Config::EC_A,Config::EC_B,Config::EC_P)

    new_state = to_number(state * p)

    output_point = new_state * q
    output = truncate(to_number(output_point))

    return new_state,output
end


rand = DualECDRBG.new(12345)


puts "rand.p = #{rand.p.to_s(16)}"
puts "rand.q = #{rand.q.to_s(16)}"   

puts "------------------------------------------"
puts "--- calc_multiplier in p=multiplier*q ----"
puts "------------------------------------------"

multiplier = calc_multiplier(rand.p,rand.q)
puts "p=multiplier*q | multiplier= 0x#{multiplier.to_s(16)}"

puts "------------------"
puts "--- Calc State ---"
puts "------------------"
rand_output1 = rand.next
rand_output2 = rand.next
puts "rand.next = 0x#{rand_output1.to_s(16)}"
puts "rand.next = 0x#{rand_output2.to_s(16)}"


state = calcState(rand_output1,rand_output2,multiplier,rand)
puts "state = 0x#{state.to_s(16)}"

puts "-------------------------------------"
puts "--- Predict Next 10 Random Number ---"
puts "-------------------------------------"

10.times do
    state, predict = predict_next(state,rand.p,rand.q)
    puts "predict rand.next = 0x#{predict.to_s(16)}"
end
puts "--------------------"

10.times do
    puts "actual rand.next = 0x#{rand.next.to_s(16)}"
end
