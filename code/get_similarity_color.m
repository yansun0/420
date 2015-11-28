function sim_color = get_similarity_color(im_cur, im_next, color_index)
	[pixel_count_cur_color, grayLevels] = imhist(im_cur(:, : , color_index));
	[pixel_count_next_color, grayLevels] = imhist(im_next(:, : , color_index));
	
	sim_color = dot(pixel_count_cur_color, pixel_count_next_color) ./ ...
		sqrt(dot(pixel_count_cur_color, pixel_count_cur_color) ...
			.* dot(pixel_count_next_color, pixel_count_next_color));
end
