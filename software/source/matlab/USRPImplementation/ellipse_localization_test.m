actual_tag_coordinate = [0.5,0.5,0.5];
anchor_coordinates = [0,0,0;1,0,0;0,1,0;0,0,1];

num_anchors = size(anchor_coordinates,1);
combinations = nchoosek(1:num_anchors,2);
delta_ranges = zeros(1,size(combinations,1));
for ii=1:size(combinations,1)
    anchor_to_anchor_range = sqrt(sum((anchor_coordinates(combinations(ii,1),:)-anchor_coordinates(combinations(ii,2),:)).^2));
    anchor_to_tag_range_one = sqrt(sum((anchor_coordinates(combinations(ii,1),:)-actual_tag_coordinate).^2));
    anchor_to_tag_range_two = sqrt(sum((anchor_coordinates(combinations(ii,2),:)-actual_tag_coordinate).^2));
    delta_ranges(ii) = anchor_to_tag_range_one + anchor_to_tag_range_two - anchor_to_anchor_range;
end

estimated_position = ellipse_localization(anchor_coordinates, combinations, delta_ranges);
