% load helper code
CLIP_1_DIR = './clip_1/';
CODE_DIR = './clip_1/';
IMG_SIZE = [100 100];
NUM_BLOCKS = 5;
BLOCK_SIZE = IMG_SIZE / NUM_BLOCKS;

% setup images
cd(CLIP_1_DIR);
img_files = dir('*.jpg');
imgs = struct;
for i = 1:length(img_files)
    img = rgb2gray(imread(img_files(i).name));
    imgs = setfield(imgs, sprintf('img%d', i), img); %#ok<SFLD>
end
FIRST_IMG = 1;
LAST_IMG = i;

% detection
D = zeros(LAST_IMG-1,1);
for i = FIRST_IMG:LAST_IMG-1
    img_cur = imresize(imgs.(sprintf('img%d',i)), IMG_SIZE);
    img_next = imresize(imgs.(sprintf('img%d',i+1)), IMG_SIZE);
    
    displacements = zeros(NUM_BLOCKS, NUM_BLOCKS, 2);
    for n = 1:NUM_BLOCKS
        for m = 1:NUM_BLOCKS
            x = (n - 1) * BLOCK_SIZE(1);
            y = (m - 1) * BLOCK_SIZE(2);
            w = BLOCK_SIZE(1)d;
            h = BLOCK_SIZE(2);
            block = imcrop(img_cur,[x, y, w, h]);
            NCC = normxcorr2(block, img_next);
            [y_max, x_max] = find(NCC==max(NCC(:)));
            displacements(n, m, :) = [x_max-size(block,2)-x
                                      y_max-size(block,1)-y];
        end
    end
    d_x = displacements(:,:,1);
    d_y = displacements(:,:,2);
    D(i) = sqrt(mean(d_x(:))^2 + mean(d_y(:))^2);
end
