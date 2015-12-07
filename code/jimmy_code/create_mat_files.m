data_folder = 'instagram_images';
	
folder = strcat('./', data_folder);
addpath(genpath(folder));
	
start_index = 1;
end_index = 257;

all_images = [];
for i = end_index:-1:start_index
	im = imread(sprintf('image_%03d.jpg', i));
	im = double(rgb2gray(im));
	im = imresize(im, [32 32]);
	im = im(:);
	all_images = [all_images, im];
end

save('female_dpm_crop', 'all_images');
