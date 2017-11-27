clear
close all

addpath('Toolbox');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAMETERS TO SET

% Calib data
images_folder = 'Data4/'; % Folder containing the png images of the checkerboard
squareSize = 30; % Size of each square in mm 

% What we do
lighting_model = 0; % 0: directional, 1: isotropic near point source, 2: anisotropic near point source
do_camera_calibration = 1; % Do intrinsics estimation or not (if not, please load the structures "cameraParams" and "imageFileNames" returned by Matlab's toolbox)
do_correct_cos4alpha = 1; % Correct for cos^4(alpha) attenuation or not (attenuation at image borders)
do_refine_S = 1; % For near source only: refine source position or not

% Tunable param
thr = 2; % A checkerboard pixel is labelled "white" if its brightness is superior to thr times the median brightness of the checkerboard 

% For near-sources, anisotropy parameter and rough position must be pre-calibrated
S = [20;-120; 420]; % for near sources only : initial position of the source in mm, wrt camera (measured manually, or by triangulation using reflective spheres) - set to [0;0;0] to put the source at camera center - In this demo the LED is ahead of the camera (S(3)>0), on its left (S(1)<0) and above (S(2)<0)
theta_12 = pi/3; % for near anisotropic sources only : theta_12 is the angle such that the intensity of the emitted light is half that of the intensity in the principal direction. Usually this angle is provided by the LED manufacturer. 

% Note: manually estimated rough position values S for the provided datasets: 
% [-170 -40 550] for Data1 (left, center, ahead of camera)
% [-130 -130 450] for Data2 (left, above, ahead of camera)
% [-150 30 450] for Data3 (left, below, ahead of camera)
% [20 -120 420] for Data4 (center, above, ahead of camera)
% [10 100 400] for Data5 (center, below, ahead of camera)
% [170 -140 440] for Data6 (right, above, ahead of camera)
% [170 30 460] for Data7 (right, center, ahead of camera)
% [170 -70 510] for Data7 (right, below, ahead of camera)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CAMERA CALIBRATION USING MATLAB CV TOOLBOX
if(do_camera_calibration)
	[imageFileNames,cameraParams] = camCalib(images_folder,squareSize);
end

% View reprojection errors
h1=figure; showReprojectionErrors(cameraParams, 'BarGraph');

% Visualize pattern locations
h2=figure; showExtrinsics(cameraParams, 'CameraCentric'); 
hold on

% Save intrinsic matrix for future
K = transpose(cameraParams.IntrinsicMatrix);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COS^4(ALPHA) COMPENSATION 
[nrows,ncols,nchannels] = size(imread(imageFileNames{1}));
if(do_correct_cos4alpha)
	ff = mean([K(1,1),K(2,2)]);
	[xx,yy] = meshgrid(1:ncols,1:nrows);
	xx = xx-K(1,3);
	yy = yy-K(2,3);
	cos4a = (ff./sqrt(xx.^2+yy.^2+ff^2)).^4;
	
	% Visualize correction pattern
	h3 = figure;
	imagesc(cos4a);
	axis image
	axis off
	colorbar
	title('All images will be divided pointwise by this map');
else
	cos4a = ones(nrows,ncols);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PREPARE DATA FOR LIGHT CALIBRATION
nb_images = length(imageFileNames);

% Planar representation of the checkerboard
planes = get_planes(cameraParams); % planes(1,:,i) is a 3D point in the i-th checkerboard, and planes(2,:,i) is a normal vector to it

% Full list of positions, normals and intensities of useful checkerboard points wrt camera
X = []; % Nx3 - List of positions
N = []; % Nx3 - List of normals 
I = []; % N x 5 - List of pixel coordinates + RGB values

for i=1:nb_images
	% Read image
	I_i = bsxfun(@rdivide,double(imread(imageFileNames{i})),cos4a);
	% Segment "white cases" based on thresholding
	[RGB, ind] = get_white_cases(I_i,cameraParams,i,cameraParams.RotationMatrices,cameraParams.TranslationVectors,thr);
	I = [I;RGB];
	X = [X;p2dTop3d(planes(:,:,i),RGB,transpose(K))];
	N = [N;repmat(sign(-planes(2,3,i))*planes(2,:,i),length(RGB),1)];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LIGHT CALIBRATION - MAIN STUFF :)
if(lighting_model == 0) % Directional light
	[S,int,Phi] = svds(pinv(N)*I(:,3:5),1);
	if(Phi(1) <0)
		Phi = -Phi;
		S = -S;
	end
	Phi = int*Phi;
	x0 = [S;Phi(1);Phi(2);Phi(3)]; % Initial position and intensities 
	options = optimoptions('lsqnonlin','Jacobian','on','Display','iter','Algorithm','levenberg-marquardt','ScaleProblem','Jacobian','TolFun', 1e-12, 'TolX', 1e-12,'MaxIter',100,'DerivativeCheck','off');
	x1  = lsqnonlin(@(var) (reprojection_error_directional(I(:,3:5),N,var)),x0,[],[],options);
	norm_S = norm(x1(1:3));
	S = x1(1:3)./norm_S;
	Phi = x1(4:6).*norm_S;	
	Dir = []; % No principal direction here since directional
	mu = []; % No anisotropy here since isotropic
	disp(sprintf('Estimated lighting direction S: %.3f %.3f %.3f',S(1),S(2),S(3)));
	disp(sprintf('Estimated RGB intensity Phi: %.3f %.3f %.3f',Phi(1),Phi(2),Phi(3)));

	% Show the directional light as a colored diamond (color = RGB intensity) with an arrow showing direction
	figure(h2)
	plot3(-100,100,0,'d','MarkerSize',15,'MarkerEdgeColor','k','LineWidth',1,'MarkerFaceColor',Phi./norm(Phi));
	quiver3(-100,100,0,-S(1),-S(3),-S(2),100,'Linewidth',2,'Color','b','MaxHeadSize',5);
	view(0,90)
	drawnow
