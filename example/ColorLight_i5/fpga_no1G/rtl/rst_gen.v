module rst_gen (
    input  clk_i,
    input  rst_i,
    output rst_o
);

/* try to generate a reset */
reg [3:0] rst_cpt;
always @(posedge clk_i) begin
    if (rst_i) begin
        rst_cpt <= 3'b0;
    end else begin
        if (rst_cpt == 4'b1000) begin
            rst_cpt <= rst_cpt;
        end else begin
            rst_cpt <= rst_cpt + 3'b1;
        end
    end
end

assign rst_o = !rst_cpt[3];

endmodule
