function ret = quick_image(gold_corrs_full, gold_idx, time_offset)

for ii=1:3
for jj=1:3
subplot(3,3,ii+(jj-1)*3);
imagesc(squeeze(abs(gold_corrs_full(ii,jj,gold_idx,time_offset,:,:))))
end
end
