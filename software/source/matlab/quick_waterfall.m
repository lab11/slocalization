for ii=1:3
for jj=1:3
subplot(3,3,ii+(jj-1)*3);
imagesc(cirs(rx_antenna_idxs == ii & tx_antenna_idxs == jj,:))
%plot(rxpaccs(rx_antenna_idxs == ii & tx_antenna_idxs == jj))
end
end

