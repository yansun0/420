% loads images, runs detectors, draw and display results
function main
    % load helper code
    addpath(genpath(fullfile(pwd, 'detectors')));

    frames = load_frames('img', 3);

    results = run_detectors(frames, ...
        struct('scene', struct('type','dfd', ...        % dfd or hist
                               'threshold', 0.91), ...  % hist:(0,1)  dfd:[h,l] 
               'logo', struct('type','ncc', ...         % ncc or sift
                               'network','flicks', ...  % see below
                               'threshold', 0.75)));    % only for ncc  
%                                'threshold', [5,2]), ... % hist:(0,1)  dfd:[h,l]
%                                'threshold', 0.91), ...  % hist:(0,1)  dfd:[h,l] 
    % network vals:
    %   imgs: 1 = nbc
    %         2 = clevver
    %         3 = flicks
    %   vids: 1 = abc
    %         2 = cnn
    %         3 = fox

    save('results.mat', 'results');
%     load('results.mat');

    show_results(results, 'img', 3);
end


% runs detectors specified on the images, and
function results = run_detectors(frames, options)

    % frames=[f1 f2 f3 f4] -> scene_results=[f1f2 f2f3 f3f4]
    % ex. if there's a scene change f2->f3 then scene_results=[0 1 0]
    fprintf('running -- scene detector\n');
    scene_results = [];
    if isfield(options, 'scene')
        switch options.scene.type
            case 'hist'
                scene_results = detect_scene_hist(frames,options.scene.threshold);
            case 'dfd'
                scene_results = detect_scene_dfd(frames,options.scene.threshold);
        end
    end
    fprintf('-> done\n');
    
    % frame=[f1 f2 f3 f4] ->
    %     logo_results=[l1 l2 l3]
    %     logo_pos = [[x1,y1,w1,h1] [x2,y2,w2,h2] ...]
    fprintf('running -- logo detector\n');
    logo_results = [];
    logo_pos = [];
    if isfield(options, 'logo')
        switch options.logo.type
            case 'sift'
                [logo_results,logo_pos] = detect_logo_sift(frames, ...
                                                           options.logo.network);
            case 'ncc'
                [logo_results,logo_pos] = detect_logo_ncc(frames, ...
                                                          options.logo.network, ...
                                                          options.logo.threshold);            
        end    
    end
    fprintf('-> done\n');
    
    
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
    fprintf('rendering output\n');

    cd('../results/');
    out_vid = VideoWriter(sprintf('%s-%d.mp4', clip_type, clip_id), 'MPEG-4');
    out_vid.Quality = 100;

    switch clip_type
        case 'img'
            out_vid.FrameRate = 8;
            open(out_vid);
            
            % set up scene results
            results = setfield(results, 'scene', [0;results.scene]);
            scene_num = 1;
            prev_frame_scene = 0;
            
            f = figure('Visible','off','Units', 'pixels');
            
            frames = load_frames(clip_type, clip_id);
            FIRST_FRAME = 1;
            LAST_FRAME = numel(fieldnames(frames));            
            for i = FIRST_FRAME:LAST_FRAME
                % get each frame
                fprintf('   frame %d\n',i);
                frame = frames.(sprintf('frame%d',i));
                imshow(frame);
                hold on;
                
                % output the scene change
                if results.scene(i) && ~prev_frame_scene
                    scene_num = scene_num+1;
                end
                prev_frame_scene = results.scene(i);
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

        case 'vid'
            vid = get_video(clip_id);
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
    end
    
    close(out_vid);
    cd('../code/');
end
