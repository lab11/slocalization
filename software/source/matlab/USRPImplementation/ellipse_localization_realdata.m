anchor_coordinates = [...
    1.683, 1.496, 1.445;...
    1.695, 0.779, 1.442;...
    3.722, 2.542, 1.463;...
    3.008, 2.549, 1.446;...
    3.844, 0.895, 1.973;...
    3.354, 0.387, 2.026];

combinations = [
    1, 4;...
    1, 6;...
    3, 2;...
    5, 2;...
    5, 4];

delta_ranges = [
    1.47,...
    1.37,...
    0.85,...
    1.29,...
    1.95];

actual_position = [2.509, 1.124, 0.614];

estimated_position = ellipse_localization(anchor_coordinates, combinations.', delta_ranges);

position_error = sqrt(sum((estimated_position-actual_position).^2));
