// Reference functions that use Bluespec's '*' operator
function Bit#(TAdd#(n,n)) multiply_unsigned( Bit#(n) a, Bit#(n) b );
    UInt#(n) a_uint = unpack(a);
    UInt#(n) b_uint = unpack(b);
    UInt#(TAdd#(n,n)) product_uint = zeroExtend(a_uint) * zeroExtend(b_uint);
    return pack( product_uint );
endfunction

function Bit#(TAdd#(n,n)) multiply_signed( Bit#(n) a, Bit#(n) b );
    Int#(n) a_int = unpack(a);
    Int#(n) b_int = unpack(b);
    Int#(TAdd#(n,n)) product_int = signExtend(a_int) * signExtend(b_int);
    return pack( product_int );
endfunction



// Multiplication by repeated addition
function Bit#(TAdd#(n,n)) multiply_by_adding( Bit#(n) a, Bit#(n) b );
    // TODO: Implement this function in Exercise 2
    let valn = valueOf(n);
    Bit#(n) product = 0;
    Bit#(n) tp = 0;
    for(Integer i=0; i<valn; i = i+1) begin
        Bit#(n) b_in = (a[i]==1'b1)?zeroExtend(b):0;
        Bit#(TAdd#(n,1)) sum = zeroExtend(tp) + zeroExtend(b_in);       //must have the extend to pass the compile, or there will be provisos needed
        product[i] = sum[0];
        tp = sum[valn:1];
    end
    return {tp, product};
endfunction



