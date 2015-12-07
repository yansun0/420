function [im, best_boxes] = get_boxes(filename, model)
	model.vis = @() visualizemodel(model, ...
					  1:2:length(model.rules{model.start}));
	[im, best_boxes] = test(filename, model, -1.0);


function [im, best_boxes] = test(imname, model, thresh)
	cls = model.class;
	fprintf('///// Running demo for %s /////\n\n', cls);

	% load and display image
	im = imread(imname);
	clf;

	% detect objects
	[ds, bs] = imgdetect(im, model, thresh);
	top = nms(ds, 0.3);
	clf;

	fprintf('\n');
	
	best_boxes = ds(top, :);
	% This is to threshold the boxes such that we only take similarities greater than 0.5
	if size(best_boxes, 1) > 0
		best_boxes = best_boxes(best_boxes(:, 6) > 0.5, :);
	end
