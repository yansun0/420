function sim = get_similarity(im_cur, im_next)
	sim_red = get_similarity_color(im_cur, im_next, 1);
	sim_blue = get_similarity_color(im_cur, im_next, 2);
	sim_green = get_similarity_color(im_cur, im_next, 3);

	sim = (sim_red / 3) + (sim_blue / 3) + (sim_green / 3);
end
