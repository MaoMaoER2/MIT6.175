import Multiplexer::*;

// Full adder functions

function Bit#(1) fa_sum( Bit#(1) a, Bit#(1) b, Bit#(1) c_in );
    return xor1( xor1( a, b ), c_in );
endfunction

function Bit#(1) fa_carry( Bit#(1) a, Bit#(1) b, Bit#(1) c_in );
    return or1( and1( a, b ), and1( xor1( a, b ), c_in ) );
endfunction

// 4 Bit full adder

function Bit#(5) add4( Bit#(4) a, Bit#(4) b, Bit#(1) c_in );
    Bit#(4) sum;
    Bit#(5) c = 5'b0;           // need to initialise or it will get error message when make
    c[0] = c_in;
    for(Integer i =0 ; i< 4;i= i+1) begin
        sum[i] = fa_sum(a[i], b[i], c[i]);
        c[i+1] = fa_carry(a[i], b[i], c[i]);
    end

    return {c[4], sum};
endfunction

// Adder interface

interface Adder8;
    method ActionValue#( Bit#(9) ) sum( Bit#(8) a, Bit#(8) b, Bit#(1) c_in );
endinterface

// Adder modules

// RC = Ripple Carry
module mkRCAdder( Adder8 );
    method ActionValue#( Bit#(9) ) sum( Bit#(8) a, Bit#(8) b, Bit#(1) c_in );
        Bit#(5) lower_result = add4( a[3:0], b[3:0], c_in );
        Bit#(5) upper_result = add4( a[7:4], b[7:4], lower_result[4] );
        return { upper_result , lower_result[3:0] };
    endmethod
endmodule

// CS = Carry Select
module mkCSAdder( Adder8 );
    method ActionValue#( Bit#(9) ) sum( Bit#(8) a, Bit#(8) b, Bit#(1) c_in );
        Bit#(9) result = 9'b0;
        let high_4_bit_sum_carry1 = add4(a[7:4], b[7:4], 1);
        let high_4_bit_sum_carry0 = add4(a[7:4], b[7:4], 0);
        let low_4_bit_sum = add4(a[3:0], b[3:0], c_in);
        result[8] = multiplexer1(low_4_bit_sum[4], high_4_bit_sum_carry0[4], high_4_bit_sum_carry1[4]);
        result[7:4] = multiplexer_n(low_4_bit_sum[4], high_4_bit_sum_carry0[3:0], high_4_bit_sum_carry1[3:0]);
        result[3:0] = low_4_bit_sum[3:0];
        return result;
    endmethod
endmodule

