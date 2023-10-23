# a class for finite field arithmetic
class FiniteField
    
    # a module for modular arithmetic
    module ModularArithmetic
        module_function
      
        # return the greatest common divisor of x and y
        def gcd(x, y)
          gcdext(x, y).first
        end
        
        # return the ext greatest common divisor of x and y
        def gcdext(x, y)
          if x < 0
            g, a, b = gcdext(-x, y)
            return [g, -a, b]
          end
          if y < 0
            g, a, b = gcdext(x, -y)
            return [g, a, -b]
          end
          r0, r1 = x, y
          a0 = b1 = 1
          a1 = b0 = 0
          until r1.zero?
            q = r0 / r1
            r0, r1 = r1, r0 - q*r1
            a0, a1 = a1, a0 - q*a1
            b0, b1 = b1, b0 - q*b1
          end
          [r0, a0, b0]
        end
        
        # return the inverse of num modulo mod
        def invert(num, mod)
          g, a, b = gcdext(num, mod)
          unless g == 1
            raise ZeroDivisionError.new("#{num} has no inverse modulo #{mod}")
          end
          a % mod
        end
        
        # return the power of base to exp modulo mod
        def powmod(base, exp, mod)
          if exp < 0
            base = invert(base, mod)
            exp = -exp
          end
          result = 1
          multi = base % mod
          until exp.zero?
            result = (result * multi) % mod if exp.odd?
            exp >>= 1
            multi = (multi * multi) % mod
          end
          result
        end
    end

    # class for reverse operation
    class ReverseFiniteField < FiniteField
        # minus number with other number
        def -(other)
            if other.is_a?(Integer)
                FiniteField.new((other - @n) % @p, @p)
            else
                raise "common modulus not found" if self.p != other.p 
                FiniteField.new((other.n - @n) % @p, @p)
            end
        end
    
        # divide number with other number
        def /(other)
            if other.is_a?(Integer) 
                self.inverse * FiniteField.new(other,@p)
            else
                raise "common modulus not found" if self.p != other.p 
                self.inverse * other
            end
        end

        # power number with other number
        def **(other)
            if other.is_a?(Integer) 
                FiniteField.new(ModularArithmetic.powmod(other, @n, @p) % @p, @p)
            else
                raise "common modulus not found" if self.p != other.p 
                FiniteField.new(ModularArithmetic.powmod(other.n, @n, @p) % @p, @p)
            end
        end
    end
    
    attr :p,:n

    def to_s
        inspect
    end

    # return the string of the number
    def inspect
        "#{@n} mod #{@p}"
    end

    # initialize the number with value and modulus
    def initialize(n,p)
        if n.is_a?(FiniteField) 
            @p = p
            @n = n.n
        else
            @p = p
            @n = n
        end
    end

    def coerce(other)
        return ReverseFiniteField.new(@n,@p), other
    end

    # add number with other number
    def +(other)
        if other.is_a?(Integer)
            FiniteField.new((@n + other) % @p, @p)
        else
            raise "common modulus not found" if self.p != other.p 
            FiniteField.new((@n + other.n) % @p, @p)
        end
    end

    # negate number
    def -@
        FiniteField.new((@p-@n) % @p, @p)
    end

    # minus number with other number
    def -(other)
        if other.is_a?(Integer)
            FiniteField.new((@n - other) % @p, @p)
        else
            raise "common modulus not found" if self.p != other.p 
            FiniteField.new((@n - other.n) % @p, @p)
        end
    end

    # multiply number with other number
    def *(other)
        if other.is_a?(Integer)
            FiniteField.new((@n * other) % @p, @p)
        else
            raise "common modulus not found" if self.p != other.p 
            FiniteField.new((@n * other.n) % @p, @p)
        end
    end

    # divide number with other number
    def /(other)
        if other.is_a?(Integer) 
            FiniteField.new((@n * FiniteField.new(other,@p).inverse.n ) % @p, @p)
        else
            raise "common modulus not found" if self.p != other.p 
            FiniteField.new((@n * other.inverse.n) % @p, @p)
        end
    end

    # power number with other number
    def **(other)
        if other.is_a?(Integer) 
            FiniteField.new(ModularArithmetic.powmod(@n, other, @p) % @p, @p)
        else
            raise "common modulus not found" if self.p != other.p 
            FiniteField.new(ModularArithmetic.powmod(@n, other.n, @p) % @p, @p)
        end
    end

    # check if the number equal to other number
    def ==(other)
        if other.is_a?(FiniteField)
            if other.p == @p and other.n == @n
                true
            else
                false
            end
        else
            false
        end
    end

    def legendre(a, p)
        return a.pow((p - 1) / 2, p)
    end

    # return the square root of the number (mod p)    
    def tonelli(n, p)
        raise "not a square (mod p)" if legendre(n, p) != 1
        q = p - 1
        s = 0
        while q % 2 == 0
            q /= 2
            s += 1
        end
        if s == 1
            return n.pow((p + 1) / 4, p)
        end
        z = 2
        while p - 1 != legendre(z, p)
            z += 1
        end
        c = z.pow(q, p)
        r = n.pow((q + 1) / 2, p)
        t = n.pow(q, p)
        m = s
        t2 = 0
        while (t - 1) % p != 0
            t2 = (t * t) % p
            i = 1
            while i < m
                break if (t2 - 1) % p == 0
                t2 = (t2 * t2) % p
                i += 1
            end
            b = c.pow(1 << (m - i - 1), p)
            r = (r * b) % p
            c = (b * b) % p
            t = (t * c) % p
            m = i
        end
        return r
    end

    # return the square root of the number (mod p)
    def sqrt
        return tonelli(@n, @p), @p - tonelli(@n, @p)
    end

    # return the inverse of the number (mod p)
    def inverse
        FiniteField.new(ModularArithmetic.invert(@n, @p) % @p, @p)  
    end
