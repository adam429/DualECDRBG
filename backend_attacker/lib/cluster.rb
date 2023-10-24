$LOAD_PATH.unshift File.dirname(__FILE__) + '/..'
require 'drb/drb'
require 'lib/elliptic_curve.rb'
require 'lib/config.rb'

# a class to run the calculation on the cluster
class Cluster

    # initialize the cluster
    def initialize(nodes)
        DRb.start_service

        @nodes = nodes.map

        @server = nodes.map do |uri|
            DRbObject.new_with_uri(uri)
        end
    end

    # run the calculation on the cluster
    def run_calc_multiplier_runner(p,q,range)
        raise "some node still running" unless all_idel?

        @server.zip(range).each do |server,r|
            server.run_calc_multiplier_runner(p,q,r)
        end
    end

    # run the calculation on the cluster
    def run_calcState_runner(rand_output1,rand_output2,multiplier,rand,range)
        raise "some node still running" unless all_idel?

        @server.zip(range).each do |server,r|
            server.run_calcState_runner(rand_output1,rand_output2,multiplier,rand,r)
        end
    end

    # reload the configuration on the cluster
    def reload_config()
        @server.each do |server|
            server.reload_config(Config::MULTIPLIER,Config::TRUNCATE_NUMBER)
        end
    end

    # check if all node is idle
    def all_idel?
        status = @server.map do |server|
            server.get_status
        end
    
        puts status.inspect
        status.uniq == ['idle']
    end

    # wait for the result, block the process if some node still running
    # inquire the result from each node, sleep 1 second between each inquire
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
en