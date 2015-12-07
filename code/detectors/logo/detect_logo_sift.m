function [results, pos] = detect_logo_sift(frames, network)
    run('./vlfeat/toolbox/vl_setup');

    results = [];
    pos = [];
    logo = load_logo(network);

    FIRST_FRAME = 1;
    LAST_FRAME = numel(fieldnames(frames));
    SCORE_THRESHOLD = 0;
    PADDING = 5;

    logo_gray = im2single(rgb2gray(logo));
    for i = FIRST_FRAME:LAST_FRAME
        frame = frames.(sprintf('frame%d',i));
        frame_gray = im2single(rgb2gray(frame));
        
        [score, A] = match(frame_gray,logo_gray);
        fprintf('frame %d -> score %d\n', i, score);

        if score > SCORE_THRESHOLD
            logo_im_size = size(logo_gray);
            P_edge = [ 1, 1, 0, 0, 1, 0; ...
                       0, 0, 1, 1, 0, 1; ...
                       1, logo_im_size(1), 0, 0, 1, 0; ...
                       0, 0, 1, logo_im_size(1), 0, 1; ...
                       logo_im_size(2), logo_im_size(1), 0, 0, 1, 0; ...
                       0, 0, logo_im_size(2), logo_im_size(1), 0, 1; ...
                       logo_im_size(2), 1, 0, 0, 1, 0; ...
                       0, 0, logo_im_size(2), 1, 0, 1 ];
            edges = P_edge * A;

%             figure;
%             imshow(frame);
%             hold on;
%             scatter(edges(1),edges(2),100,'r','fill');
%             scatter(edges(3),edges(4),100,'g','fill');
%             scatter(edges(7),edges(8),100,'y','fill');
%             scatter(edges(5),edges(6),100,'b','fill');
%             hold off;
            
            % top left = 1,2
            % bot left = 3,4
            % top right = 7,8
            % bot right = 5,6
            x = mean([edges(1) edges(3)]) - PADDING;
            y = mean([edges(2) edges(8)]) - PADDING;
            w = mean([edges(7) edges(5)]) - x + 2*PADDING;
            h = mean([edges(4) edges(6)]) - y + 2*PADDING;
            
            % TODO: filter logos here
            
            results = [results; 1]; %#ok<AGROW>
            pos = [pos; [x y w h]]; %#ok<AGROW>
        else
            results = [results; 0]; %#ok<AGROW>
            pos = [pos; [0 0 0 0]]; %#ok<AGROW>
        end
    end
end


function logo = load_logo(name)
    cd('./detectors/logo/logos_sift');
    logo = imread(sprintf('%s.png',name));
    cd('../../../');
end


function logos = load_logos %#ok<DEFNU>
    LOGOS_FILE_NAME = 'logos_saved.mat';
    
    cd('./detectors/logo/logos_sift');
    if exist(LOGOS_FILE_NAME, 'file') ~= 2
        logo_files = dir('*.png');
        logos_out = struct;
        for i = 1:length(logo_files)
            logo = imread(logo_files(i).name);
            logo_gray = im2single(rgb2gray(logo));
            [frames,desc] = vl_sift(logo_gray);
            logos_out = setfield(logos_out, ...
                                 strrep(logo_files(i).name,'.png',''), ...
                                 struct('im',logo, ...
                                        'im_g',logo_gray, ...
                                        'frames',frames, ...
                                        'desc',desc)); %#ok<SFLD>
        end
        logos_saved = logos_out;
        save(LOGOS_FILE_NAME, 'logos_saved');
    end
    load(LOGOS_FILE_NAME);
    cd('../../../');

    logos = logos_saved;
end


function [best_inliners, best_A] = match(frame, logo)
    % constants
    RANDSAC_TRYS = 50;
    RANDSAC_SAMPLES = 3;
    RANDSAC_THRESHOLD = 10;

    best_inliners = 0;
    best_A = [];
    
    [frame_frames,frame_desc] = vl_sift(frame);
    [logo_frames,logo_desc] = vl_sift(logo);
    [matches, ~] = vl_ubcmatch(logo_desc,frame_desc);
    
    size(matches);
    % matched something
    if size(matches, 2) > 2
        logo_frame_matches = logo_frames(1:2,matches(1,:));
        frame_frame_matches = frame_frames(1:2,matches(2,:));

        for k=1:RANDSAC_TRYS
            % grab 3 points
            sample_indices = vl_colsubset(1:size(matches,2), RANDSAC_SAMPLES);
            i1 = sample_indices(1);
            i2 = sample_indices(2);
            i3 = sample_indices(3);
            P = [ logo_frame_matches(1,i1),logo_frame_matches(2,i1),0,0,1,0; ...
                  0,0,logo_frame_matches(1,i1),logo_frame_matches(2,i1),0,1; ...
                  logo_frame_matches(1,i2),logo_frame_matches(2,i2),0,0,1,0; ...
                  0,0,logo_frame_matches(1,i2),logo_frame_matches(2,i2),0,1; ...
                  logo_frame_matches(1,i3),logo_frame_matches(2,i3),0,0,1,0; ...
                  0,0,logo_frame_matches(1,i3),logo_frame_matches(2,i3),0,1 ];
            P_prime = [ frame_frame_matches(1,i1); ...
                        frame_frame_matches(2,i1); ...
                        frame_frame_matches(1,i2); ...
                        frame_frame_matches(2,i2); ...
                        frame_frame_matches(1,i3); ...
                        frame_frame_matches(2,i3) ];
            A = inv(P) * P_prime;

            % transformation logo
            T = [ A(1), A(2), A(5); ...
                  A(3), A(4), A(6) ];
            logo_frame_matches(3,:) = 1;
            logo_frame_trans = T * logo_frame_matches; % 2x3 * 3xN

            % find inliners
            d_x = logo_frame_trans(1,:) - frame_frame_matches(1,:);
            d_y = logo_frame_trans(2,:) - frame_frame_matches(2,:);
            inliners = sum((d_x.*d_x + d_y.*d_y)<RANDSAC_THRESHOLD*RANDSAC_THRESHOLD);

            if inliners > best_inliners
                best_inliners = inliners;
                best_A = A;
            end
        end         
    end
end