// Multiplier Interface
interface Multiplier#( numeric type n );
    method Bool start_ready();
    method Action start( Bit#(n) a, Bit#(n) b );
    method Bool result_ready();
    method ActionValue#(Bit#(TAdd#(n,n))) result();
endinterface



// Folded multiplier by repeated addition
module mkFoldedMultiplier( Multiplier#(n) );
    // You can use these registers or create your own if you want
    Reg#(Bit#(n)) a <- mkRegU();
    Reg#(Bit#(n)) b <- mkRegU();
    Reg#(Bit#(n)) prod <- mkRegU();
    Reg#(Bit#(n)) tp <- mkRegU();
    Reg#(Bit#(TAdd#(TLog#(n),1))) i <- mkReg( fromInteger(valueOf(n)+1) );

    rule mulStep(i < fromInteger(valueOf(n)+1));
        // TODO: Implement this in Exercise 4
        Bit#(TAdd#(n,1)) sum = 0;
        if(b[i]==1'b1) begin
            sum = zeroExtend(tp) + zeroExtend(a);
        end
        else begin
            sum = zeroExtend(tp);
        end
        prod[i] <= sum[0];
        tp <= sum[valueOf(n):1];
        i <= i+1;


    endrule

    method Bool start_ready();
        // TODO: Implement this in Exercise 4
        Bit#(TAdd#(TLog#(n),1)) flag_1 =  fromInteger(valueOf(n)+1);
        return (i == flag_1);
    endmethod

    method Action start( Bit#(n) aIn, Bit#(n) bIn );
        // TODO: Implement this in Exercise 4
        a <= aIn;
        b <= bIn;
        tp <= 0;
        prod <= 0;
        i <= 0;
    endmethod

    method Bool result_ready();
        // TODO: Implement this in Exercise 4
        Bit#(TAdd#(TLog#(n),1)) flag_2 =  fromInteger(valueOf(n));
        return (i == flag_2);
    endmethod

    method ActionValue#(Bit#(TAdd#(n,n))) result();
        // TODO: Implement this in Exercise 4
        return {tp, prod};
    endmethod
endmodule



// Booth Multiplier
module mkBoothMultiplier( Multiplier#(n) );
    Reg#(Bit#(TAdd#(TAdd#(n,n),1))) m_neg <- mkRegU;
    Reg#(Bit#(TAdd#(TAdd#(n,n),1))) m_pos <- mkRegU;
    Reg#(Bit#(TAdd#(TAdd#(n,n),1))) p <- mkRegU;
    Reg#(Bit#(TAdd#(TLog#(n),1))) i <- mkReg( fromInteger(valueOf(n)+1) );

    rule mul_step(i < fromInteger(valueOf(n)+1));
        // TODO: Implement this in Exercise 6
        let pr = p[1:0];
        Bit#(TAdd#(TAdd#(n,n),1)) tp = 0;
        if(pr == 2'b01) begin
            tp = p + m_pos;
        end
        else if(pr == 2'b10) begin
            tp = p + m_neg;
        end
        else if(pr == 2'b00 || pr == 2'b11) begin
            tp = p;
        end
        i <= i+1;
        Int#(TAdd#(TAdd#(n,n),1)) tp2 = unpack(tp);
        p <= pack((tp2>>1));
    endrule

    method Bool start_ready();
        // TODO: Implement this in Exercise 6
        Bit#(TAdd#(TLog#(n),1)) flag_1 =  fromInteger(valueOf(n)+1);
        return (i == flag_1);
    endmethod

    method Action start( Bit#(n) m, Bit#(n) r );
        // TODO: Implement this in Exercise 6
        Bit#(TAdd#(TAdd#(n,n),1)) m_pos_tp = signExtend(m);
        m_pos <= m_pos_tp << ((valueOf(n))+1);

        Bit#(TAdd#(TAdd#(n,n),1)) m_neg_tp = signExtend((~m+1));
        m_neg <= m_neg_tp << ((valueOf(n))+1);      //!!!!! ba careful to use left shif, if there is no specific left num it would return the original length which clean the original data
        p <= zeroExtend({r,1'b0});
        i <= 0;
    endmethod

    method Bool result_ready();
        // TODO: Implement this in Exercise 6
        Bit#(TAdd#(TLog#(n),1)) flag_2 =  fromInteger(valueOf(n));
        return (i == flag_2);
    endmethod

    method ActionValue#(Bit#(TAdd#(n,n))) result();
        // TODO: Implement this in Exercise 6
        return p[valueOf(TAdd#(n,n)):1];
    endmethod
endmodule



// Radix-4 Booth Multiplier

//  current bits    previous    original    radix-4
//          00          0           00          00
//          00          1           0+          0+
//          01          0           +-          0+
//          01          1           +0          +0
//          10          0           -0          -0
//          10          1           -+          0-
//          11          0           0-          0-
//          11          1           00          00

module mkBoothMultiplierRadix4( Multiplier#(n) );
    Reg#(Bit#(TAdd#(TAdd#(n,n),2))) m_neg <- mkRegU;
    Reg#(Bit#(TAdd#(TAdd#(n,n),2))) m_pos <- mkRegU;
    Reg#(Bit#(TAdd#(TAdd#(n,n),2))) p <- mkRegU;
    Reg#(Bit#(TAdd#(TLog#(n),1))) i <- mkReg( fromInteger(valueOf(n)/2+1) );

    rule mul_step (i < fromInteger(valueOf(n)/2+1)) ;
        // TODO: Implement this in Exercise 8
        let pr = p[2:0];
        Bit#(TAdd#(TAdd#(n,n),2)) tp = 0;
        case (pr)
            3'b000:begin
                tp = p;
            end
            3'b001:begin
                tp = p + m_pos;
            end
            3'b010:begin
                tp = p + m_pos;
            end
            3'b011:begin
                tp = p + m_pos<<1;
            end
            3'b100:begin
                tp = p + m_neg<<1;
            end
            3'b101:begin
                tp = p + m_neg;
            end
            3'b110:begin
                tp = p + m_neg;
            end
            3'b111:begin
                tp = p;
            end
        endcase
        i <= i+1;
        Int#(TAdd#(TAdd#(n,n),2)) tp2 = unpack(tp);
        Int#(TAdd#(TAdd#(n,n),2)) tp3 = tp2 >> 2;
        p <= pack(tp3);
    endrule

    method Bool start_ready();
        // TODO: Implement this in Exercise 8
        Bit#(TAdd#(TLog#(n),1)) flag_1 = fromInteger(valueOf(n)/2+1);
        return (flag_1 == i);
    endmethod

    method Action start( Bit#(n) m, Bit#(n) r );
        // TODO: Implement this in Exercise 8
        Bit#(TAdd#(TAdd#(n,n),2)) m_pos_tp = signExtend(m);
        m_pos <= m_pos_tp << ((valueOf(n))+1);

        Bit#(TAdd#(TAdd#(n,n),2)) m_neg_tp = signExtend((~m+1));
        m_neg <= m_neg_tp << ((valueOf(n))+1);      //!!!!! ba careful to use left shif, if there is no specific left num it would return the original length which clean the original data
        p <= zeroExtend({r,1'b0});
        i <= 0;
    endmethod

    method Bool result_ready();
        // TODO: Implement this in Exercise 8
        Bit#(TAdd#(TLog#(n),1)) flag_2 = fromInteger(valueOf(n)/2);
        return (flag_2 == i);
    endmethod

    method ActionValue#(Bit#(TAdd#(n,n))) result();
        // TODO: Implement this in Exercise 8
        Bit#(TAdd#(n,n)) res = 0;
        res = p[valueOf(TAdd#(n,n)):1];

        return res;
    endmethod
endmodule

