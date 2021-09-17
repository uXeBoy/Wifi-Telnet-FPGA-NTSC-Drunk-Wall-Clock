`default_nettype none // disable implicit definitions by Verilog
`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Create Date:    19:03:41 12/15/2007
// Module Name:    NTSC
// http://ca.olin.edu/2007/ntsc/
//////////////////////////////////////////////////////////////////////////////////

module NTSC(
  input            clk,
  output reg [2:0] signal,

  input            wclk,
  input            din,
  input            reset
);

  wire [1:0] d1; // 0-2
  wire [3:0] d2; // 0-9
  wire [3:0] d3; // 0-5
  wire [3:0] d4; // 0-9
  wire [3:0] d5; // 0-5
  wire [3:0] d6; // 0-9

  reg [23:0] mem;
  reg  [4:0] waddr;

  assign d1 = mem[21:20];
  assign d2 = mem[19:16];
  assign d3 = mem[15:12];
  assign d4 = mem[11:8];
  assign d5 = mem[7:4];
  assign d6 = mem[3:0];

  always @(posedge wclk)
  begin
    if (reset) begin
      waddr <= 23; // MSBFIRST
    end
    else begin
      mem[waddr] <= din;
      waddr <= waddr - 1'b1;
    end
  end


////////////////////////////////
// states
////////////////////////////////
reg [1:0] lineState;
parameter sFP = 0,
          sHSYNC = 1,
          sBP = 2,
          sLINE = 3;

reg       syncState;
parameter sIMAGE = 0,
          sVSYNC = 1;

reg [1:0] vbiState;
parameter sPRE = 0,
          sVERT = 1,
          sPOST = 2,
          sBLANK = 3;

reg       fieldState;
parameter sEVEN = 0,
          sODD = 1;

initial begin
    lineState = sFP;
    syncState = sIMAGE;
    fieldState = sEVEN;
end


////////////////////////////////
// signal
////////////////////////////////
parameter nWHITE = 3'b111, // 0.6125V
          nBLACK = 3'b011, // 0.2625V
          nSYNC = 3'b000; // 0V

reg [7:0] pixel;
reg [8:0] line;

wire [7:0] scale;
assign scale = line[8:1];

////////////////////////////////
// timers
////////////////////////////////
// timer counts must be 1 less than calculated because timer starts at 0!!!
// clkFreq = 25000000;
reg [10:0] lineTimer;
reg        resetTimer;

initial begin
    lineTimer = 0;
    resetTimer = 0;
end


////////////////////////////////
// the thing
////////////////////////////////
always @(posedge clk) begin
    if (resetTimer) begin
        lineTimer = 0;
        resetTimer = 0;
    end else begin
        lineTimer = lineTimer + 1;
    end

    case (syncState)

    //////////////////////////////
    // image
    //////////////////////////////

    sIMAGE: begin
        case (lineState)
        sFP: begin
            signal = nBLACK;
            if (lineTimer >= 34) begin // 1.4 us
                lineState = sHSYNC;
                resetTimer = 1;
            end
        end
        sHSYNC: begin
            signal = nSYNC;
            if (lineTimer >= 117) begin // 4.7 us
                lineState = sBP;
                resetTimer = 1;

                // set up the pixel address
                pixel = 0;
