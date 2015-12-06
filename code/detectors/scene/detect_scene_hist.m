function results = detect_scene_hist(frames)
    FIRST_FRAME = 1;
    LAST_FRAME = numel(fieldnames(frames));

	scene_num = 1;
    scene_vals = zeros(LAST_FRAME-1,1);
	for i = FIRST_FRAME:LAST_FRAME-1
        img_cur = frames.(sprintf('img%d',i));
        img_next = frames.(sprintf('img%d',i+1));
	    sim = get_similarity(img_cur, img_next);
		fprintf('Similarity of frame %d to %d: %.4f\n', i, i + 1, sim);
        
		if sim < 0.91
            scene_num = scene_num + 1;
            fprintf('------------------------------------\n');
            fprintf('------------------------------------\n');
            fprintf('NEW SCENE %d of frame %d to %d: %.4f\n', scene_num, i, i + 1, sim);
            fprintf('------------------------------------\n');
            fprintf('------------------------------------\n');
            scene_vals(i) = 1;
        else
            scene_vals(i) = 0;
        end
    end
    
    results = scene_vals;
end


function sim = get_similarity(im_cur, im_next)
	sim_red = get_similarity_color(im_cur, im_next, 1);
	sim_blue = get_similarity_color(im_cur, im_next, 2);
	sim_green = get_similarity_color(im_cur, im_next, 3);

	sim = (sim_red / 3) + (sim_blue / 3) + (sim_green / 3);
end


function sim_color = get_similarity_color(im_cur, im_next, color_index)
	[pixel_count_cur_color, ~] = imhist(im_cur(:, : , color_index));
	[pixel_count_next_color, ~] = imhist(im_next(:, : , color_index));
	
	sim_color = dot(pixel_count_cur_color, pixel_count_next_color) ./ ...
		sqrt(dot(pixel_count_cur_color, pixel_count_cur_color) ...
			.* dot(pixel_count_next_color, pixel_count_next_color));
end