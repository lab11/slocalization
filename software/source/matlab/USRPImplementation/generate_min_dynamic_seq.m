function best_seq = generate_min_dynamic_seq(freq_amps)

NUM_TO_SEARCH = 1e6;

blah = repmat(reshape(freq_amps,[length(freq_amps),1]),[1,NUM_TO_SEARCH]);
blah = blah.*exp(1i*rand(size(blah))*2*pi);
blah2 = ifft(blah,[],1);
blah3 = max(abs(blah2),[],1);
[~,best_idx] = min(blah3);
best_seq = blah2(:,best_idx);
