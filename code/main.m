% loads images, runs detectors, draw and display results
function main
    % load helper code
    addpath(genpath(fullfile(pwd, 'detectors')));

    clip = load_frames('vid', 1);
    
    % SCENE
%     results = run_detectors(clip, struct('scene','hist'));
%     results = run_detectors(clip, struct('scene','dfd'));
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
    
    % LOGO
    run_detectors(clip, struct('logo','sift','network','abc'));
%     run_detectors(clip, struct('logo','ncc','network','abc'));

end


% runs detectors specified on the images, and
function results = run_detectors(frames, options)

    % frames=[f1 f2 f3 f4 f5] -> scene_results=[f1f2 f2f3 f3f4 f4f5]
    % ex. if there's a scene change f3->f4 then scene_results=[0 0 1 0]
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
                     'logo', struct('results', logo_results, 'pos', logo_pos) ...
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
            cd(CODE_DIR);
            
            result = frames;
    end

end
