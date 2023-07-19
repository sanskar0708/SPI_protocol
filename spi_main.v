


module spi_main (
   input   clk, reset,
   input   [7:0] din,
   input   [15:0] dvsr,  // 0.5*(# clk in SCK period) 
   input   start, cpol, cpha,
   output  [7:0] dout,
   output  spi_done_tick, ready,
   output  sclk,
   input   miso,
   output  mosi
   );

   
   localparam idle=0, cpha_delay=1, p0=2, p1=3;

   
   reg [2:0] state_reg, state_next;
   wire p_clk;
   reg [15:0] c_reg, c_next;
   reg spi_clk_reg, ready_i, spi_done_tick_i;
   wire spi_clk_next;
   reg [2:0] n_reg, n_next;
   reg [7:0] si_reg, si_next;
   reg [7:0] so_reg, so_next;
   

   always @(posedge clk, posedge reset)
	begin
      if (reset) begin
         state_reg <= idle;
         si_reg <= 0;
         so_reg <= 0;
         n_reg <= 0;
         c_reg <= 0;
         spi_clk_reg <= 0;
      end
      else begin
         state_reg <= state_next;
         si_reg <= si_next;
         so_reg <= so_next;
         n_reg <= n_next;
         c_reg <=c_next;
         spi_clk_reg <= spi_clk_next;
      end
	end  
   // next-state logic
   always @(*)
   begin
      state_next = state_reg;  
      ready_i = 0;
      spi_done_tick_i = 0;
      si_next = si_reg;
      so_next = so_reg;
      n_next = n_reg;
      c_next = c_reg;  
      case (state_reg)
         idle: begin
            ready_i = 1;
            if (start) begin
               so_next = din;
               n_next = 0;
               c_next = 0;
               if (cpha)  
                  state_next = cpha_delay;
               else 
                  state_next = p0;                 
            end
         end   
         cpha_delay: begin      
            if (c_reg==dvsr) begin  
               state_next = p0;
               c_next = 0;
           end
           else
               c_next = c_reg + 1;
         end  
         p0: begin     
            if (c_reg==dvsr) begin  // sclk 0-to-1
               state_next = p1;
               si_next = {si_reg[6:0], miso}; 
               c_next = 0;
            end
            else
               c_next = c_reg + 1;  
         end
         p1: begin
            if (c_reg==dvsr)       // sclk 1-to-0
               if (n_reg==7) begin
                  spi_done_tick_i = 1;
                  state_next = idle;
               end
               else begin     
                  so_next = {so_reg[6:0], 1'b0};  
                  state_next = p0;
                  n_next = n_reg + 1;
                  c_next = 0;
               end 
            else
               c_next = c_reg + 1;  
        end   
      endcase
   end
   assign ready = ready_i;
   assign spi_done_tick = spi_done_tick_i;


   assign p_clk = (state_next== p1 && ~cpha) || (state_next==p0 && cpha);
   
   assign spi_clk_next = (cpol) ? ~p_clk : p_clk;
   // output
   assign dout = si_reg;
   assign mosi = so_reg[7];
   assign sclk = spi_clk_reg;
endmodule