//              address = line * 256 + pixel;
            end
        end
        sBP: begin
            signal = nBLACK;
            if (lineTimer >= 146) begin // 5.9 us
                lineState = sLINE;
                resetTimer = 1;
            end
        end
        sLINE: begin
            if (pixel < 255) begin
                if (lineTimer >= 4) begin // 200 ns per pixel
                    //Seg A
                    if ((scale > 80 && scale < 89 && pixel > 13 && pixel < 43) && (d1 == 0 || d1 == 2)) signal = nWHITE;
                    //Seg B
                    else if ((scale > 88 && scale < 118 && pixel > 42 && pixel < 51) && (d1 == 0 || d1 == 1 || d1 == 2)) signal = nWHITE;
                    //Seg C
                    else if ((scale > 125 && scale < 155 && pixel > 42 && pixel < 51) && (d1 == 0 || d1 == 1)) signal = nWHITE;
                    //Seg D
                    else if ((scale > 154 && scale < 163 && pixel > 13 && pixel < 43) && (d1 == 0 || d1 == 2)) signal = nWHITE;
                    //Seg E
                    else if ((scale > 125 && scale < 155 && pixel > 6 && pixel < 14) && (d1 == 0 || d1 == 2)) signal = nWHITE;
                    //Seg F
                    else if ((scale > 88 && scale < 118 && pixel > 6 && pixel < 14) && (d1 == 0)) signal = nWHITE;
                    //Seg G
                    else if ((scale > 117 && scale < 126 && pixel > 13 && pixel < 43) && (d1 == 2)) signal = nWHITE;

                    //Seg A
                    else if ((scale > 80 && scale < 89 && pixel > 60 && pixel < 90) && (d2 == 0 || d2 == 2 || d2 == 3 || d2 == 5 || d2 == 6 || d2 == 7 || d2 == 8 || d2 == 9)) signal = nWHITE;
                    //Seg B
                    else if ((scale > 88 && scale < 118 && pixel > 89 && pixel < 98) && (d2 == 0 || d2 == 1 || d2 == 2 || d2 == 3 || d2 == 4 || d2 == 7 || d2 == 8 || d2 == 9)) signal = nWHITE;
                    //Seg C
                    else if ((scale > 125 && scale < 155 && pixel > 89 && pixel < 98) && (d2 == 0 || d2 == 1 || d2 == 3 || d2 == 4 || d2 == 5 || d2 == 6 || d2 == 7 || d2 == 8 || d2 == 9)) signal = nWHITE;
                    //Seg D
                    else if ((scale > 154 && scale < 163 && pixel > 60 && pixel < 90) && (d2 == 0 || d2 == 2 || d2 == 3 || d2 == 5 || d2 == 6 || d2 == 8 || d2 == 9)) signal = nWHITE;
                    //Seg E
                    else if ((scale > 125 && scale < 155 && pixel > 52 && pixel < 61) && (d2 == 0 || d2 == 2 || d2 == 6 || d2 == 8)) signal = nWHITE;
                    //Seg F
                    else if ((scale > 88 && scale < 118 && pixel > 52 && pixel < 61) && (d2 == 0 || d2 == 4 || d2 == 5 || d2 == 6 || d2 == 8 || d2 == 9)) signal = nWHITE;
                    //Seg G
                    else if ((scale > 117 && scale < 126 && pixel > 60 && pixel < 90) && (d2 == 2 || d2 == 3 || d2 == 4 || d2 == 5 || d2 == 6 || d2 == 8 || d2 == 9)) signal = nWHITE;

                    //Seg A
                    else if ((scale > 80 && scale < 89 && pixel > 107 && pixel < 137) && (d3 == 0 || d3 == 2 || d3 == 3 || d3 == 5)) signal = nWHITE;
                    //Seg B
                    else if ((scale > 88 && scale < 118 && pixel > 136 && pixel < 145) && (d3 == 0 || d3 == 1 || d3 == 2 || d3 == 3 || d3 == 4)) signal = nWHITE;
                    //Seg C
                    else if ((scale > 125 && scale < 155 && pixel > 136 && pixel < 145) && (d3 == 0 || d3 == 1 || d3 == 3 || d3 == 4 || d3 == 5)) signal = nWHITE;
                    //Seg D
                    else if ((scale > 154 && scale < 163 && pixel > 107 && pixel < 137) && (d3 == 0 || d3 == 2 || d3 == 3 || d3 == 5)) signal = nWHITE;
                    //Seg E
                    else if ((scale > 125 && scale < 155 && pixel > 99 && pixel < 108) && (d3 == 0 || d3 == 2)) signal = nWHITE;
                    //Seg F
                    else if ((scale > 88 && scale < 118 && pixel > 99 && pixel < 108) && (d3 == 0 || d3 == 4 || d3 == 5)) signal = nWHITE;
                    //Seg G
                    else if ((scale > 117 && scale < 126 && pixel > 107 && pixel < 137) && (d3 == 2 || d3 == 3 || d3 == 4 || d3 == 5)) signal = nWHITE;

                    //Seg A
                    else if ((scale > 80 && scale < 89 && pixel > 154 && pixel < 184) && (d4 == 0 || d4 == 2 || d4 == 3 || d4 == 5 || d4 == 6 || d4 == 7 || d4 == 8 || d4 == 9)) signal = nWHITE;
                    //Seg B
                    else if ((scale > 88 && scale < 118 && pixel > 183 && pixel < 192) && (d4 == 0 || d4 == 1 || d4 == 2 || d4 == 3 || d4 == 4 || d4 == 7 || d4 == 8 || d4 == 9)) signal = nWHITE;
                    //Seg C
                    else if ((scale > 125 && scale < 155 && pixel > 183 && pixel < 192) && (d4 == 0 || d4 == 1 || d4 == 3 || d4 == 4 || d4 == 5 || d4 == 6 || d4 == 7 || d4 == 8 || d4 == 9)) signal = nWHITE;
                    //Seg D
                    else if ((scale > 154 && scale < 163 && pixel > 154 && pixel < 184) && (d4 == 0 || d4 == 2 || d4 == 3 || d4 == 5 || d4 == 6 || d4 == 8 || d4 == 9)) signal = nWHITE;
                    //Seg E
                    else if ((scale > 125 && scale < 155 && pixel > 146 && pixel < 155) && (d4 == 0 || d4 == 2 || d4 == 6 || d4 == 8)) signal = nWHITE;
                    //Seg F
                    else if ((scale > 88 && scale < 118 && pixel > 146 && pixel < 155) && (d4 == 0 || d4 == 4 || d4 == 5 || d4 == 6 || d4 == 8 || d4 == 9)) signal = nWHITE;
                    //Seg G
                    else if ((scale > 117 && scale < 126 && pixel > 154 && pixel < 184) && (d4 == 2 || d4 == 3 || d4 == 4 || d4 == 5 || d4 == 6 || d4 == 8 || d4 == 9)) signal = nWHITE;

                    //Seg A
                    else if ((scale > 99 && scale < 102) && (((pixel > 195 && pixel < 215) && (d5 == 0 || d5 == 2 || d5 == 3 || d5 == 5)) ||
                                                             ((pixel > 220 && pixel < 240) && (d6 == 0 || d6 == 2 || d6 == 3 || d6 == 5 || d6 == 6 || d6 == 7 || d6 == 8 || d6 == 9)))) signal = nWHITE;
                    //Seg B
                    else if ((scale > 101 && scale < 121) && (((pixel > 214 && pixel < 217) && (d5 == 0 || d5 == 1 || d5 == 2 || d5 == 3 || d5 == 4)) ||
                                                              ((pixel > 239 && pixel < 242) && (d6 == 0 || d6 == 1 || d6 == 2 || d6 == 3 || d6 == 4 || d6 == 7 || d6 == 8 || d6 == 9)))) signal = nWHITE;
                    //Seg C
                    else if ((scale > 122 && scale < 142) && (((pixel > 214 && pixel < 217) && (d5 == 0 || d5 == 1 || d5 == 3 || d5 == 4 || d5 == 5)) ||
                                                              ((pixel > 239 && pixel < 242) && (d6 == 0 || d6 == 1 || d6 == 3 || d6 == 4 || d6 == 5 || d6 == 6 || d6 == 7 || d6 == 8 || d6 == 9)))) signal = nWHITE;
                    //Seg D
                    else if ((scale > 141 && scale < 144) && (((pixel > 195 && pixel < 215) && (d5 == 0 || d5 == 2 || d5 == 3 || d5 == 5)) ||
                                                              ((pixel > 220 && pixel < 240) && (d6 == 0 || d6 == 2 || d6 == 3 || d6 == 5 || d6 == 6 || d6 == 8 || d6 == 9)))) signal = nWHITE;
                    //Seg E
                    else if ((scale > 122 && scale < 142) && (((pixel > 193 && pixel < 196) && (d5 == 0 || d5 == 2)) ||
                                                              ((pixel > 218 && pixel < 221) && (d6 == 0 || d6 == 2 || d6 == 6 || d6 == 8)))) signal = nWHITE;
                    //Seg F
                    else if ((scale > 101 && scale < 121) && (((pixel > 193 && pixel < 196) && (d5 == 0 || d5 == 4 || d5 == 5)) ||
                                                              ((pixel > 218 && pixel < 221) && (d6 == 0 || d6 == 4 || d6 == 5 || d6 == 6 || d6 == 8 || d6 == 9)))) signal = nWHITE;
                    //Seg G
                    else if ((scale > 120 && scale < 123) && (((pixel > 195 && pixel < 215) && (d5 == 2 || d5 == 3 || d5 == 4 || d5 == 5)) ||
                                                              ((pixel > 220 && pixel < 240) && (d6 == 2 || d6 == 3 || d6 == 4 || d6 == 5 || d6 == 6 || d6 == 8 || d6 == 9)))) signal = nWHITE;

                    else signal = nBLACK;

                    pixel = pixel + 1;
                    resetTimer = 1;
                end
            end else begin
                line = line + 2;
                lineState = sFP;

                if (line >= 483) begin
                    syncState = sVSYNC;
                    vbiState = sPRE;
                    line = 0;
                    resetTimer = 1;
                end
            end
        end
        endcase
    end

    //////////////////////////////
    // vertical synchronization
    //////////////////////////////
    sVSYNC: begin
