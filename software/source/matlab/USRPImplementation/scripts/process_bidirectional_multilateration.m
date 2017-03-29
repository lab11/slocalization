function ret = process_bidirectional_multilateration(experiment_folder_name, cal_folder_name)

[deconvolved , deconvolved_direct]= bandstitching([experiment_folder_name,'/minus_2/header_192.168.10.13.csv'],[experiment_folder_name,'/minus_2/data_192.168.10.13.dat'],[cal_folder_name,'/cal_header_30_to_10.csv'],[cal_folder_name,'/cal_data_30_to_10.dat']);
save -mat decon_30_to_10.mat deconvolved deconvolved_direct
[deconvolved, deconvolved_direct] = bandstitching([experiment_folder_name,'/minus_2/header_192.168.20.14.csv'],[experiment_folder_name,'/minus_2/data_192.168.20.14.dat'],[cal_folder_name,'/cal_header_10_to_20.csv'],[cal_folder_name,'/cal_data_10_to_20.dat']);
save -mat decon_10_to_20.mat deconvolved deconvolved_direct
[deconvolved, deconvolved_direct] = bandstitching([experiment_folder_name,'/minus_2/header_192.168.30.15.csv'],[experiment_folder_name,'/minus_2/data_192.168.30.15.dat'],[cal_folder_name,'/cal_header_20_to_30.csv'],[cal_folder_name,'/cal_data_20_to_30.dat']);
save -mat decon_20_to_30.mat deconvolved deconvolved_direct
[deconvolved, deconvolved_direct] = bandstitching([experiment_folder_name,'/minus_1/header_192.168.10.13.csv'],[experiment_folder_name,'/minus_1/data_192.168.10.13.dat'],[cal_folder_name,'/cal_header_20_to_10.csv'],[cal_folder_name,'/cal_data_20_to_10.dat']);
save -mat decon_20_to_10.mat deconvolved deconvolved_direct
[deconvolved, deconvolved_direct] = bandstitching([experiment_folder_name,'/minus_1/header_192.168.20.14.csv'],[experiment_folder_name,'/minus_1/data_192.168.20.14.dat'],[cal_folder_name,'/cal_header_30_to_20.csv'],[cal_folder_name,'/cal_data_30_to_20.dat']);
save -mat decon_30_to_20.mat deconvolved deconvolved_direct
[deconvolved, deconvolved_direct] = bandstitching([experiment_folder_name,'/minus_1/header_192.168.30.15.csv'],[experiment_folder_name,'/minus_1/data_192.168.30.15.dat'],[cal_folder_name,'/cal_header_10_to_30.csv'],[cal_folder_name,'/cal_data_10_to_30.dat']);
save -mat decon_10_to_30.mat deconvolved deconvolved_direct
