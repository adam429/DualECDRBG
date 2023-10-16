require './dual_ec_drbg.rb'

def calcD(p,q)
    timestamp = Time.now

    k=1
    loop do 
        break if p == k*q
        k+=1
    end 

    puts "calc d time: #{Time.now - timestamp}"

    return k
end    

def to_number(point)  
    return point.x.n
end

def truncate(number, truncate_number)
    mask = ("F" * (number.to_s(16).size-truncate_number)).to_i(16)
    
    return number & mask
end


def calcState(rand_output1,rand_output2,d,n,a,b,p,q,truncate_number)
    timestamp = Time.now

    # step 1 - untruncate
    (16**truncate_number).times do |x|
        restore_x = (x.to_s(16) + rand_output1.to_s(16)).to_i(16)

        begin
            y = FiniteField.new((restore_x**3 + a*restore_x + b) % n,n).sqrt
        rescue RuntimeError
            next
        end
        
        # step 2 - find point from x coordinate
        point = [
            EllipticCurve.new(a,b,n).point(restore_x,y[0]),
            EllipticCurve.new(a,b,n).point(restore_x,y[1])
        ]

        # step 3 - calculate state
        states = [
            to_number(point[0] * d),
            to_number(point[1] * d)
        ]
    
        state = states[0] if states[0]==states[1] 
        raise "states[0] != states[1]" if states[0]!=states[1]

        state, predict = predict_next(state,a,b,n,p,q,truncate_number)

        if predict == rand_output2
            # puts "x = #{x}"
            # puts "point[0] = #{point[0]}"
            # puts "point[1] = #{point[1]}"
            # puts "state = #{state}"
            puts "time: #{Time.now - timestamp}"
            return state
        end
   
    end
end

def predict_next(state,a,b,n,p,q,truncate_number)
    ec = EllipticCurve.new(a,b,n)

    r = to_number(state * p)
    new_state = to_number(r * p)

    output_point = r * q
    output = truncate(to_number(output_point),truncate_number)

    return new_state,output
end

rand = DualECDRBG.new(12345)


puts "rand.p = #{rand.p.to_s(16)}"
puts "rand.q = #{rand.q.to_s(16)}"   

puts "------------------------"
puts "--- Calc d in p=d*q ----"
puts "------------------------"

d = calcD(rand.p,rand.q)
puts "p=d*q | d= 0x#{d.to_s(16)}"

puts "------------------"
puts "--- Calc State ---"
puts "------------------"
rand_output1 = rand.next
rand_output2 = rand.next
puts "rand.next = 0x#{rand_output1.to_s(16)}"
puts "rand.next = 0x#{rand_output2.to_s(16)}"

state = calcState(rand_output1,rand_output2,d,rand.ec_p,rand.ec_a,rand.ec_b,rand.p,rand.q,rand.truncate_number)
puts "state = 0x#{state.to_s(16)}"

puts "--------------------"
puts "--- Predict Next ---"
puts "--------------------"

10.times do
    state, predict = predict_next(state,rand.ec_a,rand.ec_b,rand.ec_p,rand.p,rand.q,rand.truncate_number)
    puts "predict rand.next = 0x#{predict.to_s(16)}"
end
puts "--------------------"

10.times do
    puts "actual rand.next = 0x#{rand.next.to_s(16)}"
end
