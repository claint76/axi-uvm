////////////////////////////////////////////////////////////////////////////////
//
// Filename: 	axi_driver.svh
//
// Purpose:
//          UVM driver for AXI UVM environment
//
// Creator:	Matt Dew
//
////////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 2017, Matt Dew
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
class axi_driver extends uvm_driver #(axi_seq_item);
  `uvm_component_utils(axi_driver)

  axi_if_abstract vif;
  axi_agent_config    m_config;
  memory              m_memory;

  mailbox #(axi_seq_item) driver_writeaddress_mbx  = new(0);  //unbounded mailboxes
  mailbox #(axi_seq_item) driver_writedata_mbx     = new(0);
  mailbox #(axi_seq_item) driver_writeresponse_mbx = new(0);

  mailbox #(axi_seq_item) driver_readaddress_mbx  = new(0);
  mailbox #(axi_seq_item) driver_readdata_mbx     = new(0);

  mailbox #(axi_seq_item) responder_readaddress_mbx  = new(0);
  mailbox #(axi_seq_item) responder_readdata_mbx     = new(0);

  // probably unnecessary but
  // having different variables
  // makes it easier for me to follow (less confusing)
  mailbox #(axi_seq_item) responder_writeaddress_mbx  = new(0);  //unbounded mailboxes
  mailbox #(axi_seq_item) responder_writedata_mbx     = new(0);
  mailbox #(axi_seq_item) responder_writeresponse_mbx = new(0);


  extern function new (string name="axi_driver", uvm_component parent=null);

  extern function void build_phase              (uvm_phase phase);
  extern function void connect_phase            (uvm_phase phase);
  extern function void end_of_elaboration_phase (uvm_phase phase);
  extern task          run_phase                (uvm_phase phase);

  //extern task          write(ref axi_seq_item item);


  //extern task          driver_run_phase;
 //extern task          responder_run_phase;

  extern task          driver_write_address;
  extern task          driver_write_data;
  extern task          driver_write_response;

  extern task          driver_read_address;
  extern task          driver_read_data;


  extern task          responder_write_address;
  extern task          responder_write_data;
  extern task          responder_write_response;

  extern task          responder_read_address;
  extern task          responder_read_data;

    reg foo;

   // If multiple write transfers are queued,
   // this allows easily testing back to back or pausing between write address transfers.
  int min_clks_between_aw_transfers=0;
  int max_clks_between_aw_transfers=0;

  int min_clks_between_w_transfers=0;
  int max_clks_between_w_transfers=0;

  int min_clks_between_b_transfers=0;
  int max_clks_between_b_transfers=0;

  // AXI spec, A3.2.2,  states once valid is asserted,it must stay asserted until
    // ready asserts.  These varibles let us toggle valid to beat on the ready/valid
    // logic
    bit axi_incompatible_awready_toggling_mode=0;
    bit axi_incompatible_wready_toggling_mode=0;
    bit axi_incompatible_bready_toggling_mode=0;



   int min_clks_between_ar_transfers=0;
   int max_clks_between_ar_transfers=0;

   int min_clks_between_r_transfers=0;
   int max_clks_between_r_transfers=0;

   bit axi_incompatible_rready_toggling_mode=0;

endclass : axi_driver

function axi_driver::new (
  string        name   = "axi_driver",
  uvm_component parent = null);

  super.new(name, parent);
endfunction : new

function void axi_driver::build_phase (uvm_phase phase);
  super.build_phase(phase);

  vif = axi_if_abstract::type_id::create("vif", this);

endfunction : build_phase

function void axi_driver::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
endfunction : connect_phase

function void axi_driver::end_of_elaboration_phase (uvm_phase phase);
  super.end_of_elaboration_phase(phase);
endfunction : end_of_elaboration_phase

task axi_driver::run_phase(uvm_phase phase);


  axi_seq_item item;
  axi_seq_item cloned_item;

  if (m_config.drv_type == e_DRIVER) begin
    fork
       driver_write_address();
       driver_write_data();
       driver_write_response();

       driver_read_address();
       driver_read_data();
    join_none
    //driver_run_phase;

  end else if (m_config.drv_type == e_RESPONDER) begin
    fork
       responder_write_address();
       responder_write_data();
       responder_write_response();

       responder_read_data();
    join_none
    //responder_run_phase;
  end



  forever begin

    //item = axi_seq_item::type_id::create("item", this);
    seq_item_port.get(item);
    $cast(cloned_item, item.clone());

    `uvm_info("axi_driver::run_phase",
              $sformatf("YO: %s", item.convert2string()),
              UVM_INFO)

    case (item.cmd)
      axi_uvm_pkg::e_WRITE : begin
        driver_writeaddress_mbx.put(item);
      end
      axi_uvm_pkg::e_READ  : begin
        driver_readaddress_mbx.put(item);
      end
      axi_uvm_pkg::e_READ_DATA  : begin
        `uvm_info("e_READ_DATA",
                  "stuffing item into responder_readdata_mbx.put(item);",
                  UVM_INFO)
        responder_readdata_mbx.put(item);
      end

      axi_uvm_pkg::e_SETAWREADYTOGGLEPATTERN : begin
         `uvm_info(this.get_type_name(),
                   $sformatf("Setting awready toggle patter: 0x%0x", item.toggle_pattern),
                   UVM_INFO)
         vif.enable_awready_toggle_pattern(.pattern(item.toggle_pattern));
      end
      axi_uvm_pkg::e_SETWREADYTOGGLEPATTERN : begin
         `uvm_info(this.get_type_name(),
                   $sformatf("Setting wready toggle patter: 0x%0x", item.toggle_pattern),
                   UVM_INFO)
         vif.enable_wready_toggle_pattern(.pattern(item.toggle_pattern));
      end
      axi_uvm_pkg::e_SETARREADYTOGGLEPATTERN : begin
         `uvm_info(this.get_type_name(),
                   $sformatf("Setting arready toggle patter: 0x%0x", item.toggle_pattern),
                   UVM_INFO)
         vif.enable_arready_toggle_pattern(.pattern(item.toggle_pattern));
      end

      default : begin
        responder_writeaddress_mbx.put(item);
      end
   endcase

  end // forever

