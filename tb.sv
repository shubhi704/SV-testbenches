
class transaction;
 randc bit [7:0]a;
 randc bit [7:0]b;
 bit [15:0] y;
 constraint d_constraint{ a<4; a>11; b>5; b<9;};
endclass
 
 class generator;
  transaction t;   // handler
  mailbox mbx;     // use for communication of data
  event done;      // use for communication of msg
  integer i;
  
  function new (mailbox mbx);  // constructor
    this.mbx = mbx;
    endfunction
 
 task run();
   t = new();
   for(i=0; i<20; i++) begin
      t.randomize();
      mbx.put(t);
      $display("[GEN]: data send to driver");
      @(done);
      #10;
      end
      endtask
      endclass
      
  class driver;
  transaction t;   // handler
  mailbox mbx;     // use for communication of data
  event done;      // use for communication of msg
  integer i;
  
  virtual multiplier_intf vif;
  
  function new (mailbox mbx);  // constructor
    this.mbx = mbx;
    endfunction
 
 task run();
   t = new();
   forever begin
      mbx.get(t);
      vif.a = t.a;
      vif.b = t.b;
      $display("[DRV]: data rcvd by driver");
      ->done;
      #10;
      end
      endtask
      endclass
      
 interface multiplier_intf();
   logic [7:0]a;
   logic [7:0]b;
   logic [15:0] y;
endinterface

class monitor;
  transaction t;   // handler
  mailbox mbx;     // use for communication of data
  integer i;
  
  virtual multiplier_intf vif;
  
  function new (mailbox mbx);  // constructor
    this.mbx = mbx;
    endfunction
 
 task run();
   t = new();
   forever begin
      t.a =  vif.a;
      t.b = vif.b;
      t.y = vif.y;
      mbx.put(t);
      $display("[MON]: data send to scoreboard");
      #10;
      end
      endtask
      endclass


endinterface

class scoreboard;
  transaction t;   // handler
  mailbox mbx;     // use for communication of data
  bit [15:0] temp;
  
  function new (mailbox mbx);  // constructor
    this.mbx = mbx;
    endfunction
 
 task run();
   t = new();
   forever begin
      mbx.get(t);
      temp == t.a * t.b;
      if(temp == t.y) begin
              $display("[SCO]: Test passed");
              end
      else begin
              $display("[SCO]: Test failed");
              end
      #10;
      end
      endtask
      endclass
      
      
  class environment;
  transaction t;   // handler
  monitor mon;
  generator gen;
  scoreboard sco;
  mailbox gdmbx;     // use for communication of data
  mailbox msmbx;

   virtual multiplier_intf vif;
   
   event gddone;

  function new (mailbox gdmbx, mailbox msmbx);  // constructor
    this.gdmbx = gdmbx;
    this.msmbx = msmbx;
    
    gen = new(gdmbx);
    drv = new(gdmbx);
    mon = new(msmbx);
    sco = new(msmbx)
    endfunction
 
 task run();
   gen.done = gddone;
   drv.done = gddone;
   
   drv.vif = vif;
   mon.vif = vif;
   fork
     gen.run();
     mon.run();
     drv.run();
     sco.run();
   join_any
 endtask
 endclass
 
 
 
 module tb()
 
  envirnment env;
  mailbox gdmbx;     // use for communication of data
  mailbox msmbx;
  
  multiplier dut(vif.a, vif.b, vif.y);
  
  multiplier_intf vif();
  
  initial begin
   
   gdmbx = new();
   msmbx = new();
   env = new(gdmbx,msmbx);
   env.vif = vif;
   #200;
   end
   
   initial begin
     $dumpfile("dump.vcd");
     $dumpvars;
     end
     
     endmodule
   
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      


