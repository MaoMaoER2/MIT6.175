import Vector::*;
import Complex::*;

import FftCommon::*;
import Fifo::*;

interface Fft;
    method Action enq(Vector#(FftPoints, ComplexData) in);
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
endinterface


(* synthesize *)
module mkFftCombinational(Fft);
    Fifo#(2,Vector#(FftPoints, ComplexData)) inFifo <- mkCFFifo;
    Fifo#(2,Vector#(FftPoints, ComplexData)) outFifo <- mkCFFifo;
    Vector#(NumStages, Vector#(BflysPerStage, Bfly4)) bfly <- replicateM(replicateM(mkBfly4));

    function Vector#(FftPoints, ComplexData) stage_f(StageIdx stage, Vector#(FftPoints, ComplexData) stage_in);
        Vector#(FftPoints, ComplexData) stage_temp, stage_out;
        for (FftIdx i = 0; i < fromInteger(valueOf(BflysPerStage)); i = i + 1)  begin
            FftIdx idx = i * 4;
            Vector#(4, ComplexData) x;
            Vector#(4, ComplexData) twid;
            for (FftIdx j = 0; j < 4; j = j + 1 ) begin
                x[j] = stage_in[idx+j];
                twid[j] = getTwiddle(stage, idx+j);
            end
            let y = bfly[stage][i].bfly4(twid, x);

            for(FftIdx j = 0; j < 4; j = j + 1 ) begin
                stage_temp[idx+j] = y[j];
            end
        end

        stage_out = permute(stage_temp);

        return stage_out;
    endfunction
    


    rule doFft;
        if( inFifo.notEmpty && outFifo.notFull ) begin
            inFifo.deq;
            //insert 3 stage register to wait pipeline result

            Vector#(4, Vector#(FftPoints, ComplexData)) stage_data;
            stage_data[0] = inFifo.first;
      
            for (StageIdx stage = 0; stage < 3; stage = stage + 1) begin
                stage_data[stage+1] = stage_f(stage, stage_data[stage]);
            end
            outFifo.enq(stage_data[3]);
        end
    endrule
    
    method Action enq(Vector#(FftPoints, ComplexData) in);
        inFifo.enq(in);
    endmethod
  
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
        outFifo.deq;
        return outFifo.first;
    endmethod
endmodule

// (* synthesize *)
// pipe_line wait version
// module mkFftCombinational(Fft);
//     Fifo#(2,Vector#(FftPoints, ComplexData)) inFifo <- mkCFFifo;
//     Fifo#(2,Vector#(FftPoints, ComplexData)) outFifo <- mkCFFifo;
//     Vector#(3, Reg#(Vector#(64, ComplexData))) pipe_Reg <- replicateM(mkReg(replicate(ComplexData{rel:0,img:0})));
//     Vector#(NumStages, Vector#(BflysPerStage, Bfly4)) bfly <- replicateM(replicateM(mkBfly4));

//     function Vector#(FftPoints, ComplexData) stage_f(StageIdx stage, Vector#(FftPoints, ComplexData) stage_in);
//         Vector#(FftPoints, ComplexData) stage_temp, stage_out;
//         for (FftIdx i = 0; i < fromInteger(valueOf(BflysPerStage)); i = i + 1)  begin
//             FftIdx idx = i * 4;
//             Vector#(4, ComplexData) x;
//             Vector#(4, ComplexData) twid;
//             for (FftIdx j = 0; j < 4; j = j + 1 ) begin
//                 x[j] = stage_in[idx+j];
//                 twid[j] = getTwiddle(stage, idx+j);
//             end
//             let y = bfly[stage][i].bfly4(twid, x);

//             for(FftIdx j = 0; j < 4; j = j + 1 ) begin
//                 stage_temp[idx+j] = y[j];
//             end
//         end

//         stage_out = permute(stage_temp);

//         return stage_out;
//     endfunction
    


//     rule doFft;
//         if( inFifo.notEmpty && outFifo.notFull ) begin
//             inFifo.deq;
//             //insert 3 stage register to wait pipeline result
//             pipe_Reg[0] <= inFifo.first;
//             pipe_Reg[1] <= pipe_Reg[0];
//             pipe_Reg[2] <= pipe_Reg[1];

//             Vector#(4, Vector#(FftPoints, ComplexData)) stage_data;
//             stage_data[0] = pipe_Reg[2];
      
//             for (StageIdx stage = 0; stage < 3; stage = stage + 1) begin
//                 stage_data[stage+1] = stage_f(stage, stage_data[stage]);
//             end
//             outFifo.enq(stage_data[3]);
//         end
//     endrule
    
//     method Action enq(Vector#(FftPoints, ComplexData) in);
//         inFifo.enq(in);
//     endmethod
  
//     method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
//         outFifo.deq;
//         return outFifo.first;
//     endmethod
// endmodule

(* synthesize *)
module mkFftFolded(Fft);
    Fifo#(2,Vector#(FftPoints, ComplexData)) inFifo <- mkCFFifo;
    Fifo#(2,Vector#(FftPoints, ComplexData)) outFifo <- mkCFFifo;
    Vector#(16, Bfly4) bfly <- replicateM(mkBfly4);

    rule doFft;
        //TODO: Implement the rest of this module
    endrule

    method Action enq(Vector#(FftPoints, ComplexData) in) if( inFifo.notFull );
        inFifo.enq(in);
    endmethod
  
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq if( outFifo.notEmpty );
        outFifo.deq;
        return outFifo.first;
    endmethod
endmodule

(* synthesize *)
module mkFftInelasticPipeline(Fft);
    Fifo#(2,Vector#(FftPoints, ComplexData)) inFifo <- mkCFFifo;
    Fifo#(2,Vector#(FftPoints, ComplexData)) outFifo <- mkCFFifo;
    Vector#(3, Vector#(16, Bfly4)) bfly <- replicateM(replicateM(mkBfly4));

    Vector#(3, Reg#(Vector#(64, ComplexData))) pipe_Reg <- replicateM(mkReg(replicate(ComplexData{rel:0,img:0})));
    Reg#(Bit#(3)) cnt_flag <- mkReg(0);

    function Vector#(FftPoints, ComplexData) stage_f(StageIdx stage, Vector#(FftPoints, ComplexData) stage_in);
        Vector#(FftPoints, ComplexData) stage_temp, stage_out;
        for (FftIdx i = 0; i < fromInteger(valueOf(BflysPerStage)); i = i + 1)  begin
            FftIdx idx = i * 4;
            Vector#(4, ComplexData) x;
            Vector#(4, ComplexData) twid;
            for (FftIdx j = 0; j < 4; j = j + 1 ) begin
                x[j] = stage_in[idx+j];
                twid[j] = getTwiddle(stage, idx+j);
            end
            let y = bfly[stage][i].bfly4(twid, x);

            for(FftIdx j = 0; j < 4; j = j + 1 ) begin
                stage_temp[idx+j] = y[j];
            end
        end

        stage_out = permute(stage_temp);

        return stage_out;
    endfunction

    rule doFft( inFifo.notEmpty && outFifo.notFull );
        //TODO: Implement the rest of this module
        let input_ = pipe_Reg[0];
        inFifo.deq;
        pipe_Reg[0] <= stage_f(0, inFifo.first);
        pipe_Reg[1] <= stage_f(1, pipe_Reg[0]);
        pipe_Reg[2] <= stage_f(2, pipe_Reg[1]);
        
        
        for (Integer i = 0; i < fftPoints; i = i + 1) begin
            $display ("\t%x,%x ", input_[i].rel, input_[i].img);
        end


        outFifo.enq(pipe_Reg[2]);
        
    endrule

    method Action enq(Vector#(FftPoints, ComplexData) in);
        inFifo.enq(in);
    endmethod
  
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq if(outFifo.notEmpty);
        outFifo.deq;
        return outFifo.first;
    endmethod
endmodule

(* synthesize *)
module mkFftElasticPipeline(Fft);
    Fifo#(2,Vector#(FftPoints, ComplexData)) inFifo <- mkCFFifo;
    Fifo#(2,Vector#(FftPoints, ComplexData)) outFifo <- mkCFFifo;
    Vector#(3, Vector#(16, Bfly4)) bfly <- replicateM(replicateM(mkBfly4));

    //TODO: Implement the rest of this module
    // You should use more than one rule
    Vector#(3, Fifo#(3,Vector#(FftPoints, ComplexData))) pipe_fifo <- replicateM(mkCFFifo_3);


        function Vector#(FftPoints, ComplexData) stage_f(StageIdx stage, Vector#(FftPoints, ComplexData) stage_in);
        Vector#(FftPoints, ComplexData) stage_temp, stage_out;
        for (FftIdx i = 0; i < fromInteger(valueOf(BflysPerStage)); i = i + 1)  begin
            FftIdx idx = i * 4;
            Vector#(4, ComplexData) x;
            Vector#(4, ComplexData) twid;
            for (FftIdx j = 0; j < 4; j = j + 1 ) begin
                x[j] = stage_in[idx+j];
                twid[j] = getTwiddle(stage, idx+j);
            end
            let y = bfly[stage][i].bfly4(twid, x);

            for(FftIdx j = 0; j < 4; j = j + 1 ) begin
                stage_temp[idx+j] = y[j];
            end
        end

        stage_out = permute(stage_temp);

        return stage_out;
    endfunction

    // rule doFft( inFifo.notEmpty && outFifo.notFull );
    //     //TODO: Implement the rest of this module
    //     let input_ = pipe_Reg[0];
    //     inFifo.deq;
    //     pipe_fifo[0].enq(stage_f(0, inFifo.first));
    //     pipe_fifo[1].enq(stage_f(1, pipe_fifo[0].deq));
    //     pipe_fifo[2].enq(stage_f(2, pipe_fifo[1].deq));
        
        
    //     for (Integer i = 0; i < fftPoints; i = i + 1) begin
    //         $display ("\t%x,%x ", input_[i].rel, input_[i].img);
    //     end


    //     outFifo.enq(pipe_fifo[2].deq);
        
    // endrule

    rule stage_1;
        inFifo.deq;
        pipe_fifo[0].enq(stage_f(0, inFifo.first));
    endrule

    rule stage_2;
        pipe_fifo[1].enq(stage_f(1, pipe_fifo[0].first));
        pipe_fifo[0].deq;
    endrule

    rule stage_3;
        pipe_fifo[2].enq(stage_f(2, pipe_fifo[1].first));
        pipe_fifo[1].deq;
    endrule

    rule stage_3_0;
        pipe_fifo[2].deq;
        outFifo.enq(pipe_fifo[2].first);
    endrule

    method Action enq(Vector#(FftPoints, ComplexData) in);
        inFifo.enq(in);
    endmethod
  
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
        outFifo.deq;
        return outFifo.first;
    endmethod
endmodule

interface SuperFoldedFft#(numeric type radix);
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
    method Action enq(Vector#(FftPoints, ComplexData) in);
endinterface

module mkFftSuperFolded(SuperFoldedFft#(radix)) provisos(Div#(TDiv#(FftPoints, 4), radix, times), Mul#(radix, times, TDiv#(FftPoints, 4)));
    Fifo#(2,Vector#(FftPoints, ComplexData)) inFifo <- mkCFFifo;
    Fifo#(2,Vector#(FftPoints, ComplexData)) outFifo <- mkCFFifo;
    Vector#(radix, Bfly4) bfly <- replicateM(mkBfly4);

    rule doFft;
        //TODO: Implement the rest of this module
    endrule

    method Action enq(Vector#(FftPoints, ComplexData) in);
        inFifo.enq(in);
    endmethod
  
    method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
        outFifo.deq;
        return outFifo.first;
    endmethod
endmodule

function Fft getFft(SuperFoldedFft#(radix) f);
    return (interface Fft;
        method enq = f.enq;
        method deq = f.deq;
    endinterface);
endfunction

(* synthesize *)
module mkFftSuperFolded4(Fft);
    SuperFoldedFft#(4) sfFft <- mkFftSuperFolded;
    return (getFft(sfFft));
endmodule
