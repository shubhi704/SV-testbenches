
class transaction;
  rand bit [7:0]addr;
  rand bit [7:0]dataIn;
        bit [7:0]dataOut;
        bit we;
        constraint d_constraint{addr>5; addr<15; dataIn<15;};
endclass

class generator;
 
 transaction t;
 mailbox mbx;
 integer i;
 event done;

 function new(mailbox mbx);
    this.mbx = mbx;
 endfunction

 task run();
  t = new();

   for(i=0; i<40; i++) begin
    assert(t.randomize()) begin
    mbx.put(t);
    $display("[GEN] %t: data send to driver %0d %0d",$time,t.addr,t.dataIn);
    @(done);
    end
    else
      $display("[GEN] %t: Randomization failed",$time);
    end
  endtask
  endclass

  interface ram_intf();
     logic clk,rst,we;
     logic [7:0]addr,dataIn;
     logic [7:0]dataOut;
   endinterface

class driver;
 
 transaction t;
 mailbox mbx;
 event done;

 virtual ram_intf vif;

 function new(mailbox mbx);
    this.mbx = mbx;
 endfunction

 task run();
  t = new();
  forever begin
    mbx.get(t);
    vif.addr = t.addr;
    vif.dataIn = t.dataIn;
    $display("[DRV] %t: data rcvd by driver %0d %0d",$time,t.addr,t.dataIn);
    ->done;
    #10;
    end
  endtask
  endclass

 class monitor;
 
 transaction t;
 mailbox mbx;
 integer i;

 virtual ram_intf vif;

 function new(mailbox mbx);
    this.mbx = mbx;
 endfunction

 task run();
  t = new();
  forever begin
     t.addr = vif.addr ;
     t.dataIn = vif.dataIn ;
     t.dataOut = vif.dataOut  ;
    t.we = vif.we;
    mbx.put(t);
    $display("[MON] %t: data send to scoreboard %0d %0d %0d %0d",$time,vif.addr,vif.dataIn,vif.we,vif.dataOut);
    #10;
    end
  endtask
  endclass


class scoreboard;
 
 transaction t;
  mailbox mbx;
  integer i;

 function new(mailbox mbx);
    this.mbx = mbx;
 endfunction

 task run();
  t = new();
  forever begin
    mbx.get(t);
    $display("[SCO] %t: data rcvd by scoreboard %0d %0d %0d",$time,t.addr,t.dataIn,t.dataOut);
    #10;
    end
  endtask
  endclass 


class env;

 monitor mon;
 scoreboard sco;
 generator gen;
 driver drv;
 mailbox msmbx;
 mailbox gdmbx;
 event gddone;

virtual ram_intf vif;

 function new(mailbox gdmbx, mailbox msmbx);
    this.gdmbx = gdmbx;
    this.msmbx = msmbx;

    mon = new(msmbx);
    sco = new(msmbx);
    drv = new(gdmbx);
    gen = new(gdmbx);
 endfunction

 task run();
  
   gen.done = gddone;
   drv.done = gddone;

   drv.vif = vif;
   mon.vif = vif;
   fork
     gen.run();
     drv.run();
     mon.run();
     sco.run();
   join_any
  endtask
  endclass


  module tb;

  env e;
  ram_intf vif();

  ram dut( vif.clk, vif.rst, vif.we, vif.addr, vif.dataIn, vif.dataOut );

  mailbox msmbx;
  mailbox gdmbx;

  initial begin 
   gdmbx = new();
   msmbx = new();
   e = new(gdmbx,msmbx);
    e.vif = vif;
   e.run();
   end

always #5 vif.clk = ~vif.clk;


initial begin
   vif.clk = 0;
   vif.rst = 1;
   @(posedge vif.clk);
   vif.rst = 0;
   vif.we = 1;
   repeat(20) @(posedge vif.clk);
   vif.we = 0;
   #200;
   $finish;
 end
 initial begin
   $dumpvars;
   $dumpfile("dump.vcd");
   end

   endmodule
