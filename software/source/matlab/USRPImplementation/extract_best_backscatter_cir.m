function ret = extract_best_backscatter_cir(deconvolved)

metric = squeeze(max(abs(deconvolved),[],1));

%For now we hack in an invalidation of a majority of indices...
metric(1:46) = 0;
metric(64:end) = 0;

[~,best_backscatter_cir_idx] = max(metric);
ret = deconvolved(:,1,best_backscatter_cir_idx);
