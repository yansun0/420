function [results, pos] = detect_logo_ncc(frames, network, threshold)
    results = [];
    pos = [];
    logo = load_logo(network);

    FIRST_FRAME = 1;
    LAST_FRAME = numel(fieldnames(frames));

    for i = FIRST_FRAME:LAST_FRAME
        frame = frames.(sprintf('frame%d',i));
        logo_gray = im2single(rgb2gray(logo));
        frame_gray = im2single(rgb2gray(frame));
        
        NCC = normxcorr2(logo_gray, frame_gray);
        logo_score = max(NCC(:));
        [y_peaks, x_peaks] = find(NCC==max(NCC(:)));
        y = y_peaks(1);
        x = x_peaks(1);

        fprintf('frame %d -> score %f\n', i, logo_score);
        if logo_score > threshold
            results = [results; 1]; %#ok<AGROW>
            logo_pos = get_logo_box(x,y,size(logo));
            pos = [pos; logo_pos]; %#ok<AGROW>
%             imshow(frame);
%             hold on;
%             rectangle('Position',logo_pos);
%             hold off;
        else
            results = [results; 0]; %#ok<AGROW>
            pos = [pos; [0 0 0 0]]; %#ok<AGROW>
        end
    end
        
end


function logo = load_logo(name)
    cd('./detectors/logo/logos_ncc');
    logo = imread(sprintf('%s.png',name));
    cd('../../../');
end


function logo_box = get_logo_box(x, y, logo_size)
    PADDING = 5;
    height = logo_size(1);
    width = logo_size(2);
    logo_box = [x - width - PADDING, ...
                y - height - PADDING, ...
                width + 2*PADDING, ...
                height + 2*PADDING];
end
