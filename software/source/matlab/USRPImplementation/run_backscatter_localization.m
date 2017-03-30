function ret = run_backscatter_localization(exp_dir_name, actual_position)

anchor_coordinates = [...
    1.007, 1.468, 1.436;...
    1.038, 0.749, 1.447;...
    3.720, 2.570, 1.469;...
    3.014, 2.547, 1.452;...
    3.885, 0.929, 1.985;...
    3.371, 0.409, 2.020];

combinations = [
    1, 4;...
    1, 6;...
    3, 2;...
    3, 6;...
    5, 2;...
    5, 4];

%10 to 20
delta_ranges = zeros(6,1);
load([exp_dir_name,'/decon_10_to_20.mat']);
backscatter_cir = extract_best_backscatter_cir(deconvolved);
delta_ranges(1) = compute_tdoa(deconvolved_direct(:,1), backscatter_cir);

%10 to 30
load([exp_dir_name,'/decon_10_to_30.mat']);
backscatter_cir = extract_best_backscatter_cir(deconvolved);
delta_ranges(2) = compute_tdoa(deconvolved_direct(:,1), backscatter_cir);

%20 to 10
load([exp_dir_name,'/decon_20_to_10.mat']);
backscatter_cir = extract_best_backscatter_cir(deconvolved);
delta_ranges(3) = compute_tdoa(deconvolved_direct(:,1), backscatter_cir);

%20 to 30
load([exp_dir_name,'/decon_20_to_30.mat']);
backscatter_cir = extract_best_backscatter_cir(deconvolved);
delta_ranges(4) = compute_tdoa(deconvolved_direct(:,1), backscatter_cir);

%30 to 10
load([exp_dir_name,'/decon_30_to_10.mat']);
backscatter_cir = extract_best_backscatter_cir(deconvolved);
delta_ranges(5) = compute_tdoa(deconvolved_direct(:,1), backscatter_cir);

%30 to 20
load([exp_dir_name,'/decon_30_to_20.mat']);
backscatter_cir = extract_best_backscatter_cir(deconvolved);
delta_ranges(6) = compute_tdoa(deconvolved_direct(:,1), backscatter_cir);

expected_delta_ranges = zeros(6,1);
for ii=1:6
    expected_direct_range = sqrt(sum((anchor_coordinates(combinations(ii,1),:)-anchor_coordinates(combinations(ii,2),:)).^2));
    expected_tag_range_one = sqrt(sum((anchor_coordinates(combinations(ii,1),:)-actual_position).^2));
    expected_tag_range_two = sqrt(sum((anchor_coordinates(combinations(ii,2),:)-actual_position).^2));

    expected_delta_ranges(ii) = (expected_tag_range_one + expected_tag_range_two) - expected_direct_range;
end

%Invalid delta ranges: Those which are too big (>10 meters) or too small (<0 meters)
%NOTE: This is dependent on room size!
invalid_delta_ranges = (delta_ranges > 10) | (delta_ranges < 0);

delta_ranges = delta_ranges(~invalid_delta_ranges);
expected_delta_ranges = expected_delta_ranges(~invalid_delta_ranges);
combinations = combinations(~invalid_delta_ranges,:);

expected_delta_ranges
delta_ranges

ret = ellipse_localization(anchor_coordinates, combinations, delta_ranges);
