function area = compute_area(dets)
   area = (dets(:, 3) - dets(:, 1) + 1).* (dets(:, 4) - dets(:, 2) + 1);
end