function Bit#(1) and1(Bit#(1) a, Bit#(1) b);
    return a & b;
endfunction

function Bit#(1) or1(Bit#(1) a, Bit#(1) b);
    return a | b;
endfunction

function Bit#(1) xor1( Bit#(1) a, Bit#(1) b );
    return a ^ b;
endfunction

function Bit#(1) not1(Bit#(1) a);
    return ~ a;
endfunction

function Bit#(1) multiplexer1(Bit#(1) sel, Bit#(1) a, Bit#(1) b);
    //return (sel == 0)? a : b;
    return or1(and1(not1(sel), a), and1(sel, b));
endfunction

function Bit#(5) multiplexer5(Bit#(1) sel, Bit#(5) a, Bit#(5) b);
    // Bit#(5) result;
    // for(Integer i=0; i<5; i= i+1) begin
    //     result[i] = multiplexer1(sel, a[i], b[i]);
    // end
    // return result;
    return multiplexer_n(sel, a, b);
endfunction

typedef 5 N;
function Bit#(N) multiplexerN(Bit#(1) sel, Bit#(N) a, Bit#(N) b);
    return (sel == 0)? a : b;
endfunction

//typedef 32 N; // Not needed
function Bit#(n) multiplexer_n(Bit#(1) sel, Bit#(n) a, Bit#(n) b);
    Bit#(n) result;
    let valn = valueOf(n);
    for(Integer i=0; i<valn; i= i+1) begin
        result[i] = multiplexer1(sel, a[i], b[i]);
    end
    return result;
endfunction
