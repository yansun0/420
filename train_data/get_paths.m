function out_path = get_paths(all_features, all_images, beginning, end_index)
    %% Get the paths matrix and initialize the max path
    num_frames = end_index - beginning + 1;
    max_features = 0;
    out_path = [];
    
    %% Need paths of length 5 or more
    if end_index - beginning < 4
        out_path = [];
        return;
    end
    
    %% Loop through making sure every frame has at least 1 feature
    for i = beginning:end_index
        if (isequal(size(all_features{i}), 0) | isequal(size(all_features{i}, 1), 0))
            all_paths_after = [];
        	for j = i + 1:end_index
                if (~isequal(size(all_features{j}), 0) & ~isequal(size(all_features{j}, 1), 0))
                    fprintf('---- starting path at %d to %d\n', j, end_index);
                    all_paths_after = get_paths(all_features, all_images, j, end_index);
                    break;
                end
            end
            all_paths_before = [];
            for j = beginning:i
                if (~isequal(size(all_features{j}), 0) & ~isequal(size(all_features{j}, 1), 0))
                    fprintf('---- starting path at %d to %d \n', j, i-1);
                    all_paths_before = get_paths(all_features, all_images, j, i - 1);
                    break;
                end
            end
            out_path = cat(3, all_paths_before, all_paths_after);
            if size(out_path, 1) == 0
                out_path = [];
            end
            return;
        end

        max_features = max([size(all_features{i}, 1), max_features]);
    end 

    prev_path_max = zeros(1, size(all_features{i}, 1));
    all_path_scores = zeros(max_features, num_frames - 1);
    all_paths = zeros(max_features, num_frames - 1);
    for i = end_index - 1:-1:beginning
        dets_cur = all_features{i};
        im_cur = all_images{i};

        dets_next = all_features{i + 1};
        im_next = all_images{i + 1};
        
        sim = compute_similarity(dets_cur, dets_next, im_cur, im_next);
        repeated_previous = repmat(prev_path_max, size(sim, 1), 1);
        sim(sim > 0) = sim(sim > 0) + repeated_previous(sim > 0);
        
        actual_beginning = beginning;
        [sorted_max_sim, indices] = max(sim, [], 2);
        if (max(sorted_max_sim) < 1)
            if (num_frames - i > 4)
                actual_beginning = i + 1; 
                break;
            end
            out_path = [];
            return;
        end
        all_paths(:, i) = pad_vector(indices, max_features);
        all_path_scores(:, i) = pad_vector(sorted_max_sim, max_features);
        prev_path_max = sorted_max_sim';
    end

    [~, start_pt] = max(prev_path_max);
    j = actual_beginning;
    out_path = [start_pt];
    best_path = [];
    for i = actual_beginning:end_index - 1 
        im_next = all_images{j};
        best_box = all_features{j}(start_pt, :);
        best_path = [best_path; best_box];
        all_features{j}(start_pt, :) = [];
        start_pt = all_paths(start_pt, j);
        out_path = [out_path, start_pt];
        j = j + 1;
    end

    i = i + 1;

    im_next = all_images{j};
    best_box = all_features{j}(start_pt, :);
    best_path = [best_path; best_box];
    all_features{j}(start_pt, :) = [];
    out_path = padded_path(out_path, actual_beginning);

    all_paths_after = get_paths(all_features, all_images, beginning, end_index);
    if isstruct(all_paths_after)
        all_paths_after = all_paths_after{1};
    end
    disp(size(padded_boxes(best_path, actual_beginning)));
    out_path = cat(3, padded_boxes(best_path, actual_beginning), all_paths_after);
end

function padded_vector = pad_vector(indices, output_size)
	input_size = size(indices, 1);
	padded_vector = [indices; zeros(output_size - input_size, 1)];
end


function padded_vector = padded_path(indices, beginning)
	input_size = size(indices, 2);
    ending = 164;
	padded_vector = [zeros(1, beginning - 1), indices, zeros(1, ending - input_size - beginning + 1)];
end

function output = padded_boxes(boxes, beginning)
	num_paths = size(boxes, 1);
    ending = 164;
    box_size = 7;
	output = [zeros(beginning - 1, box_size); boxes; zeros(ending - num_paths - beginning + 1, box_size)];
end
