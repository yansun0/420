% loads images, runs detectors, draw and display results
function main
    % load helper code
%     addpath(genpath(fullfile(pwd, 'detectors')));
% 
%     frames = load_frames('img', 1);
% 
%     results = run_detectors(frames, ...
%         struct('scene','dfd', ... % dfd or hist
%                'logo','ncc', ...  % ncc or sift
%                'network','nbc')); % has to match broadcast
%            
%     save('results.mat', 'results');
    load('results.mat');

    show_results(results, 'img', 1);
end


% runs detectors specified on the images, and
function results = run_detectors(frames, options)

    % frames=[f1 f2 f3 f4] -> scene_results=[f1f2 f2f3 f3f4]
    % ex. if there's a scene change f2->f3 then scene_results=[0 1 0]
    scene_results = [];
    if isfield(options, 'scene')
        switch options.scene
            case 'hist'
                scene_results = detect_scene_hist(frames);
            case 'dfd'
                scene_results = detect_scene_dfd(frames);
        end
    end
    
    % frame=[f1 f2 f3 f4] ->
    %     logo_results=[l1 l2 l3]
    %     logo_pos = [[x1,y1,w1,h1] [x2,y2,w2,h2] ...]
    logo_results = [];
    logo_pos = [];
    if isfield(options, 'logo')
        switch options.logo
            case 'sift'
                [logo_results, logo_pos] = detect_logo_sift(frames,options.network);
            case 'ncc'
                [logo_results, logo_pos] = detect_logo_ncc(frames,options.network);                
        end    
    end
    
    
    % TODO: add face here
    
    
    results = struct('scene', scene_results, ...
                     'logo', struct('here', logo_results, 'pos', logo_pos) ...
                     );
end


% load images into struct
% fieldnames: 'frame1', 'frame2', ..., 'frame{n}'
function result = load_frames(clip_type, clip_id)
    switch clip_type
        case 'img'
            CLIP_DIR = sprintf('../clips/imgs/%d', clip_id);
            CODE_DIR = '../../../code/';

            cd(CLIP_DIR);
            frames_files = dir('*.jpg');
            frames = struct;
            for i = 1:length(frames_files)
                frame = imread(frames_files(i).name);
                frames = setfield(frames, sprintf('frame%d', i), frame); %#ok<SFLD>
            end
            cd(CODE_DIR);    

            result = frames;
            
        case 'vid'
            vid = get_video(clip_id);
            frames = struct;
            time = 0;
            while hasFrame(vid)
                if time > vid.Duration
                    break;
                end
                vid.CurrentTime = time;
                frame = readFrame(vid);
                frames = setfield(frames, sprintf('frame%d', time), frame); %#ok<SFLD>                    
                time = time + 1;
            end
            
            result = frames;
    end

end

function vid = get_video(clip_id)
    CLIP_DIR = '../clips/videos/';
    CODE_DIR = '../../code/';

    cd(CLIP_DIR);
    vid_name = '';
    switch clip_id
        case 1
            vid_name = 'abc';
        case 2
            vid_name = 'cnn';
        case 3
            vid_name = 'fox';
    end
    vid = VideoReader(sprintf('%s.mp4', vid_name));
    cd(CODE_DIR);
end


function show_results(results, clip_type, clip_id)
    switch clip_type
        case 'img'
            out_vid = VideoWriter(sprintf('%s-%d.mp4', clip_type, clip_id), 'MPEG-4');
            out_vid.Quality = 100;
            out_vid.FrameRate = 8;
            open(out_vid);
            
            % set up scene results
            results = setfield(results, 'scene', [0;results.scene]);
            scene_num = 1;
            
            f = figure('Visible','off','Units', 'pixels');
            
            frames = load_frames(clip_type, clip_id);
            FIRST_FRAME = 1;
            LAST_FRAME = numel(fieldnames(frames));            
            for i = FIRST_FRAME:LAST_FRAME
                % get each frame
                fprintf('frame %d\n',i);
                frame = frames.(sprintf('frame%d',i));
                imshow(frame);
                hold on;
                
                % output the scene change
                if results.scene(i)
                    % TODO: check there isn't going to be a sequence of 1s
                    scene_num = scene_num+1;
                end
                text(10, 15, sprintf('SCENE %d', scene_num), ...
                    'Color','white','FontSize',18,'FontWeight','bold');
                
                % output the logo
                logo_pos = results.logo.pos(i,:);
                if results.logo.here(i) && ...
                    logo_pos(3) > 0 && logo_pos(4) > 0
                    rectangle('Position',logo_pos,'EdgeColor','r','LineWidth',2);
                end
                
                hold off;
                
                % save the frame into the video
                F = getframe(f);
                [out_frame, ~] = frame2im(F);
                writeVideo(out_vid,out_frame);
            end
            close(out_vid);

        case 'vid'
            vid = get_video(clip_id);
            out_vid = VideoWriter(sprintf('%s-%d.mp4', clip_type, clip_id), 'MPEG-4');
            out_vid.Quality = 100;
            out_vid.FrameRate = vid.FrameRate;
            open(out_vid);

            cur_time = -1;
            end_time = size(results.logo.pos, 1);
            cur_logo_result = struct;
            f = figure('Visible','off','Units', 'pixels');
            while hasFrame(vid)
                % get the second data
                fprintf('time %f\n',vid.CurrentTime);
                if floor(vid.CurrentTime) > cur_time
                    cur_time = floor(vid.CurrentTime);
                    cur_time_corrected = cur_time + 1;
                    if cur_time_corrected > end_time
                        size(results.logo.here);
                    end
                    i = min(cur_time_corrected, end_time);
                    cur_logo_result = struct('here', results.logo.here(i), ...
                                             'pos',  results.logo.pos(i,:));
                end

                % create a new frame for the video
                frame = readFrame(vid);
                imshow(frame);
                hold on;
                
                % output the scene change
                
                % output the logo
                if cur_logo_result.here
                    if cur_logo_result.pos(3) > 0 && cur_logo_result.pos(4) > 0
                        rectangle('Position',cur_logo_result.pos,'EdgeColor','r','LineWidth',2);
                    else
                        size(cur_logo_result);
                    end
                end
                
                hold off;
                
                % save the frame into the video
                F = getframe(f);
                [out_frame, ~] = frame2im(F);
                writeVideo(out_vid,out_frame);
            end
            close(out_vid);
    end
end

% 
%     % show results
%     % |results.scene| = |imgs| - 1 always
%     i = 1;
%     continued = 0;
%     while i < size(results.scene,1) + 1
%         figure;
%         if results.scene(i)
%             imshow(clip.(sprintf('img%d', i)));
%             continued = 1;
%         elseif continued
%             imshow(clip.(sprintf('img%d', i)));
%             continued = 0;
%         else
%             continued = 0;
%         end            
%         i = i + 1;
%     end
