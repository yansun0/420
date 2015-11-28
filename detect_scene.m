% load helper code
CLIP_DIR = './clip_2/';
CODE_DIR = '../';
IMG_SIZE = [100 100];
NUM_BLOCKS = 5;
BLOCK_SIZE = IMG_SIZE / NUM_BLOCKS;

% setup images
cd(CLIP_DIR);
img_files = dir('*.jpg');
imgs = struct;
for i = 1:length(img_files)
    img = rgb2gray(imread(img_files(i).name));
    imgs = setfield(imgs, sprintf('img%d', i), img); %#ok<SFLD>
end
FIRST_IMG = 1;
LAST_IMG = i;
cd(CODE_DIR);

% detection
D = zeros(LAST_IMG-1,1);
E = D;
F = D;
for i = FIRST_IMG:LAST_IMG-1
    img_cur = imresize(imgs.(sprintf('img%d',i)), IMG_SIZE);
    img_next = imresize(imgs.(sprintf('img%d',i+1)), IMG_SIZE);
    
    displacements = zeros(NUM_BLOCKS, NUM_BLOCKS, 2);
    for n = 1:NUM_BLOCKS
        for m = 1:NUM_BLOCKS
            x = (n - 1) * BLOCK_SIZE(1);
            y = (m - 1) * BLOCK_SIZE(2);
            w = BLOCK_SIZE(1);
            h = BLOCK_SIZE(2);
            block = imcrop(img_cur,[x, y, w, h]);
            NCC = normxcorr2(block, img_next);
            [y_maxs, x_maxs] = find(NCC==max(NCC(:)));
            dist_x = x_maxs - size(block,2) - x;
            dist_y = y_maxs - size(block,1) - y;
            dist = sqrt(dist_x.^2 + dist_y.^2);
            best_max = find(dist==min(dist));
            displacements(n, m, :) = [x_maxs(best_max)-size(block,2)-x, ...
                                      y_maxs(best_max)-size(block,1)-y];
                                  
        end
    end
    d_x = displacements(:,:,1);
    d_y = displacements(:,:,2);
    D(i) = pdist2(d_x(:)', d_y(:)');
    E(i) = sqrt(mean(d_x(:))^2 + mean(d_y(:))^2);
    
    d_x = colfilt(displacements(:,:,1), [5 5], 'sliding', @mode);
    d_y = colfilt(displacements(:,:,2), [5 5], 'sliding', @mode);
    F(i) = pdist2(d_x(:)', d_y(:)');
end
