% loads images, runs detectors, draw and display results
function main
    % load helper code
    addpath(genpath(fullfile(pwd, 'detectors')));

    clip = load_imgs(1);
    
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
    run_detectors(clip, struct('logo','sift','network','nbc'));

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
% fieldnames: 'img1', 'img2', ..., 'img{n}'
function result = load_imgs(clip_num)
    CLIP_DIR = sprintf('../clip_%d', clip_num);
    CODE_DIR = '../code/';
    
    cd(CLIP_DIR);
    img_files = dir('*.jpg');
    imgs = struct;
    for i = 1:length(img_files)
        img = imread(img_files(i).name);
        imgs = setfield(imgs, sprintf('img%d', i), img); %#ok<SFLD>
    end
    cd(CODE_DIR);    

    result = imgs;
end
