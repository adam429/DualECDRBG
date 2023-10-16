class FiniteField
    module ModularArithmetic
        module_function
      
        def gcd(x, y)
          gcdext(x, y).first
        end
        
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
        
        def invert(num, mod)
          g, a, b = gcdext(num, mod)
          unless g == 1
            raise ZeroDivisionError.new("#{num} has no inverse modulo #{mod}")
          end
          a % mod
        end
        
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

    class ReverseFiniteField < FiniteField
        def -(other)
            if other.is_a?(Integer)
                FiniteField.new((other - @n) % @p, @p)
            else
                raise "common modulus not found" if self.p != other.p 
                FiniteField.new((other.n - @n) % @p, @p)
            end
        end
    
        def /(other)
            if other.is_a?(Integer) 
                self.inverse * FiniteField.new(other,@p)
            else
                raise "common modulus not found" if self.p != other.p 
                self.inverse * other
            end
        end

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

    def inspect
        "#{@n} mod #{@p}"
    end

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

    def +(other)
        if other.is_a?(Integer)
            FiniteField.new((@n + other) % @p, @p)
        else
            raise "common modulus not found" if self.p != other.p 
            FiniteField.new((@n + other.n) % @p, @p)
        end
    end

    def -@
        FiniteField.new((@p-@n) % @p, @p)
    end

    def -(other)
        if other.is_a?(Integer)
            FiniteField.new((@n - other) % @p, @p)
        else
            raise "common modulus not found" if self.p != other.p 
            FiniteField.new((@n - other.n) % @p, @p)
        end
    end

    def *(other)
        if other.is_a?(Integer)
            FiniteField.new((@n * other) % @p, @p)
        else
            raise "common modulus not found" if self.p != other.p 
            FiniteField.new((@n * other.n) % @p, @p)
        end
    end

    def /(other)
        if other.is_a?(Integer) 
            FiniteField.new((@n * FiniteField.new(other,@p).inverse.n ) % @p, @p)
        else
            raise "common modulus not found" if self.p != other.p 
            FiniteField.new((@n * other.inverse.n) % @p, @p)
        end
    end

    def **(other)
        if other.is_a?(Integer) 
            FiniteField.new(ModularArithmetic.powmod(@n, other, @p) % @p, @p)
        else
            raise "common modulus not found" if self.p != other.p 
            FiniteField.new(ModularArithmetic.powmod(@n, other.n, @p) % @p, @p)
        end
    end

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

    def sqrt
        return tonelli(@n, @p), @p - tonelli(@n, @p)
    end

    def inverse
        FiniteField.new(ModularArithmetic.invert(@n, @p) % @p, @p)  
    end
end

if __FILE__ == $0
    a=FiniteField.new(8,23)
    b=FiniteField.new(13,23)

    puts "a= #{a}"
    puts "-a = #{-a}"
    puts "b = #{b}"
    puts "-b = #{-b}"
    puts "a+b = #{a+b}"
    puts "a-b = #{a-b}"
    puts "a*b = #{a*b}"
    puts "a/b = #{a/b}"
    puts "a.inverse = #{a.inverse}"
    puts "b.inverse = #{b.inverse}"
    puts "a+1 = #{a+1}"
    puts "1+a = #{1+a}"
    puts "a-2 = #{a-2}"
    puts "2-a = #{2-a}"
    puts "a*3 = #{a*3}"
    puts "3*a = #{3*a}"
    puts "a/4 = #{a/4}"
    puts "4/a = #{4/a}"
    puts "a**-1 = #{a**-1}"
    puts "2**a = #{2**a}"
    puts "a**2 = #{a**2}"
    puts "a**b = #{a**b}"
    puts "a.sqrt = #{a.sqrt}"
    puts "b.sqrt = #{b.sqrt}"
end