require 'drb/drb'
require './elliptic_curve.rb'
require './config.rb'

# The URI to connect to
SERVER_URI="druby://18.141.58.4:80"

# Start a local DRbServer to handle callbacks.

# Not necessary for this small example, but will be required
# as soon as we pass a non-marshallable object as an argument
# to a dRuby call.

# Note: this must be called at least once per process to take any effect.
# This is particularly important if your application forks.
DRb.start_service

attackserver = DRbObject.new_with_uri(SERVER_URI)

e = EllipticCurve.new(Config::EC_A, Config::EC_B, Config::EC_P)
q = e.point(Config::EC_GX, Config::EC_GY)
p = 50000 * q



attackserver.run_calc_multiplier_runner(p,q,0..16000)

while attackserver.get_status == "busy" do
    sleep(1)
end

attackserver.run_calc_multiplier_runner(p,q,40000..56000)

while attackserver.get_status == "busy" do
    sleep(1)
end


puts "status = #{attackserver.get_status}"
puts "result = #{attackserver.get_result}"

