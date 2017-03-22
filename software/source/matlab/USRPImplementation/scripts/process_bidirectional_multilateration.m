[deconvolved , deconvolved_direct]= bandstitching('256hz_exp7/header_192.168.10.13.csv','256hz_exp7/data_192.168.10.13.dat','cal_data_redo2/cal_header_30_to_10.csv','cal_data_redo2/cal_data_30_to_10.dat');
save -mat decon_30_to_10.mat deconvolved deconvolved_direct
[deconvolved, deconvolved_direct] = bandstitching('256hz_exp7/header_192.168.20.14.csv','256hz_exp7/data_192.168.20.14.dat','cal_data_redo2/cal_header_10_to_20.csv','cal_data_redo2/cal_data_10_to_20.dat');
save -mat decon_10_to_20.mat deconvolved deconvolved_direct
[deconvolved, deconvolved_direct] = bandstitching('256hz_exp7/header_192.168.30.15.csv','256hz_exp7/data_192.168.30.15.dat','cal_data_redo2/cal_header_20_to_30.csv','cal_data_redo2/cal_data_20_to_30.dat');
save -mat decon_20_to_30.mat deconvolved deconvolved_direct
[deconvolved, deconvolved_direct] = bandstitching('256hz_exp8/header_192.168.10.13.csv','256hz_exp8/data_192.168.10.13.dat','cal_data_redo2/cal_header_20_to_10.csv','cal_data_redo2/cal_data_20_to_10.dat');
save -mat decon_20_to_10.mat deconvolved deconvolved_direct
[deconvolved, deconvolved_direct] = bandstitching('256hz_exp8/header_192.168.20.14.csv','256hz_exp8/data_192.168.20.14.dat','cal_data_redo2/cal_header_30_to_20.csv','cal_data_redo2/cal_data_30_to_20.dat');
save -mat decon_30_to_20.mat deconvolved deconvolved_direct
[deconvolved, deconvolved_direct] = bandstitching('256hz_exp8/header_192.168.30.15.csv','256hz_exp8/data_192.168.30.15.dat','cal_data_redo2/cal_header_10_to_30.csv','cal_data_redo2/cal_data_10_to_30.dat');
save -mat decon_10_to_30.mat deconvolved deconvolved_direct
