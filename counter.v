module count_score(clk, coll1,coll2, reset, score0, score1, score2, score3);
input		coll1,coll2, reset, clk;
output 	[3:0]score0, score1, score2, score3;
reg		[3:0]score0, score1, score2, score3;

always@ (posedge clk or posedge reset)begin
	if(reset) begin
		score0 = 4'b0000;  //000
		score1 = 4'b0000;  //000
		score2 = 4'b0000;  //000
		score3 = 4'b0000;  //000
	end
	//+1
	else if(coll2 == 1'b1) begin
		if (score3 == 4'b1001 && score2 == 4'b1001 && score1 == 4'b1001 && score0 == 4'b1001)begin  
			score0 = 4'b0000;  //000
			score1 = 4'b0000;  //000
			score2 = 4'b0000;  //000
			score3 = 4'b0000;  //000
		end
		else if(score0 == 4'b1001) begin
			score0 = 4'b0000;
			score1 = score1 + 4'b0001;
			if(score1 == 4'b1001 ) begin
				score0 = 4'b0000;
				score1 = 4'b0000;
				score2 = score2 + 4'b0001;
			end
		end
		else if(score1 == 4'b1001 && score0 == 4'b1001) begin
			score0 = 4'b0000;
			score1 = 4'b0000;
			score2 = score2 + 4'b0001;
		end
		else if(score2 == 4'b1001 && score1 == 4'b1001 && score0 == 4'b1001) begin
			score0 = 4'b0000;
			score1 = 4'b0000;
			score2 = 4'b0000;
			score3 = score3 + 4'b0001;
		end
		else
			score0 = score0 + 4'b0001;
	end
//-1
	else if(coll1 == 1'b1) begin
		if (score3 == 4'b1001 && score2 == 4'b1001 && score1 == 4'b1001 && score0 == 4'b1001)begin  
			score0 = 4'b0000;  //000
			score1 = 4'b0000;  //000
			score2 = 4'b0000;  //000
			score3 = 4'b0000;  //000
		end
		else if(score0 == 4'b1001) begin
			score0 = 4'b0000;
			score1 = score1 - 4'b0001;
			if(score1 == 4'b1001 ) begin
				score0 = 4'b0000;
				score1 = 4'b0000;
				score2 = score2 - 4'b0001;
			end
		end
		else if(score1 == 4'b1001 && score0 == 4'b1001) begin
			score0 = 4'b0000;
			score1 = 4'b0000;
			score2 = score2 - 4'b0001;
		end
		else if(score2 == 4'b1001 && score1 == 4'b1001 && score0 == 4'b1001) begin
			score0 = 4'b0000;
			score1 = 4'b0000;
			score2 = 4'b0000;
			score3 = score3 - 4'b0001;
		end
		else
			score0 = score0 -  4'b0001;
	end
end
endmodule
