i = 260;

%%
file = fopen('code.txt', 'w');

%%
fprintf(file, 'module inSumSquare(\n\t');
fprintf(file, 'input SYS_CLK,\n\t');
fprintf(file, 'input [11:0] inValue,\n\t');
fprintf(file, 'input validCondition,\n\t');
fprintf(file, 'output reg [23:0] outValue\n\t');
fprintf(file, ');\n\n');


%%
fprintf(file, 'reg [11:0] ');
for counter = 1:i-1,
    fprintf(file, 'x%g, ', counter-1);
end
fprintf(file, 'x%g;\n\n\n', i-1);

%%
fprintf(file, 'always @(posedge SYS_CLK) begin\n');
fprintf(file, '\tif (validCondition) begin\n');
fprintf(file, '\t\tx0 <= inValue;\n');
for counter = 1:i-1,
    fprintf(file, '\t\tx%g <= x%g;\n', counter, counter-1);
end
fprintf(file, '\tend\n');
fprintf(file, 'end\n\n');

%%
fprintf(file, 'always @(posedge SYS_CLK) begin\n');
fprintf(file, '\tif (validCondition) begin\n');
fprintf(file, '\t\toutValue <= ');
for counter = 1:i-1;
    fprintf(file, 'x%g*x%g + ', counter-1, counter-1);
end
fprintf(file, 'x259*x259;\n');
fprintf(file, '\tend\n');
fprintf(file, '\telse begin\n');
fprintf(file, '\t\toutValue <= outValue;\n');
fprintf(file, '\tend\n');
fprintf(file, 'end\n\n');

%%
fprintf(file, 'endmodule\n');

%%
fclose(file);