endtask : run_phase


/*
   driver_write_address - driver write address phase
   1. wait for TLM item to get queued
   2. initialize variables
   3. write out
   4. if ready and valid, wait X (x>=0 clks), then check for any more queued items
   5. if avail, then fetch and goto step 2.
   6. if no items to be drivein on next clk, the drive all write address signals low
      and goto step 1.
*/
task axi_driver::driver_write_address;

  axi_seq_item item=null;
  axi_seq_item_aw_vector_s v;

   bit [63:0] aligned_addr;

  int minval;
  int maxval;
  int wait_clks_before_next_aw;

  int item_needs_init=1;

  vif.set_awvalid(1'b0);

  forever begin

    if (item == null) begin
       driver_writeaddress_mbx.get(item);
       item_needs_init=1;
    end

    vif.wait_for_clks(.cnt(1));

      // if done with this xfer (write address is only one clock, done with valid & ready
       if (vif.get_awready_awvalid == 1'b1) begin
          driver_writedata_mbx.put(item);
          item=null;

          minval=min_clks_between_aw_transfers;
          maxval=max_clks_between_aw_transfers;
          wait_clks_before_next_aw=$urandom_range(maxval,minval);

          // Check if delay wanted
          if (wait_clks_before_next_aw==0) begin
             // if not, check if there's another item
             driver_writeaddress_mbx.try_get(item);
             if (item!=null) begin
                item_needs_init=1;
             end
          end
       end
       // Initialize values
       if (item_needs_init==1) begin
          axi_seq_item::aw_from_class(.t(item), .v(v));
          v.awlen  = item.calculate_beats(.addr(item.addr),
                                          .number_bytes(2**item.burst_size), //item.number_bytes
                                          .burst_length(item.len));

         `uvm_info("====> v.awlen <====", $sformatf("v.awlen == %d", v.awlen), UVM_INFO)

          v.awaddr = item.calculate_aligned_address(.addr(v.awaddr),
                                                    .number_bytes(4));
          item_needs_init=0;
       end

        // Update values <- No need in write address (only one clk per)

       // Write out
       if (item != null) begin
          vif.write_aw(.s(v), .valid(1'b1));
          if (wait_clks_before_next_aw > 0) begin
             vif.wait_for_clks(.cnt(wait_clks_before_next_aw-1)); // -1 because another wait
                                                                // at beginning of loop
          end
       end   // if (item != null)

    // No item for next clock, so close out bus
    if (item == null) begin
         v.awaddr  = 'h0;
         v.awid    = 'h0;
         v.awsize  = 'h0;
         v.awburst = 'h0;
         vif.write_aw(.s(v), .valid(1'b0));
         vif.wait_for_clks(.cnt(1));
    end

    end // forever

endtask : driver_write_address

/*
   driver_write_data - driver write data phase
   1. wait for TLM item to get queued
   2. initialize variables
   3. loop
   4.    update variables when wready & wvalid (slave has received current beat)
   5.    write out
   6. if wlast and ready and valid, wait X (x>=0 clks), then check for any more queued items
   7. if avail, then fetch and goto step 2.
   8. if no items to be drivein on next clk, the drive all write data signals low
      and goto step 1.
*/
task axi_driver::driver_write_data;
  axi_seq_item item=null;
  axi_seq_item_w_vector_s s;

  bit iaxi_incompatible_wready_toggling_mode;

  int n=0;

  int minval;
  int maxval;
  int wait_clks_before_next_w;

  vif.set_wvalid(1'b0);
  forever begin

    if (item == null) begin
       driver_writedata_mbx.get(item);
      item.initialize();
    end

    // Look at this only one per loop, so there's no race condition of it
    // changing mid-loop.
    iaxi_incompatible_wready_toggling_mode = axi_incompatible_wready_toggling_mode;

    vif.wait_for_clks(.cnt(1));

    // defaults. not needed but  I think is cleaner in sim
    s.wvalid = 'b0;
    s.wdata  = 'hfeed_beef;
    s.wstrb  = 'h0;
    s.wlast  = 1'b0;

    // Check if done with this transfer
    if (vif.get_wready()==1'b1 && vif.get_wvalid() == 1'b1) begin
      item.dataoffset = n;
      if (iaxi_incompatible_wready_toggling_mode == 1'b0) begin
         item.validcntr++;
      end

      item.update_address();

      if (item.dataoffset>=item.Burst_Length_Bytes) begin //F
          driver_writeresponse_mbx.put(item);
          item = null;

          minval=min_clks_between_w_transfers;
          maxval=max_clks_between_w_transfers;
          wait_clks_before_next_w=$urandom_range(maxval,minval);

          // Check if delay wanted
          if (wait_clks_before_next_w==0) begin
             // if not, check if there's another item
             driver_writedata_mbx.try_get(item);

             if (item != null) begin
               item.initialize();
             end
          end
       end
    end  // (vif.get_wready()==1'b1 && vif.get_wvalid() == 1'b1)


    // Update values
    if (item != null) begin

      if (item.validcntr >=  item.validcntr_max) begin
         item.validcntr=0;
       end

       //
       // if invalid-toggling-mode is enabled, then allow deasserting valid
       // before ready asserts.
       // Default is to stay asserted, and only allow deasssertion after ready asserts.
       if (iaxi_incompatible_wready_toggling_mode == 1'b0) begin
          if (vif.get_wvalid() == 1'b0) begin
             item.validcntr++;
          end
       end else begin
             item.validcntr++;
       end

       s.wvalid = item.valid[item.validcntr]; // 1'b1;
       s.wstrb  = 'h0;
       s.wdata  = 'h0;
       s.wlast  = 1'b0;
       n=item.dataoffset;
      for (int j=item.Lower_Byte_Lane;j<=item.Upper_Byte_Lane;j++) begin
        s.wdata[j*8+:8] = item.data[n++];
          s.wstrb[j]      = 1'b1;
        if (n>=item.Burst_Length_Bytes) begin
             s.wlast=1'b1;
             break;
          end
       end // for

       // Write out
       vif.write_w(.s(s),.waitforwready(0));


    end // (item != null)

    // No item for next clock, so close out bus
    if (item == null) begin
       s.wvalid = 1'b0;
       s.wlast  = 1'b0;
       s.wdata  = 'h0;
 //    s.wid    = 'h0; AXI3 only
       s.wstrb  = 'h0;

       vif.write_w(.s(s),.waitforwready(0));

       if (wait_clks_before_next_w > 0) begin
          vif.wait_for_clks(.cnt(wait_clks_before_next_w-1));
                                        // -1 because another wait
                                        // at beginning of loop
       end
    end // if (item == null
  end // forever
endtask : driver_write_data



task axi_driver::driver_write_response;

  axi_seq_item            item;
  axi_seq_item_b_vector_s s;

  vif.set_bready_toggle_mask(m_config.bready_toggle_mask);

  forever begin
    driver_writeresponse_mbx.get(item);
 //   `uvm_info(this.get_type_name(), "HEY, driver_write_response!!!!", UVM_INFO)
  //  vif.wait_for_bvalid();
    vif.read_b(.s(s));
    item.bid   = s.bid;
    item.bresp = s.bresp;
 //   `uvm_info(this.get_type_name(), "HEY, HEY, waiting on seq_item_port.put()", UVM_INFO)
    seq_item_port.put(item);
  //  `uvm_info(this.get_type_name(), "HEY, HEY, waiting on seq_item_port.put() - done", UVM_INFO)
  //  `uvm_info(this.get_type_name(), $sformatf("driver_write_response: %s", item.convert2string()), UVM_INFO)

  end
endtask : driver_write_response



task axi_driver::driver_read_address;

  axi_seq_item item=null;
  axi_seq_item_ar_vector_s v;

   bit [63:0] aligned_addr;

  int minval;
  int maxval;
  int wait_clks_before_next_ar;

  int item_needs_init=1;

  vif.set_arvalid(1'b0);

  forever begin

    if (item == null) begin
       driver_readaddress_mbx.get(item);
       item_needs_init=1;
    end

    vif.wait_for_clks(.cnt(1));

      // if done with this xfer (write address is only one clock, done with valid & ready
    if (vif.get_arready_arvalid == 1'b1) begin
          driver_readdata_mbx.put(item);
          item=null;

          minval=min_clks_between_ar_transfers;
          maxval=max_clks_between_ar_transfers;
          wait_clks_before_next_ar=$urandom_range(maxval,minval);

          // Check if delay wanted
      if (wait_clks_before_next_ar==0) begin
             // if not, check if there's another item
             driver_readaddress_mbx.try_get(item);
             if (item!=null) begin
                item_needs_init=1;
             end
          end
       end
       // Initialize values
       if (item_needs_init==1) begin
          axi_seq_item::ar_from_class(.t(item), .v(v));
          v.arlen  = item.calculate_beats(.addr(item.addr),
                                          .number_bytes(2**item.burst_size), //item.number_bytes
                                          .burst_length(item.len));

         v.araddr = item.calculate_aligned_address(.addr(v.araddr),
                                                    .number_bytes(4));
          item_needs_init=0;
       end

        // Update values <- No need in write address (only one clk per)

       // Write out
       if (item != null) begin
          vif.write_ar(.s(v), .valid(1'b1));
         if (wait_clks_before_next_ar > 0) begin
           vif.wait_for_clks(.cnt(wait_clks_before_next_ar-1)); // -1 because another wait
                                                                // at beginning of loop
          end
       end   // if (item != null)

    // No item for next clock, so close out bus
    if (item == null) begin
         v.araddr  = 'h0;
         v.arid    = 'h0;
         v.arsize  = 'h0;
         v.arburst = 'h0;
         v.arlen   = 'h0;
         vif.write_ar(.s(v), .valid(1'b0));
         vif.wait_for_clks(.cnt(1));
    end

    end // forever

endtask : driver_read_address

task axi_driver::driver_read_data;

  axi_seq_item_r_vector_s  r_s;
  axi_seq_item item;

  vif.enable_rready_toggle_pattern(.pattern(m_config.rready_toggle_pattern));

  driver_readdata_mbx.get(item);
  item.data=new[item.len];
  item.dataoffset=0;

  forever begin
    vif.wait_for_read_data(.s(r_s));

    `uvm_info(this.get_type_name(),$sformatf("r_s.data: 0x%0x   LowerLane:%0d   Upperlane:%0d", r_s.rdata,item.Lower_Byte_Lane,item.Upper_Byte_Lane),
              UVM_INFO)

    for (int z=item.Lower_Byte_Lane;z<item.Upper_Byte_Lane;z++) begin
      item.data[item.dataoffset++] = r_s.rdata[z];
    end
    item.update_address();
    // `uvm_info("driver_read_data", "YO, got beat:", UVM_INFO)
    if (r_s.rlast == 1'b1) begin
     // `uvm_info("driver_read_data", "YO, got rlast:", UVM_INFO)
      seq_item_port.put(item);
    end
  end   //forever

//end


endtask : driver_read_data

task axi_driver::responder_write_address;

  axi_seq_item             item;
  axi_seq_item_aw_vector_s s;


  forever begin
    responder_writeaddress_mbx.get(item);
 //   `uvm_info(this.get_type_name(), "axi_driver::responder_write_address Getting address", UVM_INFO)
    vif.read_aw(.s(s));
    axi_seq_item::aw_to_class(.t(item), .v(s));

    item.data=new[item.len];
    item.wlast=new[item.len];
    item.wstrb=new[item.len];

    responder_writedata_mbx.put(item);
  end
endtask : responder_write_address




task axi_driver::responder_write_data;

  int          i;
  axi_seq_item item;
  axi_seq_item litem;
  int          datacnt;
  axi_seq_item_w_vector_s s;
  bit foo;

  forever begin
     responder_writedata_mbx.get(item);
 //   `uvm_info(this.get_type_name(),
 //             $sformatf("axi_driver::responder_write_data - Waiting for data for %s",
 //                       item.convert2string()),
 //             UVM_INFO)
    /*
      i=0;
      while (i<item.len/4) begin
         vif.wait_for_clks(.cnt(1));
        if (vif.get_wready_wvalid() == 1'b1)  begin
           vif.read_w(s);
           axi_seq_item::w_to_class(
            {item.data[i*4+3],
             item.data[i*4+2],
             item.data[i*4+1],
             item.data[i*4+0]},
            {item.wstrb[i*4+3],
             item.wstrb[i*4+2],
             item.wstrb[i*4+1],
             item.wstrb[i*4+0]},
            foo,
            item.wlast[i],
            .v(s));

           i++;
    //    `uvm_info(this.get_type_name(),
    //              $sformatf("axi_driver::responder_write_data GOT %d for data for %s", i,
   //                     item.convert2string()),
    //          UVM_INFO)
      end

    end
    */
    //    `uvm_info(this.get_type_name(),
     //            $sformatf("axi_driver::responder_write_data responder_writeresponse_mbx.put - %s",
   //                     item.convert2string()),
   //           UVM_INFO)
     responder_writeresponse_mbx.put(item);
  end
endtask : responder_write_data


task axi_driver::responder_write_response;
  axi_seq_item item=null;
  axi_seq_item_b_vector_s s;


   bit [63:0] aligned_addr;

  int minval;
  int maxval;
  int wait_clks_before_next_b;

  int item_needs_init=1;

  forever begin

    if (item == null) begin
       responder_writeresponse_mbx.get(item);
       item_needs_init=1;
    end

    vif.wait_for_clks(.cnt(1));

      // if done with this xfer (write address is only one clock, done with valid & ready
      if (vif.get_bready_bvalid == 1'b1) begin
      //    driver_writedata_mbx.put(item);
          item=null;

          minval=min_clks_between_b_transfers;
          maxval=max_clks_between_b_transfers;
          wait_clks_before_next_b=$urandom_range(maxval,minval);

          // Check if delay wanted
        if (wait_clks_before_next_b==0) begin
             // if not, check if there's another item
             driver_writeresponse_mbx.try_get(item);
             if (item!=null) begin
                item_needs_init=1;
             end
          end
       end

       // Initialize values
       if (item_needs_init==1) begin
          item_needs_init=0;
       end

        // Update values <- No need in write address (only one clk per)

       // Write out
       if (item != null) begin
          s.bid   = 'h3;
          s.bresp = 'h1;
          vif.write_b(.s(s), .valid(1'b1));
         if (wait_clks_before_next_b > 0) begin
            vif.wait_for_clks(.cnt(wait_clks_before_next_b-1)); // -1 because another wait
                                                                // at beginning of loop
          end
       end   // if (item != null)

    // No item for next clock, so close out bus
    if (item == null) begin
          s.bid   = 'h0;
          s.bresp = 'h0;
      vif.write_b(.s(s), .valid(1'b0));
          vif.wait_for_clks(.cnt(1));
    end

    end // forever

endtask : responder_write_response

task axi_driver::responder_read_address;
endtask : responder_read_address


task axi_driver::responder_read_data;
  axi_seq_item item=null;
  axi_seq_item_r_vector_s s;

  bit iaxi_incompatible_rready_toggling_mode;

  int n=0;

  int minval;
  int maxval;
  int wait_clks_before_next_r;

  vif.set_rvalid(1'b0);
  forever begin

    if (item == null) begin
       responder_readdata_mbx.get(item);
      //item.len=item.len*4;
      //item.Burst_Length_Bytes=item.Burst_Length_Bytes*4;
      item.initialize();

      item.dataoffset=0;
    end

    // Look at this only one per loop, so there's no race condition of it
    // changing mid-loop.
    iaxi_incompatible_rready_toggling_mode = axi_incompatible_rready_toggling_mode;

    vif.wait_for_clks(.cnt(1));

    // defaults. not needed but  I think is cleaner in sim
    s.rvalid = 'b0;
    s.rdata  = 'hfeed_beef;
    s.rid    = 'h0;
    // s.rstrb  = 'h0;
    s.rlast  = 1'b0;
    `uvm_info("READ_DATA", $sformatf("item: %s", item.convert2string()), UVM_INFO)
    // Check if done with this transfer
    if (vif.get_rready()==1'b1 && vif.get_rvalid() == 1'b1) begin
      item.dataoffset = n;
      if (iaxi_incompatible_rready_toggling_mode == 1'b0) begin
         item.validcntr++;
      end

      item.update_address();

      if (item.dataoffset>=item.Burst_Length_Bytes) begin //F
          // driver_writeresponse_mbx.put(item);
          item = null;

          minval=min_clks_between_r_transfers;
          maxval=max_clks_between_r_transfers;
          wait_clks_before_next_r=$urandom_range(maxval,minval);

          // Check if delay wanted
        if (wait_clks_before_next_r==0) begin
             // if not, check if there's another item
             responder_readdata_mbx.try_get(item);

             if (item != null) begin
               item.Burst_Length_Bytes=item.Burst_Length_Bytes*4;
               item.initialize();
             end
          end
       end
    end  // (vif.get_wready()==1'b1 && vif.get_wvalid() == 1'b1)


    // Update values
    if (item != null) begin

      if (item.validcntr >=  item.validcntr_max) begin
         item.validcntr=0;
       end

       //
       // if invalid-toggling-mode is enabled, then allow deasserting valid
       // before ready asserts.
       // Default is to stay asserted, and only allow deasssertion after ready asserts.
      if (iaxi_incompatible_rready_toggling_mode == 1'b0) begin
        if (vif.get_rvalid() == 1'b0) begin
             item.validcntr++;
          end
       end else begin
             item.validcntr++;
       end

       s.rvalid = 1'b1;// item.valid[item.validcntr]; // 1'b1;
       //s.rstrb  = 'h0;
       s.rdata  = 'h0;
       s.rlast  = 1'b0;
       n=item.dataoffset;
      for (int j=item.Lower_Byte_Lane;j<=item.Upper_Byte_Lane;j++) begin
        s.rdata[j*8+:8] = item.data[n++];
          //s.rstrb[j]      = 1'b1;
        if (n>=item.Burst_Length_Bytes) begin
             s.rlast=1'b1;
             break;
          end
       end // for

       // Write out
      vif.write_r(.s(s),.waitforrready(0));


    end // (item != null)

    // No item for next clock, so close out bus
    if (item == null) begin
       s.rvalid = 1'b0;
       s.rlast  = 1'b0;
       s.rdata  = 'h0;
 //    s.wid    = 'h0; AXI3 only
       // s.rstrb  = 'h0;

      vif.write_r(.s(s),.waitforrready(0));

      if (wait_clks_before_next_r > 0) begin
        vif.wait_for_clks(.cnt(wait_clks_before_next_r-1));
                                        // -1 because another wait
                                        // at beginning of loop
       end
    end // if (item == null
  end // forever
endtask : responder_read_data

