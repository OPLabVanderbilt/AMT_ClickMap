function page_idx = GetClickablePageIndex(image_path)
	files = dir(image_path);
	files = { files.name };

	is_image     = cellfun(@(s) ~isempty(regexp(s, '\.(png|jpe?g|tiff?|gif)$', 'once')), files);
	is_trial     = cellfun(@(s) ~isempty(regexp(s, '^trial-[0-9]+[_.]', 'once')), files);
	is_clickable = cellfun(@(s) ~isempty(regexp(s, 'clickable-true', 'once')), files);

	files = files(is_image & is_trial & is_clickable);

	tokens2double = @(t) str2double(t{1}{1});
	page_idx = cellfun(@(f) tokens2double(regexp(f, '^trial-([0-9]+)[_.]', 'tokens')), files);
	page_idx = sort(page_idx);
end