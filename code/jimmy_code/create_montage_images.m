FRAME_DIR = './clip_3_final_frames/';
FINAL_OUTPUT = './clip_3_final_frames/mont-%03d.jpg';
start_frame = 16;
last_frame = 290;

%%
for i = start_frame:last_frame
    im_cur = imread(fullfile(FRAME_DIR, sprintf('%03d.jpg', i)));
    im_orig = imread(fullfile(FRAME_DIR, sprintf('orig-%03d.jpg', i)));
    f = figure; imshowpair(im_cur, im_orig, 'montage');
    saveas(f, sprintf(FINAL_OUTPUT, i));
    close all;
end