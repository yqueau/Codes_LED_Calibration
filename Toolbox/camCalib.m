function [imageFileNames,cameraParams] = camCalib(images_folder,squareSize)

	% Get PNG checkerboard images stored in Data/
	images = dir(fullfile(images_folder, '*.png'));
	nb_images = length(images);
	for im = 1:nb_images
		imageFileNames{im} = fullfile(images(im).folder,images(im).name);
	end
	clear images

	% Detect checkerboards in images
	disp('Checkerboard detection');
	[imagePoints, boardSize, imagesUsed] = detectCheckerboardPoints(imageFileNames);

	% Remove unused images
	imageFileNames = imageFileNames(imagesUsed);

	% Generate world coordinates of the corners of the squares
	worldPoints = generateCheckerboardPoints(boardSize, squareSize);

	% Calibrate the camera
	disp('Calibrating camera')
	cameraParams = estimateCameraParameters(imagePoints, worldPoints, ...
		'EstimateSkew', false, 'EstimateTangentialDistortion', false, ...
		'NumRadialDistortionCoefficients', 2, 'WorldUnits', 'mm');
end
