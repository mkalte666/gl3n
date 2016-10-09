/**
gl3n.ext.simd

Authors: Malte Kießling
Licence: MIT 

*/

module gl3n.ext.simd;

private {
    import core.cpuid : sse, sse2, sse3, sse41, sse42;
    import core.simd;
    import std.traits : isFloatingPoint;
}


version(D_SIMD) {
    public enum simdAvailable = true; /// Holds if SIMD is available at compile time
} else {
    public enum simdAvailable = false; ///
}

/// Returns the next size >= d that both can hold d and 
/// can be used as size argument for simd vectors
template nearestSimdDimension(int d)
{
    int dim;
    static if(d <= 2) {
        const int nearestSimdDimension = 2;
    } else static if(d <= 4) {
        const int nearestSimdDimension = 4;
    } else static if(d <= 8) {
        const int nearestSimdDimension = 8;
    } else static if(d <= 16) {
        const int nearestSimdDimension = 16;
    }
    else {
        static assert(0,"Cannot get nearest simd vector dimension for input");
    }
}


static if(simdAvailable) {
    /// Holds helper functions for simd instructions and fallbacks
    template SIMD(T,int n) {
        alias vecTyp = Vector!(T[n]);
    static public pure @safe nothrow{
    pragma(inline) {
        
        static const bool hasAssign = true; /// Holds if acelerated assignment is available
        static const bool hasAddSto = !is(T==void)||n!=16; /// Holds if a+=b is available
        static const bool hasSubSto = hasAddSto; /// Holds if a-=b is available
        static const bool hasAdd = hasAddSto; /// Holds if c=a+b is available
        static const bool hasSub = hasAddSto; /// Holds if c=a-b is avaiable
        static const bool hasMagnitudeSquared = isFloatingPoint!T && n <= 4; /// Holds if |a|^2 is availabe 
        static const bool hasMagnitude = hasMagnitudeSquared; /// Holds if |a| is available
 
        /// Assings two vectors. Always available
        void assign(vecTyp a, vecTyp b) {
            a=b;
        }

        static if(hasAdd) {
            /// c = a+b
            vecTyp add (vecTyp a, vecTyp b) {
                return a+b;
            }
        }
        static if(hasAddSto) {
            /// a+=b
            void addSto(vecTyp a, vecTyp b) {
                a+=b;
            }
        }
        static if(hasSub) {
            /// c = a-b
            vecTyp sub(vecTyp a, vecTyp b) {
                return a-b;
            }
        }
        static if(hasSubSto) {
            /// a-=b
            void subSto(vecTyp a, vecTyp b) {
                a-=b;
            }
        } 
        
        static if(hasMagnitudeSquared) { 
            /// flag for vecor-size fullfilling dot product
            static const ubyte imm8_dpFull = (1<<0)|(1<<4) | 
                    (n>=2) ? (1<<5) : 0 |
                    (n>=3) ? (1<<6) : 0 |
                    (n>=4) ? (1<<7) : 0;
            /// |a|^2
            real magnitude_squared(vecTyp a) {
                if (sse41()) {
                    static if(is(T==float)) {
                        vecTyp r = __simd(XMM.DPPS,a,a,imm8_dpFull);
                        return r.array[0];
                    }
                }
                
                // "leagacy" implementation
                vecTyp b = a*a;
                for(int i = 1; i < n; i++) {
                    b.array[0] += b.array[i];
                }

                return b.array[0];
            }
        }

        static if(hasMagnitude) {
            /// |a|
            real magnitude(vecTyp a) {
                if (sse41()) {
                    static if(is(T==float)) {
                        vecTyp r = __simd(XMM.DPPS,a,a,imm8_dpFull);
                        r = __simd(XMM.SQRTSS,r);
                        return r.array[0];  
                    }
                }

                // meh?
                vecTyp b = a*a;
                for(int i = 1; i < n; i++) {
                    b.array[0]+= b.array[i];
                } 
                b = __simd(XMM.SQRTSS,b);
                return b.array[0];
            }
        }   
    }    
    }
    }
}

