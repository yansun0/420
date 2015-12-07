clear;
%data_folder = 'instagram_images/bad';
%data_folder = 'female';
data_folder = '';
input_file_format = '%04d.jpg';
output_file_format = '../../train_data/clip_3_faces/image_%03d_face%02d.jpg';
output_file_mat = '../../train_data/clip_3_faces/image_%03d';
startup;

fprintf('compiling the code...');
compile;
fprintf('done.\n\n');

load('face_final');
% addpath(genpath('../code/dpm'));

folder = strcat('../../clip_3/', data_folder);
addpath(genpath(folder));

start_index = 16;
end_index = 100;

for i = start_index:1:end_index
	[im, best_boxes] = my_demo_jimmy(sprintf(input_file_format, i), model);
	for j = 1:1:size(best_boxes, 1)
		best_box = best_boxes(j, :);
		rect = [best_box(:, 1), best_box(:, 2), best_box(:, 3) - best_box(:, 1), best_box(:, 4) - best_box(:, 2)];
		save_im = imcrop(im, rect);
		imwrite(save_im, sprintf(output_file_format, i, j));
	end
	save(sprintf(output_file_mat, i), 'best_boxes');
end
