%% Modify these parameters to create the path
FRAME_DIR = '../clip_2/';
DET_DIR = './clip_2_faces/gender/';
FINAL_OUTPUT = './clip_2_final_frames/%03d.jpg';
start_frame = 187;
last_frame = 199;

all_features = {};
all_images = {};

%%
% We use j because we don't want our indices to start in like 22
j = 1;
for i = start_frame:last_frame
    im_cur = imread(fullfile(FRAME_DIR, sprintf('%03d.jpg', i)));
    % Currently only thing in mat is best_boxes
    data = load(fullfile(DET_DIR, sprintf('image_%03d_gender.mat', i)));
    dets_cur = data.best_boxes;
    
    all_features{j} = dets_cur;
    all_images{j} = im_cur;
    j = j + 1;
end
end_index = last_frame - start_frame + 1;
my_path = get_paths(all_features, all_images, 1, end_index);

num_paths = size(my_path, 3);
gender_paths = [];

% We don't want to try messing with paths that don't exist
if size(my_path, 1) > 0
    for k = 1: num_paths
        cur_path = my_path(:, :, k);
        % Paths must have the gender column
        if size(cur_path, 2) > 6
            amt_gender = sum(cur_path(cur_path(:, 1) > 0, 7));
            num_frames = size(cur_path(cur_path(:, 1) > 0, 7), 1);
            possible_gender = round(amt_gender / num_frames);
            
            % Here we are making the gender for each path consistent
            % We do this by making the gender for the path whatever the majority is
            cur_path(cur_path(:, 1) > 0, 7) = possible_gender;
        end
        gender_paths = cat(3, gender_paths, cur_path);
    end
end

% Construct the paths 
for i=1:end_index
    features_used = [];
    if size(my_path, 1) > 0
        for k = 1:num_paths
            cur_path = gender_paths(i, :, k);
            features_used = [features_used; cur_path];
        end
    end
    f = figure; showboxes(all_images{i}, features_used);
    saveas(f, sprintf(FINAL_OUTPUT, i + start_frame - 1));
    close all;
end
close all;
