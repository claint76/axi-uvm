////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	tb.svh
//
// Project:	Pipelined Wishbone to AXI converter - UVM testbench
//
// Purpose:	
//          Top Level Testbench
//
// Creator:	Matt Dew
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2016, Matt Dew
//
// This program is free software (firmware): you can redistribute it and/or
// modify it under the terms of  the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or (at
// your option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
// for more details.
//
// License:	GPL, v3, as defined and found on www.gnu.org,
//		http://www.gnu.org/licenses/gpl.html
//
//
////////////////////////////////////////////////////////////////////////////////
//
//


module tb;
  
   import params_pkg::*;

   parameter C_AXI_ID_WIDTH   = params_pkg::AXI_ID_WIDTH;
   parameter C_AXI_ADDR_WIDTH = params_pkg::AXI_ADDR_WIDTH;
   parameter C_AXI_DATA_WIDTH = params_pkg::AXI_DATA_WIDTH;
  
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  
  import axi_uvm_pkg::*;

  
  logic clk;
  logic reset;
  
  wire                          axi_awready;
  wire [C_AXI_ID_WIDTH-1:0]	    axi_awid;
  wire [C_AXI_ADDR_WIDTH-1:0]   axi_awaddr;
  wire [7:0]                    axi_awlen;    // Write Burst Length
  wire [2:0]                    axi_awsize;	  // Write Burst size
  wire [1:0]                    axi_awburst;  // Write Burst type
  wire [0:0]                    axi_awlock;   // Write lock type
  wire [3:0]                    axi_awcache;  // Write Cache type
  wire [2:0]                    axi_awprot;   // Write Protection type
  wire [3:0]                    axi_awqos;    // Write Quality of Svc
  wire                          axi_awvalid;  // Write address valid
  
  // AXI write data channel signals
  wire                          axi_wready;   // Write data ready
  wire [C_AXI_DATA_WIDTH-1:0]   axi_wdata;    // Write data
  wire [C_AXI_DATA_WIDTH/8-1:0] axi_wstrb;    // Write strobes
  wire                          axi_wlast;    // Last write transaction   
  wire                          axi_wvalid;   // Write valid
  
  // AXI write response channel signals
  wire [C_AXI_ID_WIDTH-1:0]     axi_bid;      // Response ID
  wire [1:0]                    axi_bresp;    // Write response
  wire                          axi_bvalid;   // Write reponse valid
  wire                          axi_bready;   // Response ready

  // AXI read address channel signals
  wire                         axi_arready; // Read address ready
  wire [C_AXI_ID_WIDTH-1:0]    axi_arid;    // Read ID
  wire [C_AXI_ADDR_WIDTH-1:0]  axi_araddr;  // Read address
  wire [7:0]                   axi_arlen;  // Read Burst Length
  wire [2:0]                   axi_arsize;  // Read Burst size
  wire [1:0]                   axi_arburst; // Read Burst type
  wire [0:0]                   axi_arlock;  // Read lock type
  wire [3:0]                   axi_arcache; // Read Cache type
  wire [2:0]                   axi_arprot;  // Read Protection type
  wire [3:0]                   axi_arqos;   // Read Protection type
  wire                         axi_arvalid; // Read address valid
  
// AXI read data channel signals   
  wire [C_AXI_ID_WIDTH-1:0]    axi_rid;     // Response ID
  wire [1:0]		           axi_rresp;   // Read response
  wire                         axi_rvalid;  // Read reponse valid
  wire [C_AXI_DATA_WIDTH-1:0]  axi_rdata;   // Read data
  wire                         axi_rlast;   // Read last
  wire                         axi_rready;  // Read Response ready
  
