function plans = get_planes(cameraParams)
% Code written by Tom Lucas during his internship at IRIT

	nb_images = cameraParams.NumPatterns;
	rotationMatrices = cameraParams.RotationMatrices; % Vecteurs de rotation
	translationVectors = cameraParams.TranslationVectors; % Vecteurs de translation
	points_2d = cameraParams.WorldPoints;
	points_2d(:,3,:) = 1;

	plans = zeros(2,3,nb_images);

	for boardIdx = 1:nb_images
		R = rotationMatrices(:,:,boardIdx)';
		t = translationVectors(boardIdx, :)';
		
		worldBoardCoords = bsxfun(@plus, R*points_2d', t)';
		wX = worldBoardCoords(:,1);
		wY = worldBoardCoords(:,2);
		wZ = worldBoardCoords(:,3);
		plans(:,:,boardIdx) = [wX(1),wY(1),wZ(1);...
			cross([wX(6)-wX(1),wY(6)-wY(1),wZ(6)-wZ(1)],...
			[wX(43)-wX(1),wY(43)-wY(1),wZ(43)-wZ(1)])];
		plans(2,:,boardIdx) = plans(2,:,boardIdx)/norm(plans(2,:,boardIdx));
	end

end
