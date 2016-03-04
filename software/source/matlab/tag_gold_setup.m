genGoldCodes;
hex_mults = 0:size(goldSequences,2)-1;
hex_mults = 7-mod(hex_mults,8);
hex_mults = 2.^hex_mults;
hex_mults = repmat(hex_mults,[size(goldSequences,1),1]);

gold_dec = goldSequences.*hex_mults;
gold_dec_bytes = ceil(size(gold_dec,2)/8);

%Pad with zeros
gold_dec = [gold_dec,zeros(size(gold_dec,1),gold_dec_bytes*8-size(gold_dec,2))];

gold_dec = reshape(gold_dec,[size(gold_dec,1),8,size(gold_dec,2)/8]);
gold_dec = squeeze(sum(gold_dec,2));

for ii=1:size(gold_dec,1)
	disp(sprintf('0x%02X, ',gold_dec(ii,:)))
end

disp(['size = ', num2str(size(goldSequences,2))])