//  wire                            o_reset;
  wire                            wb_cyc;
  wire                            wb_stb;
  wire                            wb_we;
  wire [(C_AXI_ADDR_WIDTH-1):0]   wb_addr;
  wire [(C_AXI_DATA_WIDTH-1):0]   wb_indata;
  wire [(C_AXI_DATA_WIDTH-1):0]   wb_outdata;
  wire [(C_AXI_DATA_WIDTH/8-1):0] wb_sel;
  wire                            wb_ack;
  wire                            wb_stall;
  wire                            wb_err;
  
  
  axi_if #(.C_AXI_ID_WIDTH   (C_AXI_ID_WIDTH),
              .C_AXI_DATA_WIDTH (C_AXI_DATA_WIDTH),
              .C_AXI_ADDR_WIDTH (C_AXI_ADDR_WIDTH)
          ) axi_driver_vif (.clk   (clk),
               .reset (reset),
               .awready(axi_awready),
               .awid(axi_awid),
               .awaddr(axi_awaddr),
               .awlen(axi_awlen),
               .awsize(axi_awsize),
               .awburst(axi_awburst),
               .awlock(axi_awlock),
               .awcache(axi_awcache),
               .awprot(axi_awprot),
               .awqos(axi_awqos),
               .awvalid(axi_awvalid),
  
               .wready(axi_wread),
               .wdata(axi_wdata),
               .wstrb(axi_wstrb),
               .wlast(axi_wlast),
               .wvalid(axi_wvalid),
  
               .bid(axi_bid),
               .bresp(axi_bresp),
               .bvalid(axi_bvalid),
               .bready(axi_bready),
                
               .arready(axi_arready),
               .arid(axi_arid),
               .araddr(axi_araddr),
               .arlen(axi_arlen),
               .arsize(axi_arsize),
               .arburst(axi_arburst),
               .arlock(axi_arlock),
               .arcache(axi_arcache),
               .arprot(axi_arprot),
               .arqos(axi_arqos),
               .arvalid(axi_arvalid),
  
               .rid(axi_rid),
               .rresp(axi_rresp),
               .rvalid(axi_rvalid),
               .rdata(axi_rdata),
               .rlast(axi_rlast),
               .rready(axi_rready)
             );
  
    axi_if #(.C_AXI_ID_WIDTH   (C_AXI_ID_WIDTH),
              .C_AXI_DATA_WIDTH (C_AXI_DATA_WIDTH),
              .C_AXI_ADDR_WIDTH (C_AXI_ADDR_WIDTH)
            ) axi_responder_vif (.clk   (clk),
               .reset (reset),
               .awready(axi_awready),
               .awid(axi_awid),
               .awaddr(axi_awaddr),
               .awlen(axi_awlen),
               .awsize(axi_awsize),
               .awburst(axi_awburst),
               .awlock(axi_awlock),
               .awcache(axi_awcache),
               .awprot(axi_awprot),
               .awqos(axi_awqos),
               .awvalid(axi_awvalid),
  
               .wready(axi_wread),
               .wdata(axi_wdata),
               .wstrb(axi_wstrb),
               .wlast(axi_wlast),
               .wvalid(axi_wvalid),
  
               .bid(axi_bid),
               .bresp(axi_bresp),
               .bvalid(axi_bvalid),
               .bready(axi_bready),
                
               .arready(axi_arready),
               .arid(axi_arid),
               .araddr(axi_araddr),
               .arlen(axi_arlen),
               .arsize(axi_arsize),
               .arburst(axi_arburst),
               .arlock(axi_arlock),
               .arcache(axi_arcache),
               .arprot(axi_arprot),
               .arqos(axi_arqos),
               .arvalid(axi_arvalid),
  
               .rid(axi_rid),
               .rresp(axi_rresp),
               .rvalid(axi_rvalid),
               .rdata(axi_rdata),
               .rlast(axi_rlast),
               .rready(axi_rready)
             );
  
  
  wb_if #(.C_AXI_DATA_WIDTH (C_AXI_DATA_WIDTH),
          .C_AXI_ADDR_WIDTH (C_AXI_ADDR_WIDTH)
         ) wb_vif (.clk   (clk),
                   .reset (reset),

          .cyc   (wb_cyc),
          .stb   (wb_stb),
          .we    (wb_we),
          .addr  (wb_addr),
          .indata  (wb_indata),
          .sel   (wb_sel),
          .ack   (wb_ack),
          .stall (wb_stall),
          .outdata  (wb_outdata),
          .err   (wb_err)
        );
  
         
  /*
  
  axim2wbsp #( .C_AXI_ID_WIDTH(C_AXI_ID_WIDTH),
              .C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
              .C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH)
             ) 
              dut
             (
               .i_clk(clk),	// System clock
               .i_axi_reset_n(~reset),

                // AXI write address channel signals
               .o_axi_awready(axi_awready),
               .i_axi_awid(axi_awid),
               .i_axi_awaddr(axi_awaddr),
               .i_axi_awlen(axi_awlen),
               .i_axi_awsize(axi_awsize),
               .i_axi_awburst(axi_awburst),
               .i_axi_awlock(axi_awlock),
               .i_axi_awcache(axi_awcache),
               .i_axi_awprot(axi_awprot),
               .i_axi_awqos(axi_awqos),
               .i_axi_awvalid(axi_awvalid),
  
                // AXI write data channel signals
               .o_axi_wready(axi_wread),
               .i_axi_wdata(axi_wdata),
               .i_axi_wstrb(axi_wstrb),
               .i_axi_wlast(axi_wlast),
               .i_axi_wvalid(axi_wvalid),
  
               // AXI write response channel signals
               .o_axi_bid(axi_bid),
               .o_axi_bresp(axi_bresp),
               .o_axi_bvalid(axi_bvalid),
               .i_axi_bready(axi_bready),
  
               // AXI read address channel signals
               .o_axi_arready(axi_arready),
               .i_axi_arid(axi_arid),
               .i_axi_araddr(axi_araddr),
               .i_axi_arlen(axi_arlen),
               .i_axi_arsize(axi_arsize),
               .i_axi_arburst(axi_arburst),
               .i_axi_arlock(axi_arlock),
               .i_axi_arcache(axi_arcache),
               .i_axi_arprot(axi_arprot),
               .i_axi_arqos(axi_arqos),
               .i_axi_arvalid(axi_arvalid),
  
               // AXI read data channel signals   
               .o_axi_rid(axi_rid),
               .o_axi_rresp(axi_rresp),
               .o_axi_rvalid(axi_rvalid),
               .o_axi_rdata(axi_rdata),
               .o_axi_rlast(axi_rlast),
               .i_axi_rready(axi_rready),

	           // We'll share the clock and the reset
               .o_reset(),
               .o_wb_cyc(wb_cyc),
               .o_wb_stb(wb_stb),
               .o_wb_we(wb_we),
               .o_wb_addr(wb_addr),
               .o_wb_data(wb_indata),
               .o_wb_sel(wb_sel),
               .i_wb_ack(wb_ack),
               .i_wb_stall(wb_stall),
               .i_wb_data(wb_outdata),
               .i_wb_err(wb_err) 
               );
  */
 
  
  
  // tbx clkgen
initial begin
   clk = 0;
   forever begin
      #10 clk = ~clk;
   end
end

// tbx clkgen
initial begin
   reset = 1;
   #100 reset = 0;
end

initial begin
  axi_driver_vif.use_concrete_class(.drv_type(axi_pkg::e_DRIVER));
  axi_responder_vif.use_concrete_class(.drv_type(axi_pkg::e_RESPONDER));

  //axi_rd_vif.use_concrete_class();
  //wb_vif.use_concrete_class();

  run_test("axim2wbsp_base_test");    
end
  
initial begin
  $dumpfile("dump.vcd");
  //$dumpvars(0, dut.axi_write_decoder); //(1);
  $dumpvars(1); //(1);

end
  
endmodule : tb




