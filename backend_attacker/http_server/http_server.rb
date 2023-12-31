## This file is used to create a http server to receive the input from frontend and return the result to frontend

# run:
#    ruby http_server.rb

$LOAD_PATH.unshift File.dirname(__FILE__) + '/..'

require 'webrick'
require 'json'
require 'multi_thread/attacker_multi_thread.rb'


server = WEBrick::HTTPServer.new(:Port => 8000, :DocumentRoot => '../../frontend_client/dist')

server.mount_proc '/attack' do |req, res|

    # POST request
    if req.request_method == 'POST' then

        # parse the input
        inp = JSON.parse(req.body.gsub(/\n/,''))

        puts "input: #{inp}"

        puts "------------------------------------------"
        puts "--- calc_multiplier in p=multiplier*q ----"
        puts "------------------------------------------"

        e = EllipticCurve.new(Config::EC_A,Config::EC_B,Config::EC_P)

        p = e.point(inp["px"].to_i(16),inp["py"].to_i(16))
        q = e.point(inp["qx"].to_i(16),inp["qy"].to_i(16))


        rand = DualECDRBG.new(12345)
        rand.p = p
        rand.q = q

        puts "p = #{p}"
        puts "q = #{q}"


        # brute force to find multiplier
        multiplier = calc_multiplier(p,q)
        puts "p=multiplier*q | multiplier= 0x#{multiplier.to_s(16)}"
    
        puts "------------------"
        puts "--- Calc State ---"
        puts "------------------"
        rand_output1 = inp["rand1"].to_i(16)
        rand_output2 = inp["rand2"].to_i(16)
        puts "rand.next = 0x#{rand_output1.to_s(16)}"
        puts "rand.next = 0x#{rand_output2.to_s(16)}"
    

        # brute force to find state
        state = calcState(rand_output1,rand_output2,multiplier,rand)

        puts "state = #{state.to_s}"

        puts "state = 0x#{state.to_s(16)}"
    
        puts "-------------------------------------"
        puts "--- Predict Next 10 Random Number ---"
        puts "-------------------------------------"
    
        result = 10.times.map do
            state, predict = predict_next(state,rand.p,rand.q)
            puts "predict rand.next = 0x#{predict.to_s(16)}"
            predict.to_s(16)
        end
        puts "--------------------"
    
        # return the result in json format
        res.body = {"status":200, "result":result}.to_json            
    end

end

server.start

trap('INT') { server.shutdown }


# ruby http_server.rb >/dev/null 2>&1 &