function run_histogram_detector(clip_number)
	CLIP_1_DIR = '../clip_1';
	clip_1_start_frame = 22;
	clip_1_second_last_frame = 199;
	clip_1_format = '%03d.jpg';

	CLIP_2_DIR = '../clip_2';
	clip_2_start_frame = 65;
	clip_2_second_last_frame = 198;
	clip_2_format = '%03d.jpg';

	CLIP_3_DIR = '../clip_3';
	clip_3_start_frame = 16;
	clip_3_second_last_frame = 289;
	clip_3_format = '%04d.jpg';

	if clip_number == 1
		start_frame = clip_1_start_frame;
		second_last_frame = clip_1_second_last_frame;
		image_clip_format = clip_1_format;
		image_clip_directory = CLIP_1_DIR;
	elseif clip_number == 2
		start_frame = clip_2_start_frame;
		second_last_frame = clip_2_second_last_frame;
		image_clip_format = clip_2_format;
		image_clip_directory = CLIP_2_DIR;
	else
		start_frame = clip_3_start_frame;
		second_last_frame = clip_3_second_last_frame;
		image_clip_format = clip_3_format;
		image_clip_directory = CLIP_3_DIR;
	end

	prev_frame_change = 0;
	scene_num = 1;
	for i = start_frame:second_last_frame
	    im_cur = imread(fullfile(image_clip_directory, sprintf(image_clip_format, i)));
	    im_next = imread(fullfile(image_clip_directory, sprintf(image_clip_format, i+1)));
	    sim = get_similarity(im_cur, im_next);
		fprintf('Similarity of frame %d to %d: %.4f\n', i, i + 1, sim);
		if sim < 0.91
			if prev_frame_change < 1
				scene_num = scene_num + 1;
				prev_frame_change = 1;
				fprintf('------------------------------------\n');
				fprintf('------------------------------------\n');
				fprintf('NEW SCENE %d of frame %d to %d: %.4f\n', scene_num, i, i + 1, sim);
				fprintf('------------------------------------\n');
				fprintf('------------------------------------\n');
			end
		elseif prev_frame_change > 0
			scene_num = scene_num + 1;
			prev_frame_change = 0;
			fprintf('------------------------------------\n');
			fprintf('------------------------------------\n');
			fprintf('NEW SCENE %d of frame %d to %d: %.4f\n', scene_num, i, i + 1, sim);
			fprintf('------------------------------------\n');
			fprintf('------------------------------------\n');
		else
			prev_frame_change = 0;
		end
	end