import Ehr::*;
import Vector::*;

//////////////////
// Fifo interface 

interface Fifo#(numeric type n, type t);
    method Bool notFull;
    method Action enq(t x);
    method Bool notEmpty;
    method Action deq;
    method t first;
    method Action clear;
endinterface

/////////////////
// Conflict FIFO

module mkMyConflictFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
    // n is size of fifo
    // t is data type of fifo
    Vector#(n, Reg#(t))     data     <- replicateM(mkRegU());
    Reg#(Bit#(TLog#(n)))    enqP     <- mkReg(0);
    Reg#(Bit#(TLog#(n)))    deqP     <- mkReg(0);
    Reg#(Bool)              empty    <- mkReg(True);
    Reg#(Bool)              full     <- mkReg(False);

    // useful value
    Bit#(TLog#(n))          max_index = fromInteger(valueOf(n)-1);

    // TODO: Implement all the methods for this module

    method Bool notFull();
        return !full;
    endmethod

    method Action enq(t x) if(!full);
        let flag = enqP;
        if(flag < max_index) begin
            enqP <= enqP + 1;
            flag = enqP + 1;
        end
        else begin
            enqP <= 0;
            flag = 0;
        end
        data[enqP] <= x;
        empty <= False;
        if(deqP==flag) begin
            full <= True;
        end
    endmethod

    method Bool notEmpty;
        return !empty;
    endmethod

    method Action deq if(!empty);
        let flag = deqP;

        if(deqP < max_index) begin
            deqP <= deqP + 1;
            flag = deqP + 1;
        end
        else begin
            deqP <= 0;
            flag = 0;
        end
        
        full <= False;
        if(enqP==flag) begin
            empty <= True;
        end

    endmethod

    method t first if(!empty);
        return data[deqP];
    endmethod

    method Action clear;
        enqP <= 0;
        deqP <= 0;
        full <= False;
        empty <= True;
    endmethod


endmodule

/////////////////
// Pipeline FIFO

// Intended schedule:
//      {notEmpty, first, deq} < {notFull, enq} < clear
module mkMyPipelineFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
    // n is size of fifo
    // t is data type of fifo
    Vector#(n, Ehr#(2,t))     data     <- replicateM(mkEhr(?));
    Reg#(Bit#(TLog#(n)))    enqP     <- mkReg(0);
    Reg#(Bit#(TLog#(n)))    deqP     <- mkReg(0);
    Ehr#(3,Bool)              empty    <- mkEhr(True);
    Ehr#(3,Bool)              full     <- mkEhr(False);

    // useful value
    Bit#(TLog#(n))          max_index = fromInteger(valueOf(n)-1);


    method Bool notFull();
        return !full[1];
    endmethod

    method Action enq(t x) if(!full[1]);
        let flag = enqP;
        if(flag < max_index) begin
            enqP <= enqP + 1;
            flag = enqP + 1;
        end
        else begin
            enqP <= 0;
            flag = 0;
        end
        data[enqP][1] <= x;
        empty[1] <= False;
        if(deqP==flag) begin
            full[1] <= True;
        end
    endmethod

    method Bool notEmpty;
        return !empty[0];
    endmethod

    method Action deq if(!empty[0]);
        let flag = deqP;

        if(deqP < max_index) begin
            deqP <= deqP + 1;
            flag = deqP + 1;
        end
        else begin
            deqP <= 0;
            flag = 0;
        end
        
        full[0] <= False;
        if(enqP==flag) begin
            empty[0] <= True;
        end

    endmethod

    method t first if(!empty[0]);
        return data[deqP][0];
    endmethod

    method Action clear;
        enqP <= 0;
        deqP <= 0;
        full[2] <= False;
        empty[2] <= True;
    endmethod



endmodule

/////////////////////////////
// Bypass FIFO without clear

