$LOAD_PATH.unshift File.dirname(__FILE__) + '/..'

require 'lib/finite_field.rb'

# a class to represent elliptic curve
class EllipticCurve
    attr :a, :b, :p

    def to_s
        inspect
    end

    # return the string of the elliptic curve
    def inspect
        "y^2 = x^3 + #{@a.n}x + #{@b.n} mod #{@p}"
    end

    # initialize the elliptic curve
    def initialize(a, b, p)
        @a = FiniteField.new(a,p)
        @b = FiniteField.new(b,p)
        @p = p
    end

    # check if the point is on the curve
    def check_point?(x, y)
        return true if x == "infinity" && y == "infinity" 
        (y**2)  == (x**3 + @a*x + @b) 
    end

    # create the point on the curve
    def point(x,y)
        Point.new(self, FiniteField.new(x,@p), FiniteField.new(y,@p))
    end

    # a class to represent point on the elliptic curve
    class Point
        attr :x, :y, :elliptic_curve
    
        def to_s(degree=10)
            inspect(degree)
        end

        # return the string of the point
        def inspect(degree=10)
            if @x=="infinity" && @y=="infinity" 
                "(infinity)"
            else
                if degree == 10 then
                    "(#{@x.n}, #{@y.n})"
                elsif degree == 16 then
                    "(0x#{@x.n.to_s(degree)}, 0x#{@y.n.to_s(degree)})"
                end
            end
        end
    
        # initialize the point on the curve with x and y coordinate
        def initialize(elliptic_curve, x, y)
            @elliptic_curve = elliptic_curve
    
            @x = x 
            @y = y 
    
            raise "Point not on curve" unless @elliptic_curve.check_point?(@x, @y)
        end

        # check if the point equal to other point
        def ==(other)
            self.elliptic_curve.inspect == other.elliptic_curve.inspect && self.x == other.x && self.y == other.y
        end

        # multiply the point with number
        def *(n)
            result = Point.new(self.elliptic_curve, "infinity", "infinity")
            multi = self
            until n.zero?
                result = result + multi if n.odd?
                n >>= 1
                multi = multi + multi
            end
            result
        end

        # negate the point
        def -@
            Point.new(self.elliptic_curve, x, -y )
        end

        # minus the point with other point
        def -(obj)
            self + (-obj)
        end

        def coerce(other)
            return self, other
        end

        # add the point with other point
        def +(obj)
            if obj.is_a?(Point)
                if self.elliptic_curve.inspect == obj.elliptic_curve.inspect
                    # infinity is the identity element
                    return obj if (self.x == "infinity" && self.y == "infinity")
                    return self if (obj.x == "infinity" && obj.y == "infinity")

                    # calculate the slope
                    begin
                        if self.x == obj.x && self.y == obj.y
                            m = (3*self.x**2 + self.elliptic_curve.a) * (2*self.y).inverse
                        else
                            m = (self.y - obj.y) * (self.x - obj.x).inverse
                        end
                    rescue ZeroDivisionError
                        x3 = "infinity"
                        y3 = "infinity"
                    else
                        x3 = (m**2 - self.x - obj.x) 
                        y3 = (m*(self.x - x3) - self.y) 
                    end
    
    
                    Point.new(self.elliptic_curve, x3, y3)
                else
                    raise "Points not on the same curve"
                end
            else
                raise "Invalid type"
            end
        end
    
    end
end

if __FILE__ == $0

    e = EllipticCurve.new(5, 1, 23)
    p = e.point(9,4)
    q = e.point(4,4)
    
    puts "e = #{e}"               # e = y^2 = x^3 + 5x + 1 mod 23
    puts "p = #{p}"               # p = (9, 4)
    puts "-p = #{-p}"             # -p = (9, 19)
    puts "p-p = #{p-p}"           # p-p = (infinity)
    puts "inf+q = #{(p-p)+q}"     # (infinity)+q = (4, 4)
    puts "4*p = #{4*p}"           # 4*p = (12, 8)    
 

    e = EllipticCurve.new(5, 1, 23)
    p = e.point(9,4)
    q = e.point(4,4)
    
    puts "e = #{e}"               # e = y^2 = x^3 + 5x + 1 mod 23
    puts "p = #{p}"               # p = (9, 4)
    puts "-p = #{-p}"             # -p = (9, 19)
    puts "p-p = #{p-p}"           # p-p = (infinity)
    puts "q = #{q}"               # q = (4, 4)
    puts "inf+q = #{p-p+q}"       # inf+q = (4, 4)
    puts "p+p+p+p = #{p+p+p+p}"   # p+p+p+p = (12, 8)
    puts "4*p = #{4*p}"           # 4*p = (12, 8)    

    40.times do |i|
        puts "#{i+1} * q = #{q*(i+1)}"
    end
end