test_root = 'test-files';
csv_path  = 'csv-files';
map_path  = 'clickmaps';

% select csv data files
[csv_files, path] = uigetfile(fullfile(csv_path, '*.csv'), 'MultiSelect', 'on');
if ~iscell(csv_files)
	csv_files = { csv_files };
end
n_files = length(csv_files);

% select test file path, determine clickable pages
test_path = uigetdir(test_root);
page_idx = GetClickablePageIndex(test_path);

% if you want to only see subset of pages (e.g., from trial-101 to trial-500)
%page_idx = page_idx(page_idx >= 101 & page_idx <= 500);


% figure params
paper_size = [8.5 11];  % US letter
image_pos  = [0 0 paper_size];
grid_size  = [4, 3];
n_subplots = grid_size(1) * grid_size(2);

% map file prefix
file_prefix = strcat('Map_', datestr(now(), 'yyyy-mm-dd_HH-MM-SS'));

% map params
image_size = [200, 200];
click_sd   = 1;

% variables
sbj_count  = 0;
worker_ids = {};
click_maps = [];

for f = 1:n_files
	csv_table = readtable(fullfile(csv_path, csv_files{f}));
	valid_idx = ~cellfun(@isempty, csv_table.SubmitTime);
	csv_table = csv_table(valid_idx, :);  % discard empty rows
	n_rows = size(csv_table, 1);

	[mx, my] = meshgrid(1:image_size(2), 1:image_size(1));
	mx = repmat(mx / image_size(2) * 100, [1, 1, n_rows]);
	my = repmat(my / image_size(1) * 100, [1, 1, n_rows]);

	temp_maps = zeros([image_size, n_rows]);
	for p = 1:length(page_idx)
		x_vals = csv_table.(sprintf('ClickedX%d', page_idx(p)));
		y_vals = csv_table.(sprintf('ClickedY%d', page_idx(p)));
		if isa(x_vals, 'double') && isa(y_vals, 'double')
			tx = mx - repmat(permute(x_vals, [2 3 1]), image_size);
			ty = my - repmat(permute(y_vals, [2 3 1]), image_size);
			tr = sqrt((tx .^ 2) + (ty .^ 2));
			temp_maps = temp_maps + exp(-.5 * (tr / click_sd) .^ 2);
		end
	end

	worker_ids = cat(1, worker_ids, csv_table.WorkerId);
	click_maps = cat(3, click_maps, temp_maps);
	sbj_count  = sbj_count + n_rows;
end



% plot & save click maps
for s = 1:sbj_count
	if mod(s, n_subplots) == 1
		sbj_str = sprintf('S%03d-S%03d', s, min(s + n_subplots - 1, sbj_count));
		hfig = figure('Name',       sprintf('Click Maps: %s', sbj_str), ...
			'Color',             'w', ...
			'Units',             'inches', ...
			'InnerPosition',     image_pos + [1.5 1.5 0 0], ...
			'PaperPositionMode', 'manual', ...
			'PaperUnits',        'inches', ...
			'PaperSize',         paper_size, ...
			'PaperPosition',     image_pos ...
			);
		fprintf('===== %s =====\n', sbj_str);
	end

	subplot(grid_size(1), grid_size(2), mod(s - 1, n_subplots) + 1);
	imagesc(click_maps(:, :, s));
	caxis([0, 8]);
	axis square;
	axis off;
	title(sprintf('S%03d: %s', s, worker_ids{s}), ...
			'FontSize', 10, 'FontWeight', 'normal');

	% save click maps
	if (mod(s, n_subplots) == 0) || (s == sbj_count)
		fig_file = sprintf('%s_%s.pdf', file_prefix, sbj_str);
		print(hfig, fullfile(map_path, fig_file), '-dpdf', '-r300');
	end

	% write worker ids
	if s == sbj_count
		fprintf('S%03d: %s\n', s, worker_ids{s});
		fprintf('=====================\n');
	elseif mod(s, grid_size(2)) == 0
		fprintf('S%03d: %s\n', s, worker_ids{s});
	else
		fprintf('S%03d: %s\t', s, worker_ids{s});
	end
end