else
	X_minus_Xs = bsxfun(@minus,X,S'); % Vector from source to surface
	norm_X_minus_Xs = sqrt((sum(X_minus_Xs.^2,2))); % Distance from source to surface
	shading = sum(-N.*X_minus_Xs./norm_X_minus_Xs,2); % Shading: normal to surface times normalized lighting vector
	normalized_shading = shading./(norm_X_minus_Xs.^2); % Shading divided by squared source-surface distance
	if(lighting_model==1) % Isotropic near source
		Phi(1) = sum(normalized_shading.*I(:,3))./sum(normalized_shading.^2); % Source intensity in red channel
		Phi(2) = sum(normalized_shading.*I(:,4))./sum(normalized_shading.^2); % Source intensity in green channel
		Phi(3) = sum(normalized_shading.*I(:,5))./sum(normalized_shading.^2); % Source intensity in blue channel
		options = optimoptions('lsqnonlin','Jacobian','on','Display','iter','Algorithm','levenberg-marquardt','ScaleProblem','Jacobian','TolFun', 1e-12, 'TolX', 1e-12,'MaxIter',100,'DerivativeCheck','off');
		x0 = [S;Phi(1);Phi(2);Phi(3)]; % Initial position and intensities 
		x1  = lsqnonlin(@(var) (reprojection_error_isotropic(I(:,3:5),N,X,do_refine_S,var)),x0,[],[],options);
		S = x1(1:3);
		Phi = x1(4:6);
		Dir = []; % No principal direction here since isotropic
		mu = []; % No anisotropy here since isotropic
		disp(sprintf('Estimated position S: %.3f %.3f %.3f',S(1),S(2),S(3)));
		disp(sprintf('Estimated RGB intensity Phi: %.3f %.3f %.3f',Phi(1),Phi(2),Phi(3)));
		
		% Show the LED as a colored diamond (color = RGB intensity) 
		figure(h2)
		plot3(S(1),S(3),S(2),'d','MarkerSize',15,'MarkerEdgeColor','k','LineWidth',1,'MarkerFaceColor',Phi./norm(Phi));
		view(0,90)
		drawnow
	elseif(lighting_model==2)
		mu = -log(2)./log(cos(theta_12));
		[Dir,int,Phi] = svds(pinv(X_minus_Xs./norm_X_minus_Xs)*((bsxfun(@rdivide,I(:,3:5),normalized_shading)).^(1/mu)),1);
		Phi = int*Phi;
		if(Phi(1) <0)
			Phi = -Phi;
			Dir = -Dir;
		end
		Phi = Phi.^mu;
		options = optimoptions('lsqnonlin','Jacobian','on','Display','iter','Algorithm','levenberg-marquardt','ScaleProblem','Jacobian','TolFun', 1e-12, 'TolX', 1e-12,'MaxIter',100,'DerivativeCheck','off');
		[th,ph] = cart2sph(Dir(1),Dir(2),Dir(3));
		x0 = [S;Phi(1);Phi(2);Phi(3);th;ph]; % Initial position, intensities and orientations
		x1  = lsqnonlin(@(var) (reprojection_error_anisotropic(I(:,3:5),N,X,mu,do_refine_S,var)),x0,[],[],options);
		S = x1(1:3);
		Phi = x1(4:6);
		th = x1(7);
		ph = x1(8);
		Dir = [cos(th)*cos(ph);sin(th)*cos(ph);sin(ph)];
		disp(sprintf('Estimated position S: %.3f %.3f %.3f',S(1),S(2),S(3)));
		disp(sprintf('Estimated RGB intensity Phi: %.3f %.3f %.3f',Phi(1),Phi(2),Phi(3)));
		disp(sprintf('Estimated orientation Dir: %.3f %.3f %.3f',Dir(1),Dir(2),Dir(3)));

		% Show the LED as a colored diamond (color = RGB intensity) with an arrow showing direction
		figure(h2)
		plot3(S(1),S(3),S(2),'d','MarkerSize',15,'MarkerEdgeColor','k','LineWidth',1,'MarkerFaceColor',Phi./norm(Phi));
		quiver3(S(1),S(3),S(2),Dir(1),Dir(3),Dir(2),100,'Linewidth',2,'Color','b','MaxHeadSize',5);
		view(0,90)
		drawnow

	end		
end

save('LED_calib_result.mat','S','Phi','Dir','mu','K')
