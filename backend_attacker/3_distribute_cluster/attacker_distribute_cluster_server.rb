require 'drb/drb'
require './attacker_distribute_cluster_client.rb'

# The URI for the server to connect to
URI="druby://0.0.0.0:80"

# The object that handles requests on the node
class AttackServer
    attr :status, :result

    # initialize the node
    def initialize
        @status = "idle"
    end

    # return the status of the node
    def get_status
        @status
    end

    # return the result of the node
    def get_result
        @result
    end

    # reload the configuration on the node
    def reload_config(multiplier,truncate_number)
        ## Dual_EC_DRBG

        puts "multiplier = #{multiplier}"
        puts "truncate_number = #{truncate_number}"

        Config.send(:remove_const, :MULTIPLIER)
        Config.send(:remove_const, :TRUNCATE_NUMBER)
        Config.send(:remove_const, :TRUNCATE_MASK)

        Config.const_set(:MULTIPLIER, multiplier)
        Config.const_set(:TRUNCATE_NUMBER, truncate_number)
        Config.const_set(:TRUNCATE_MASK,16**(Config::SIZE_NUMBER-Config::TRUNCATE_NUMBER)-1)

        puts "Config::MULTIPLIER = #{Config::MULTIPLIER}"
        puts "Config::TRUNCATE_NUMBER = #{Config::TRUNCATE_NUMBER}"
        puts "Config::TRUNCATE_MASK = #{Config::TRUNCATE_MASK}"
    end

    # brute force to find multiplier, run the task on the node
    def run_calc_multiplier_runner(p,q,range)
        raise "the node is not idle" if @status != "idle"

        @status = "busy"
        @result = nil

        puts "run_calc_multiplier_runner #{range}"
        Thread.new do
            @result = calc_multiplier_runner(p,q,range)
            @status = "idle"
        end

    end

    # brute force to find state, run the task on the node
    def run_calcState_runner(rand_output1,rand_output2,multiplier,rand,range)
        raise "the node is not idle" if @status != "idle"

        @status = "busy"
        @result = nil

        puts "run_calc_state_runner #{range}"
        Thread.new do
            @result = calcState_runner(rand_output1,rand_output2,multiplier,rand,range)
            @status = "idle"
        end
    end

end

if __FILE__ == $0
    # The object that handles requests on the server
    FRONT_OBJECT=AttackServer.new

    DRb.start_service(URI, FRONT_OBJECT)
    # Wait for the drb server thread to finish before exiting.
    DRb.thread.join
end