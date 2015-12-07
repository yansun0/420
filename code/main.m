% loads images, runs detectors, draw and display results
function main
    % load helper code
    addpath(genpath(fullfile(pwd, 'detectors')));

    clip = struct('type','img','id', 2);

    frames = load_frames(clip);
    results = run_detectors(frames, ...
        struct('clip', clip, ...
               'scene', struct('type','hist', ...        % dfd or hist
                               'threshold', 0.91), ...  % hist:(0,1)  dfd:[h,l] 
               'logo', struct('type','ncc', ...         % ncc or sift
                               'threshold', 0.75)));    % only for ncc
    save('results.mat', 'results');
%     load('results.mat');

%                                'threshold', [5,2]), ... % hist:(0,1)  dfd:[h,l]
%                                'threshold', 0.91), ...  % hist:(0,1)  dfd:[h,l] 
    show_results(results, clip);
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
        network = get_network(options.clip);
        switch options.logo.type
            case 'sift'
                [logo_results,logo_pos] = detect_logo_sift(frames,network);
            case 'ncc'
                [logo_results,logo_pos] = detect_logo_ncc(frames,network, ...
                                                          options.logo.threshold);            
        end    
    end
    fprintf('-> done\n');   
    
    % face detection was preprocessed, and saved as .mat files
    fprintf('running -- face detector\n');
    [face_tracks, num_faces] = load_face_detection(options.clip);
    
    results = struct('scene', scene_results, ...
                     'logo', struct('here',logo_results,'pos',logo_pos), ...
                     'face', struct('tracks',face_tracks,'num',num_faces));
end


% load images into struct
% fieldnames: 'frame1', 'frame2', ..., 'frame{n}'
function result = load_frames(clip)    
    switch clip.type
        case 'img'
            CLIP_DIR = sprintf('../clips/imgs/%d', clip.id);
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
            vid = get_video(clip.id);
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

function network_name = get_network(clip)
    network_name = '';
    switch clip.type
        case 'vid'
            switch clip.id
                case 1
                    network_name = 'abc';
                case 2
                    network_name = 'cnn';
                case 3
                    network_name = 'fox';
            end
        case 'img'
            switch clip.id
                case 1
                    network_name = 'nbc';
                case 2
                    network_name = 'clevver';
                case 3
                    network_name = 'flicks';
            end
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


function [results, num_tracks] = load_face_detection(clip)
    CLIP_DIR = sprintf('../clips/imgs/%d-tracks', clip.id);
    CODE_DIR = '../../../code';
    
    cd(CLIP_DIR);
    features_files = dir('*.mat');
    all_tracks = struct;
    frame_num = 0;
    id_base = 0;
    for i = 1:length(features_files)
        % expected var here `gender_paths`
        % 3D: [xleft,ytop,xright,ybottom,id,score,gender] x npath
        load(features_files(i).name);

        % process the tracks
        num_frames = size(gender_paths,1);
        num_tracks = size(gender_paths,3);
        for j = 1:num_frames
            tracks = zeros(num_tracks,6);
            for k = 1:num_tracks
                x = gender_paths(j,1,k);
                y = gender_paths(j,2,k);
                w = gender_paths(j,3,k) - gender_paths(j,1,k);
                h = gender_paths(j,4,k) - gender_paths(j,2,k);
                id = id_base + k;
                gender = gender_paths(j,7,k);
                tracks(k,:) = [x y w h id gender];
            end
            frame_num = frame_num + 1;
            all_tracks = setfield(all_tracks, sprintf('frame%d', frame_num), tracks); %#ok<SFLD>
        end
        id_base = id_base + num_tracks;
    end
    cd(CODE_DIR);
    
    results = all_tracks;
    num_tracks = id_base;
end


function show_results(results, clip)
    fprintf('rendering output\n');

    cd('../results/');
    out_vid = VideoWriter(sprintf('%s-%d.mp4', clip.type, clip.id), 'MPEG-4');
    out_vid.Quality = 100;

    switch clip.type
        case 'img'
            out_vid.FrameRate = 8;
            open(out_vid);
            
            % set up scene results
            results = setfield(results, 'scene', [0;results.scene]);
            scene_num = 1;
            prev_frame_scene = 0;
            
            % set up colors for face tracking
            colors = zeros(results.face.num, 3);
            for i = 1:size(colors,1)
                colors(i,:) = rand(1,3);
            end
            
            f = figure('Visible','off','Units', 'pixels');
            
            frames = load_frames(clip);
            FIRST_FRAME = 1;
            LAST_FRAME = numel(fieldnames(frames));            
            for i = FIRST_FRAME:LAST_FRAME
                % get each frame
                fprintf('   frame %d\n',i);
                frame_id = sprintf('frame%d',i);
                frame = frames.(frame_id);
                imshow(frame);
                hold on;
                
                % output the scene change
                if results.scene(i) && ~prev_frame_scene
                    fprintf('    SHOT CHANGED\n');
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
                
                % output face detection
                face_detections = results.face.tracks.(frame_id);
                for j = 1:size(face_detections,1)
                    face = face_detections(j,:);
                    face_pos = face(1:4);
                    face_id = face(5);
                    face_gender = face(6);
                    if ~sum(face_pos)
                        continue;
                    end
                    
                    color = colors(face_id,:);
                    rectangle('Position',face_pos,'EdgeColor',color,'LineWidth',2);
                    gender = 'Female';
                    if ~face_gender
                        gender = 'Male';
                    end
                    text(face(1)+5,face(2)+15,gender,'Color',color, ...
                         'FontSize',18,'FontWeight','bold');
                end
                
                hold off;
                
                % save the frame into the video
                F = getframe(f);
                [out_frame, ~] = frame2im(F);
                writeVideo(out_vid,out_frame);
            end

        case 'vid'
            vid = get_video(clip.id);
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