end

if __FILE__ == $0
    a=FiniteField.new(8,23)
    b=FiniteField.new(13,23)

    puts "a= #{a}"      # a= 8 mod 23
    puts "-a = #{-a}"   # -a = 15 mod 23
    puts "a+b = #{a+b}" # a+b = 21 mod 23
    puts "a-b = #{a-b}" # a-b = 18 mod 23
    puts "a*b = #{a*b}" # a*b = 12 mod 23
    puts "a/b = #{a/b}" # a/b = 13 mod 23
    puts "a.inverse = #{a.inverse}" # a.inverse = 3 mod 23
    puts "a**-1 = #{a**-1}"   # a**-1 = 3 mod 23
    puts "a**2 = #{a**2}"     # a**2 = 18 mod 23
    puts "a.sqrt = #{a.sqrt}" # a.sqrt = [13, 10]


    puts "a= #{a}"      # a= 8 mod 23
    puts "-a = #{-a}"   # -a = 15 mod 23
    puts "b = #{b}"     # b = 13 mod 23
    puts "-b = #{-b}"   # -b = 10 mod 23
    puts "a+b = #{a+b}" # a+b = 21 mod 23
    puts "a-b = #{a-b}" # a-b = 18 mod 23
    puts "a*b = #{a*b}" # a*b = 12 mod 23
    puts "a/b = #{a/b}" # a/b = 13 mod 23
    puts "a.inverse = #{a.inverse}" # a.inverse = 3 mod 23
    puts "b.inverse = #{b.inverse}" # b.inverse = 16 mod 23
    puts "a+1 = #{a+1}" # a+1 = 9 mod 23
    puts "1+a = #{1+a}" # 1+a = 9 mod 23
    puts "a-2 = #{a-2}" # a-2 = 6 mod 23
    puts "2-a = #{2-a}" # 2-a = 17 mod 23
    puts "a*3 = #{a*3}" # a*3 = 1 mod 23
    puts "3*a = #{3*a}" # 3*a = 1 mod 23
    puts "a/4 = #{a/4}" # a/4 = 2 mod 23
    puts "4/a = #{4/a}" # 4/a = 12 mod 23
    puts "a**-1 = #{a**-1}"   # a**-1 = 3 mod 23
    puts "2**a = #{2**a}"     # 2**a = 3 mod 23
    puts "a**2 = #{a**2}"     # a**2 = 18 mod 23
    puts "a**b = #{a**b}"     # a**b = 18 mod 23
    puts "a.sqrt = #{a.sqrt}" # a.sqrt = [13, 10]
    puts "b.sqrt = #{b.sqrt}" # b.sqrt = [6, 17]
end






