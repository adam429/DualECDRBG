require 'drb/drb'
require './elliptic_curve.rb'
require './config.rb'


class Cluster
    def initialize(nodes)
        DRb.start_service

        @nodes = nodes.map

        @server = nodes.map do |uri|
            DRbObject.new_with_uri(uri)
        end
    end

    def run_calc_multiplier_runner(p,q,range)
        raise "some node still running" unless all_idel?

        # range = range.each_slice(range.last/@server.size).with_index.with_object({}) { |(a,i),h|
        #     h[a.first..a.last]=i }.to_a.map {|x| x[0]}
        # puts "run_calc_multiplier_runner split range = #{range}"

        @server.zip(range).each do |server,r|
            server.run_calc_multiplier_runner(p,q,r)
        end
    end

    def run_calcState_runner(rand_output1,rand_output2,multiplier,rand,range)
        raise "some node still running" unless all_idel?

        # range = range.each_slice(range.last/@server.size).with_index.with_object({}) { |(a,i),h|
        #     h[a.first..a.last]=i }.to_a.map {|x| x[0]}
        # puts "run_calcState_runner split range = #{range}"

        @server.zip(range).each do |server,r|
            server.run_calcState_runner(rand_output1,rand_output2,multiplier,rand,r)
        end
    end


    def all_idel?
        status = @server.map do |server|
            server.get_status
        end
    
        puts status.inspect
        status.uniq == ['idle']
    end

    def wait_result
        loop do 
            break if all_idel?
            sleep(1)
        end
        
        result = @server.map do |server|
            server.get_result
        end     

        return result
    end
end

if __FILE__ == $0

    nodes = Cluster.new(Config::CLUSTER_NODES)

    e = EllipticCurve.new(Config::EC_A, Config::EC_B, Config::EC_P)
    q = e.point(Config::EC_GX, Config::EC_GY)
    p = 190000 * q

    nodes.run_calc_multiplier_runner(p,q,[1..96000,96001..192000])

    result = nodes.wait_result
    puts "result = #{result.inspect}"
end