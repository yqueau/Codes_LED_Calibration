function [F, J] = reprojection_error_directional(I,N,var)

	S = var(1:3); % Direction
	Phi = var(4:6); % Intensity
	
	shading = sum(bsxfun(@times,N,S'),2);
	
	F = [I(:,1)-Phi(1)*shading;... % red channel
		I(:,2)-Phi(2)*shading;... % green channel
		I(:,3)-Phi(3)*shading]; % blue channel
		
	J = zeros(3*length(shading),6);
	J(1:length(shading),4) = -shading;	
	J(length(shading)+1:2*length(shading),5) = -shading;	
	J(2*length(shading)+1:3*length(shading),6) = -shading;	

		d_shading_x = N(:,1);
		d_shading_y = N(:,2);
		d_shading_z = N(:,3);
		
		J(1:length(shading),1) = -Phi(1)*(d_shading_x);	
		J(1:length(shading),2) = -Phi(1)*(d_shading_y);	
		J(1:length(shading),3) = -Phi(1)*(d_shading_z);	
		J(length(shading)+1:2*length(shading),1) = -Phi(2)*(d_shading_x);	
		J(length(shading)+1:2*length(shading),2) = -Phi(2)*(d_shading_y);	
		J(length(shading)+1:2*length(shading),3) = -Phi(2)*(d_shading_z);	
		J(2*length(shading)+1:3*length(shading),1) = -Phi(3)*(d_shading_x);	
		J(2*length(shading)+1:3*length(shading),2) = -Phi(3)*(d_shading_y);	
		J(2*length(shading)+1:3*length(shading),3) = -Phi(3)*(d_shading_z);	
	
end

