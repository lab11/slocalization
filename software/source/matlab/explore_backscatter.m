INTERP_SIZE = 2^16;
%TOA_THRESH = 0.5;

gold_code = [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1]-.5;
gold_len = length(gold_code);

disp('Reading CIRs from file...')
[cirs, packet_idxs] = readBackScatterData('backscatter_test4_stationary.csv');

disp('Correlating CIRs...')
result_len = floor(size(cirs,2)/2)-2;
diff_plus_two = zeros(INTERP_SIZE,result_len);
diff_plus_one = zeros(INTERP_SIZE,result_len);
diff_angle_two = zeros(result_len,1);
diff_angle_one = zeros(result_len,1);
phase_corrections = zeros(result_len, 4);
backscatter_toas = zeros(result_len,1);
expected_phase_angle_error = zeros(result_len,1);

cirs_aligned = zeros(INTERP_SIZE, size(cirs,2));
pops = zeros(size(cirs,2),1);
for ii=2:size(cirs,2)
    [poa1, poa2, pop1, pop2] = lineUpCIRs(cirs(:,1),cirs(:,ii),INTERP_SIZE);
    cirs_aligned(:,1) = poa1;
    cirs_aligned(:,ii) = poa2;
    [max_abs,max_idx] = max(abs(poa2));
    pops(ii) = max_abs;
end

gold_corrs = zeros(INTERP_SIZE,size(cirs,2)-gold_len);
for ii=1:size(cirs,2)-gold_len
    disp(['ii = ',num2str(ii)])
    
    gold_corr = zeros(INTERP_SIZE,1);
    for jj=1:gold_len
        gold_corr = gold_corr + cirs_aligned(:,ii+jj-1)*gold_code(jj);
    end
    gold_corrs(:,ii) = gold_corr;
%     cir = cirs(:,ii);
%     cir_plus_1 = cirs(:,ii+1);
%     cir_plus_2 = cirs(:,ii+2);
%     [poa1, poa2, pop1, pop2] = lineUpCIRs(cir,cir_plus_1,INTERP_SIZE);
%     [pta1, pta2, ptp1, ptp2] = lineUpCIRs(cir,cir_plus_2,INTERP_SIZE);
%     
%     poa1 = poa1/max(abs(poa1));
%     poa2 = poa2/max(abs(poa2));
%     pta1 = pta1/max(abs(pta1));
%     pta2 = pta2/max(abs(pta2));
%     angle_error_cand(1) = mod((ptp2 + ptp1) / 2 - pop2 + pi,2*pi) - pi;
%     angle_error_cand(2) = mod((ptp2 + ptp1) / 2 - pop2 + 2*pi,2*pi) - pi;
%     angle_diff_cand(1) = (ptp2 + ptp1) / 2;
%     angle_diff_cand(2) = (ptp2 + ptp1) / 2 + pi;
%     [expected_phase_angle_error(jj), min_idx] = min(abs(angle_error_cand));
%     
%     diff_plus_one(:,jj) = (pta1+poa1)/2-poa2*exp(1i*pop2)*exp(-1i*angle_diff_cand(min_idx));
%     diff_plus_two(:,jj) = pta2-pta1;
%     diff_angle_one(jj) = pop2-pop1;
%     diff_angle_two(jj) = ptp2-ptp1;
%     phase_corrections(jj,:) = [pop1, pop2, ptp1, ptp2];
%     above_thresh = find(abs(diff_plus_one(:,jj)) > max(abs(diff_plus_one(:,jj)))*TOA_THRESH);
%     backscatter_toas(jj) = above_thresh(1);
%    
%    jj=jj+1;
end
