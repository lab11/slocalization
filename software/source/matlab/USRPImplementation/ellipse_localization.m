function ret = ellipse_localization(anchor_positions, combinations, delta_ranges)

fun = @(x)ellipse_localization_objective(x, anchor_positions, combinations, delta_ranges);
options = optimset('PlotFcns',@optimplotfval);

x0 = zeros(1,size(anchor_positions,2));
ret = fminsearch(fun, x0, options);
