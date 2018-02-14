function calc_tdoas(dist)

% n.b. 29.9758 from the direct CIR measurement, which I'm going to say is also
% a testament to the quality of my laser range finding / setup skills
rx30 = [      0, -.3615, 1.455];
tx30 = [      0,  .3615, 1.455];
rx20 = [29.9758,  .3615, 1.455];
tx20 = [29.9758, -.3615, 1.455];
tag  = [   dist,      0, 0.323];

ofile = fopen(['times/', num2str(dist), 'm.dat'], 'w');

if dist < 10
  diststr = ['0', num2str(dist)];
else
  diststr = num2str(dist);
end

% cirs is ( cir ; direct,backscatter ; sample )
load(['256hz_exp_noPN_30m_', diststr, 'm/20_tx/cirs_192.168.30.15.mat'], 'cirs', 'samples');
cirs20tx = cirs;
load(['256hz_exp_noPN_30m_', diststr, 'm/30_tx/cirs_192.168.20.14.mat'], 'cirs', 'samples');
cirs30tx = cirs;

threshs = .2:.1:.6;
for sample_idx = 1:length(samples)
  fprintf(ofile, '%f\t', samples(sample_idx)/1250);
  for thres = threshs
    direct = cirs20tx(:,1,sample_idx);
    backscatter = cirs20tx(:,2,sample_idx);
    [tdoa20tx,confidence20tx] = compute_tdoa(direct, backscatter, thres);

    direct = cirs30tx(:,1,sample_idx);
    backscatter = cirs30tx(:,2,sample_idx);
    [tdoa30tx,confidence30tx] = compute_tdoa(direct, backscatter, thres);

    %%choose the better, deals with nulls and such
    actual20tx = sum((tx20-tag).^2)^.5 + sum((rx30-tag).^2)^.5 - sum((tx20-rx30).^2)^.5;
    actual30tx = sum((tx30-tag).^2)^.5 + sum((rx20-tag).^2)^.5 - sum((tx30-rx20).^2)^.5;
    %tdoa = min(abs(tdoa20tx-actual20tx), abs(tdoa30tx-actual30tx));

    %good = (abs(tdoa20tx-actual20tx) < 1) || (abs(tdoa30tx-actual30tx) < 1);
    %fprintf(ofile, '%f %d\t', tdoa, good);

    acc = 5;
    good20tx = abs(tdoa20tx-actual20tx) <= acc;
    good30tx = abs(tdoa30tx-actual30tx) <= acc;

    fprintf(ofile, '%f %d\t%f %d\t', tdoa20tx, good20tx, tdoa30tx, good30tx);
  end

  fprintf(ofile, '%f\t%f\t', confidence20tx, confidence30tx);
  fprintf(ofile, '\n');
end

fclose(ofile);
