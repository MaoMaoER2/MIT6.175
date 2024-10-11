import Ehr::*;
import Vector::*;

interface Fifo#(numeric type n, type t);
    method Bool notFull;
    method Action enq(t x);
    method Bool notEmpty;
    method Action deq;
    method t first;
endinterface

// Two element conflict-free fifo from lecture
module mkCFFifo( Fifo#(2, t) ) provisos (Bits#(t, tSz));
    Ehr#(2, t) da <- mkEhr(?);
    Ehr#(2, Bool) va <- mkEhr(False);
    Ehr#(2, t) db <- mkEhr(?);
    Ehr#(2, Bool) vb <- mkEhr(False);

    rule canonicalize ( vb[1] && !va[1] ) ;
        
        da[1] <= db[1];
        va[1] <= True;
        vb[1] <= False;
    
    endrule

    method Bool notFull();
        return !vb[0];
    endmethod

    method Bool notEmpty();
        return va[0];
    endmethod

    method Action enq(t x) if(!vb[0]);
        db[0] <= x;
        vb[0] <= True;
    endmethod

    method Action deq if(va[0]);
        va[0] <= False;
    endmethod

    method t first if(va[0]);
        return da[0];
    endmethod
endmodule

// Three element conflict-free fifo from lecture
//  vc  vb  va
//  dc  db  da
module mkCFFifo_3( Fifo#(3, t) ) provisos (Bits#(t, tSz));
    Ehr#(2, t) da <- mkEhr(?);
    Ehr#(2, Bool) va <- mkEhr(False);
    Ehr#(2, t) db <- mkEhr(?);
    Ehr#(2, Bool) vb <- mkEhr(False);
    Ehr#(2, t) dc <- mkEhr(?);
    Ehr#(2, Bool) vc <- mkEhr(False);

    rule canonicalize( (vb[1] || vc[1]) && !va[1] );
            da[1] <= db[1];
            db[1] <= dc[1];
            va[1] <= vb[1];
            vb[1] <= vc[1];
            vc[1] <= False;
        
    endrule

    method Bool notFull();
        return !vc[0];
    endmethod

    method Bool notEmpty();
        return va[0]||vb[0];
    endmethod

    method Action enq(t x) if(!vc[0]);
        dc[0] <= x;
        vc[0] <= True;
    endmethod

    method Action deq if(va[0] || vb[0]);
        if(va[0]==True)
        begin
            va[0] <= False;
        end
        else if(vb[0] == True) begin
            vb[0] <= False;
        end
    endmethod

    method t first if(va[0] || vb[0]);
        if(va[0]==True)
        begin
            return da[0];
        end
        else begin
            return db[0];
        end
    endmethod
endmodule