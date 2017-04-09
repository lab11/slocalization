function ret = write_cir_to_file(filename, deconvolved, deconvolved_direct, cs)

LEN_TO_WRITE = 200;

cir_dists = (0:489)*.2449;
[~,which_deconvolved_idx] = max(max(abs(deconvolved(:,1,:)),[],1),[],3);

direct_cir = abs(deconvolved_direct(:,1));
tag_cir = abs(deconvolved(:,1,which_deconvolved_idx));

direct_cir = circshift(direct_cir, cs);
tag_cir = circshift(tag_cir, cs);

direct_cir = direct_cir./max(abs(direct_cir));
tag_cir = tag_cir./max(abs(tag_cir));

csvwrite(filename, [cir_dists(1:LEN_TO_WRITE).',direct_cir(1:LEN_TO_WRITE),tag_cir(1:LEN_TO_WRITE)]);