//  if (fieldState == sEVEN) begin
//  end
        case (vbiState)
        sPRE: begin
            case (lineState)
            sFP: begin
                signal = nSYNC;
                if (lineTimer >= 34) begin // 1.4 us
                    lineState = sLINE;
                    resetTimer = 1;
                end
            end
            sLINE: begin
                signal = nBLACK;
                if (lineTimer >= 758) begin // 63.5/2 - 1.4 us
                    lineState = sFP;
                    resetTimer = 1;
                    line = line + 1;

                    if ((fieldState == sEVEN && line >= 7) || (fieldState == sODD && line >= 6)) begin
                        vbiState = sVERT;
                        line = 0;
                    end
                end
            end
            endcase
        end
        sVERT: begin
            case (lineState)
            sFP: begin
                signal = nSYNC;
                if (lineTimer >= 675) begin // 63.5/2 - 4.7 us
                    lineState = sHSYNC;
                    resetTimer = 1;
                end
            end
            sHSYNC: begin
                signal = nBLACK;
                if (lineTimer >= 117) begin // 4.7 us
                    lineState = sFP;
                    resetTimer = 1;
                    line = line + 1;

                    if (line >= 6) begin
                        vbiState = sPOST;
                        line = 0;
                    end
                end
            end
            endcase
        end
        sPOST: begin
            case (lineState)
            sFP: begin
                signal = nSYNC;
                if (lineTimer >= 34) begin // 1.4 us
                    lineState = sLINE;
                    resetTimer = 1;
                end
            end
            sLINE: begin
                signal = nBLACK;
                if (lineTimer >= 758) begin // 63.5/2 - 1.4 us
                    lineState = sFP;
                    resetTimer = 1;
                    line = line + 1;

                    if ((fieldState == sEVEN && line >= 5) || (fieldState == sODD && line >= 6)) begin
                        vbiState = sBLANK;
                        line = 0;
                    end
                end
            end
            endcase
        end
        sBLANK: begin
            case (lineState)
            sFP: begin
                signal = nSYNC;
                if (lineTimer >= 117) begin // 4.7 us
                    lineState = sLINE;
                    resetTimer = 1;
                end
            end
            sLINE: begin
                signal = nBLACK;
                if (lineTimer >= 1469) begin // 63.5 - 4.7 us
                    lineState = sFP;
                    resetTimer = 1;
                    line = line + 1;

                    if ((fieldState == sEVEN && line >= 12) || (fieldState == sODD && line >= 11)) begin
                        lineState = sFP;
                        syncState = sIMAGE;
                        fieldState = !fieldState;

                        // start on line 0 if sODD, line 1 if sEVEN
                        line = fieldState;
                    end
                end
            end
            endcase
        end
        endcase
    end
    endcase
end


endmodule