function c = compute_center(dets)
	c = 0.5 * (dets(:, [1:2]) + dets(:, [3:4]));
end