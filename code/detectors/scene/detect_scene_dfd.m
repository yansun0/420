function results = detect_scene_dfd(frames)
    IMG_SIZE = [100 100];
    NUM_BLOCKS = 5;
    BLOCK_SIZE = IMG_SIZE / NUM_BLOCKS;
    FIRST_FRAME = 1;
    LAST_FRAME = numel(fieldnames(frames));

    D = zeros(LAST_FRAME-1,1);
    for i = FIRST_FRAME:LAST_FRAME-1
        img_cur = imresize(rgb2gray(frames.(sprintf('frame%d',i))), IMG_SIZE);
        img_next = imresize(rgb2gray(frames.(sprintf('frame%d',i+1))), IMG_SIZE);

        dists = zeros(NUM_BLOCKS, NUM_BLOCKS, 2);
        for n = 1:NUM_BLOCKS
            for m = 1:NUM_BLOCKS
                % divide current frame into blocks
                x = (n - 1) * BLOCK_SIZE(1);
                y = (m - 1) * BLOCK_SIZE(2);
                w = BLOCK_SIZE(1);
                h = BLOCK_SIZE(2);
                block = imcrop(img_cur,[x, y, w, h]);

                % find match for the blocks of cur frame in next frame
                % might get multiple peaks -- take the one of least dist
                NCC = normxcorr2(block, img_next);
                [y_peaks, x_peaks] = find(NCC==max(NCC(:)));
                dist_x = x_peaks - size(block,2) - x;
                dist_y = y_peaks - size(block,1) - y;
                dist = sqrt(dist_x.^2 + dist_y.^2);
                best_max = find(dist==min(dist));
                
                dists(n, m, :) = [x_peaks(best_max)-size(block,2)-x, ...
                                  y_peaks(best_max)-size(block,1)-y];
            end
        end
        dists_x = dists(:,:,1);
        dists_y = dists(:,:,2);
        % D(i) = pdist2(dists_x(:)', dists_y(:)');
        % D(i) = sqrt(mean(dists_x(:))^2 + mean(dists_y(:))^2);
        dists_x = colfilt(dists_x, [5 5], 'sliding', @mode);
        dists_y = colfilt(dists_y, [5 5], 'sliding', @mode);
        D(i) = pdist2(dists_x(:)', dists_y(:)');
    end
    
    results = filter_results(D);
end

% turn raw scene values into 0, 1
% where 0 = continution of the previous scene
%       1 = new scene
function results = filter_results(scene_vals_raw)
    mu = mean(scene_vals_raw);
    sigma = std(scene_vals_raw);
    top_vals = sort(scene_vals_raw, 'descend');
    thresh_high = min(mu + 5*sigma, mean(top_vals(1:3,:)));
    thresh_low = min(mu + 2*sigma, mean(top_vals(1:3,:)));

    % idea: high threshold + low threshold, canny like
    scenes_val = scene_vals_raw>thresh_low & scene_vals_raw<thresh_high;
    scenes_val = scenes_val + 2*(scene_vals_raw>=thresh_high);

    scene_val_filtered = zeros(size(scenes_val));
    linked = 0;
    for i = 1:size(scenes_val, 1)
        scene_val = scenes_val(i,1);
        % if linked == 0 and scene != 2 -> 0
        % if linked == 1 and scene == 1 -> 1
        % if scene == 2 -> 1
        linked = (linked && scene_val>0) || (scene_val==2);
        scene_val_filtered(i) = linked;
    end
    
    results = scene_val_filtered;
end