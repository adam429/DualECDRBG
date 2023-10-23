require 'drb/drb'
require './attacker_distribute_cluster_client.rb'

# The URI for the server to connect to
URI="druby://0.0.0.0:80"

class AttackServer
    attr :status, :result

    def initialize
        @status = "idle"
    end

    def get_status
        @status
    end

    def get_result
        @result
    end

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

        # Config::MULTIPLIER = config::MULTIPLIER
        # Config::TRUNCATE_NUMBER = config::TRUNCATE_NUMBER
        # Config::TRUNCATE_MASK = 16**(Config::SIZE_NUMBER-Config::TRUNCATE_NUMBER)-1
        
        # eval "Config::MULTIPLIER = #{config::MULTIPLIER}"
        # eval "Config::TRUNCATE_NUMBER = #{config::TRUNCATE_NUMBER}"
        # eval "Config::TRUNCATE_MASK = 16**(Config::SIZE_NUMBER-Config::TRUNCATE_NUMBER)-1"

        puts "Config::MULTIPLIER = #{Config::MULTIPLIER}"
        puts "Config::TRUNCATE_NUMBER = #{Config::TRUNCATE_NUMBER}"
        puts "Config::TRUNCATE_MASK = #{Config::TRUNCATE_MASK}"
    end

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