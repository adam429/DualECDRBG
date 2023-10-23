require 'parallel'
require 'drb'
require './dual_ec_drbg.rb'
require './cluster.rb'
require './config.rb'



# Brute force to find multiplier
def calc_multiplier(p,q)
    timestamp = Time.now

    batch = Config::NODE_MUL_BATCH_SIZE
    cluster = Config::CLUSTER_NODES.size
    current_k = 1

    loop do
        # generate task
        task = (0..cluster-1).map do |x|
            current_k+batch*x .. current_k+batch*x+(batch-1)
        end
        current_k = current_k + batch*cluster

        # run task
        # result = task.map do |range|
        #     puts "range: #{range.first} - #{range.last}"
        #     calc_multiplier_runner(p,q,range)
        # end.compact

        puts "task = #{task.inspect}"
        $nodes.run_calc_multiplier_runner(p,q,task)
        result = $nodes.wait_result.compact

        if result.size > 0 then
            puts "calc multiplier time: #{Time.now - timestamp}"
            return result.first
        end
    end
end    

def calc_multiplier_runner(p,q,range)
    timestamp = Time.now

    batch = Config::CALC_MUL_BATCH_SIZE
    process = Parallel.processor_count
    current_k = range.first

    while current_k <= range.last do
        # generate task
        task = (0..process-1).map do |x|
            current_k+batch*x .. current_k+batch*x+(batch-1)
        end
        current_k = current_k + batch*process

        # run task
        result = Parallel.map(task, in_processes: process) do |x| 
            k = x.first
            kq = k*q
            ret = nil
            x.each do 
                if p == kq then
                    ret = k
                    break 
                end
                kq = kq + q
                k+=1
            end 
            ret
        end.compact

        if result.size > 0 then
            return result.first
        end
    end
    return nil
end

# dual_ec_drbg emulate next() function
def to_number(point)  
    return point.x.n
end

def truncate(number)
    return number & Config::TRUNCATE_MASK
end

# brute force to find state
def calcState(rand_output1,rand_output2,multiplier,rand)

    batch = Config::NODE_STATE_BATCH_SIZE 
    cluster = Config::CLUSTER_NODES.size
    current_k = 0

    timestamp = Time.now

    while current_k<16**Config::TRUNCATE_NUMBER do
        # generate task
        task = (0..cluster-1).map do |x|
            current_k+batch*x .. current_k+batch*x+(batch-1)
        end
        current_k = current_k + batch*cluster

        # run task
        # result = task.map do |range|
        #     puts "range: #{range.first} - #{range.last}"
        #     calcState_runner(rand_output1,rand_output2,multiplier,rand,range)
        # end.compact
        puts "task = #{task.inspect}"
        $nodes.run_calcState_runner(rand_output1,rand_output2,multiplier,rand,task)
        result = $nodes.wait_result.compact


        if result.size > 0 then
            puts "calc state time: #{Time.now - timestamp}"
            return result.first
        end
    end
end

def calcState_runner(rand_output1,rand_output2,multiplier,rand,range)

    timestamp = Time.now

    batch = Config::CALC_STATE_BATCH_SIZE
    process = Parallel.processor_count
    current_k = range.first

    while current_k<=range.last do
        # generate task
        task = (0..process-1).map do |x|
            current_k+batch*x .. current_k+batch*x+(batch-1)
        end
        current_k = current_k + batch*process

        # run task
        result = Parallel.map(task, in_processes: process) do |range| 
            ret = nil
            range.each do |x|
                restore_x = (x << (Config::SIZE_NUMBER - Config::TRUNCATE_NUMBER)*4) + rand_output1

                begin
                    y = FiniteField.new((restore_x**3 + Config::EC_A*restore_x + Config::EC_B) % Config::EC_P,Config::EC_P).sqrt
                rescue RuntimeError
                    next
                end
                
                # step 2 - find point from x coordinate
                point = [
                    EllipticCurve.new(Config::EC_A,Config::EC_B,Config::EC_P).point(restore_x,y[0]),
                    # EllipticCurve.new(Config::EC_A,Config::EC_B,Config::EC_P).point(restore_x,y[1])
                ]
        
                # step 3 - calculate state
                states = [
                    to_number(point[0] * multiplier),
                    # to_number(point[1] * multiplier)
                ]

                state = states[0]
                # state = states[0] if states[0]==states[1] 
                # raise "states[0] != states[1]" if states[0]!=states[1]
        
                predict = truncate(to_number(rand.q * state))
                
                if predict == rand_output2
                    ret = state
                    break
                end
            end
            ret
        end.compact

        if result.size > 0 then
            return result.first
        end
    end
    return nil

end

# predict next random number
def predict_next(state,p,q)
    ec = EllipticCurve.new(Config::EC_A,Config::EC_B,Config::EC_P)

    new_state = to_number(state * p)

    output_point = new_state * q
    output = truncate(to_number(output_point))

    return new_state,output
end

if __FILE__ == $0
    $nodes = Cluster.new(Config::CLUSTER_NODES)
    $nodes.reload_config
    
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

end