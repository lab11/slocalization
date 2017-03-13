function err = ellipse_localization_objective(cand_position, anchor_positions, combinations, delta_ranges)

%Assumption: anchor_positions(1,:) is the position of the transmitter.  All others are receivers

%Objective function: Minimize error of location estimate given delta ranges and anchor positions
err = 0;
for ii=1:size(combinations,1)
    anchor_to_anchor_range = sqrt(sum((anchor_positions(combinations(ii,1),:)-anchor_positions(combinations(ii,2),:)).^2));
    anchor_to_tag_range_one = sqrt(sum((anchor_positions(combinations(ii,1),:)-cand_position).^2));
    anchor_to_tag_range_two = sqrt(sum((anchor_positions(combinations(ii,2),:)-cand_position).^2));
    expected_delta_range = anchor_to_tag_range_one + anchor_to_tag_range_two - anchor_to_anchor_range;
    err = err + (expected_delta_range - delta_ranges(ii)).^2;
end
