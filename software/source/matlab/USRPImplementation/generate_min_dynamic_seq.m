function best_seq = generate_min_dynamic_seq(seq_len)

NUM_TO_SEARCH = 1e6;

blah = [zeros(1,NUM_TO_SEARCH);exp(1i*rand(seq_len-1,NUM_TO_SEARCH)*2*pi)];
blah2 = ifft(blah,[],1);
blah3 = max(abs(blah2),[],1);
[~,best_idx] = min(blah3);
best_seq = blah2(:,best_idx);
