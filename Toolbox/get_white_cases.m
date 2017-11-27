function [points_blancs ind] = segmentation_carres(I,cameraParams,indice,RotMat,TransMat,percent)
% Code written by Tom Lucas during his internship at IRIT

R = double(I(:,:,1));
V = double(I(:,:,2));
B = double(I(:,:,3));

[nb_lignes,nb_colonnes,~] = size(I);
I_gray = rgb2gray(double(I)/255);

points = [cameraParams.WorldPoints, zeros(size(cameraParams.WorldPoints,1),1),ones(size(cameraParams.WorldPoints,1),1)]*[RotMat(:,:,indice);TransMat(indice,:)]*cameraParams.IntrinsicMatrix;
points=points./repmat(points(:,3),[1 3]);

H = convhull(points(:,1),points(:,2)); 

mask = zeros(nb_lignes,nb_colonnes);
[x,y]=meshgrid(ceil(min(points(H,1))):floor(max(points(H,1))),ceil(min(points(H,2))):floor(max(points(H,2))));
in = inpolygon(x(:),y(:),points(H,1),points(H,2));
M = [y(:),x(:)];
M = M(in,:);
indices = sub2ind(size(mask),M(:,1),M(:,2));

moyenne_blanc = median(I_gray(indices));
pixels_blancs = (I_gray(indices)>percent*moyenne_blanc);
ind = indices(pixels_blancs);
[J,I] = ind2sub(size(I_gray),ind);

points_blancs = [J,I,R(indices(pixels_blancs)),V(indices(pixels_blancs)),B(indices(pixels_blancs))];



figure(457)
imagesc(I_gray)
hold on
plot(points(:,1),points(:,2),'or')
plot(points(H,1),points(H,2),'-b')
axis equal
colormap gray
plot(I,J,'dy','MarkerSize',1);
hold off
axis image
axis off
title(sprintf('Points detected as white in checkerboard %d',indice))
drawnow
pause(0.1)

end