// Intended schedule:
//      {notFull, enq} < {notEmpty, first, deq} < clear
// my opinion: in this case, the bypass fifo in fact keep writing in new data and the old data are replaced
module mkMyBypassFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
    // n is size of fifo
    // t is data type of fifo
    Vector#(n, Ehr#(2,t))     data     <- replicateM(mkEhr(?));
    Reg#(Bit#(TLog#(n)))    enqP     <- mkReg(0);
    Reg#(Bit#(TLog#(n)))    deqP     <- mkReg(0);
    Ehr#(3,Bool)              empty    <- mkEhr(True);
    Ehr#(3,Bool)              full     <- mkEhr(False);

    // useful value
    Bit#(TLog#(n))          max_index = fromInteger(valueOf(n)-1);


    method Bool notFull();
        return !full[0];
    endmethod

    method Action enq(t x) if(!full[0]);
        let flag = enqP;
        if(flag < max_index) begin
            enqP <= enqP + 1;
            flag = enqP + 1;
        end
        else begin
            enqP <= 0;
            flag = 0;
        end
        data[enqP][0] <= x;
        empty[0] <= False;
        if(deqP==flag) begin
            full[0] <= True;
        end
    endmethod

    method Bool notEmpty;
        return !empty[1];
    endmethod

    method Action deq if(!empty[1]);
        let flag = deqP;

        if(deqP < max_index) begin
            deqP <= deqP + 1;
            flag = deqP + 1;
        end
        else begin
            deqP <= 0;
            flag = 0;
        end
        
        full[1] <= False;
        if(enqP==flag) begin
            empty[1] <= True;
        end

    endmethod

    method t first if(!empty[1]);
        return data[deqP][1];
    endmethod

    method Action clear;
        enqP <= 0;
        deqP <= 0;
        full[2] <= False;
        empty[2] <= True;
    endmethod    


endmodule

//////////////////////
// Conflict free fifo

// Intended schedule:
//      {notFull, enq} CF {notEmpty, first, deq}
//      {notFull, enq, notEmpty, first, deq} < clear
module mkMyCFFifo( Fifo#(n, t) ) provisos (Bits#(t,tSz));
    // n is size of fifo
    // t is data type of fifo
    Vector#(n, Reg#(t))     data     <- replicateM(mkReg(?));
    Ehr#(2,Bit#(TLog#(n)))    enqP     <- mkEhr(0);
    Ehr#(2,Bit#(TLog#(n)))    deqP     <- mkEhr(0);
    Ehr#(2,Bool)              empty    <- mkEhr(True);
    Ehr#(2,Bool)              full     <- mkEhr(False);

    // useful value
    Bit#(TLog#(n))          max_index = fromInteger(valueOf(n)-1);
    Ehr#(2,Maybe#(t))       enq_flag     <- mkEhr(?);
    Ehr#(2,Maybe#(Bool))            deq_flag     <- mkEhr(?);
    Ehr#(2,Maybe#(Bool))            clear_flag   <- mkEhr(?);


    (* no_implicit_conditions *)
    (* fire_when_enabled *)
    rule canonicalize;
        let enq_enable = isValid(enq_flag[1]) && (!full[0]);
        let deq_enable = isValid(deq_flag[1]) && (!empty[0]);      //without !full and !empty in condition will get wrong result

        if(enq_enable && !deq_enable) begin
            let flag = enqP[0];
            if(flag < max_index) begin
                enqP[0] <= enqP[0] + 1;
                flag = enqP[0] + 1;
            end
            else begin
                enqP[0] <= 0;
                flag = 0;
            end
            data[enqP[0]] <= fromMaybe(?, enq_flag[1]);
            empty[0] <= False;
            if(deqP[0]==flag) begin
                full[0] <= True;
            end
        end
        else if(deq_enable && !enq_enable) begin
            let flag = deqP[0];
            if(deqP[0] < max_index) begin
                deqP[0] <= deqP[0] + 1;
                flag = deqP[0] + 1;
            end
            else begin
                deqP[0] <= 0;
                flag = 0;
            end
            
            full[0] <= False;
            if(enqP[0]==flag) begin
                empty[0] <= True;
            end
        end
        else if(enq_enable && deq_enable) begin
            let flag = enqP[0];
            let flag2 = deqP[0];

            if(flag < max_index) begin
                enqP[0] <= enqP[0] + 1;
                flag = enqP[0] + 1;
            end
            else begin
                enqP[0] <= 0;
                flag = 0;
            end
            data[enqP[0]] <= fromMaybe(?, enq_flag[1]);

            if(deqP[0] < max_index) begin
                deqP[0] <= deqP[0] + 1;
                flag2 = deqP[0] + 1;
            end
            else begin
                deqP[0] <= 0;
                flag2 = 0;
            end
            
            full[0] <= False;
            empty[0] <= False;
        end
        enq_flag[1] <= tagged Invalid;
        deq_flag[1] <= tagged Invalid;

    endrule

    method Bool notFull();
        return !full[0];
    endmethod

    method Action enq(t x) if(!full[0]);
        enq_flag[0] <= tagged Valid x;
    endmethod

    method Bool notEmpty;
        return !empty[0];
    endmethod

    method Action deq if(!empty[0]);
        deq_flag[0] <= tagged Valid True;
    endmethod

    method t first if(!empty[0]);
        return data[deqP[0]];
    endmethod

    method Action clear;
        empty[1] <= True;
        full[1] <= False;
        deqP[1] <= 0;
        enqP[1] <= 0;
    endmethod



endmodule

