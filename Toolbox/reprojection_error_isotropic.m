function [F, J] = reprojection_error_isotropic(I,N,X,do_refine_S,var)

	S = var(1:3); % Position
	Phi = var(4:6); % Intensity
	
	X_minus_Xs = bsxfun(@minus,S',X); % Vector from surface to source
	norm_X_minus_Xs = sqrt((sum(X_minus_Xs.^2,2))); % Distance from source to surface
	shading = sum(N.*X_minus_Xs./norm_X_minus_Xs,2); % Shading: normal to surface times normalized lighting vector
	normalized_shading = shading./(norm_X_minus_Xs.^2); % Shading divided by squared source-surface distance
	
	F = [I(:,1)-Phi(1)*normalized_shading;... % red channel
		I(:,2)-Phi(2)*normalized_shading;... % green channel
		I(:,3)-Phi(3)*normalized_shading]; % blue channel
		
	J = zeros(3*length(normalized_shading),6);
	J(1:length(normalized_shading),4) = -normalized_shading;	
	J(length(normalized_shading)+1:2*length(normalized_shading),5) = -normalized_shading;	
	J(2*length(normalized_shading)+1:3*length(normalized_shading),6) = -normalized_shading;	

	if(do_refine_S)
		shading = sum(N.*X_minus_Xs,2);
		d_shading_x = N(:,1);
		d_shading_y = N(:,2);
		d_shading_z = N(:,3);
		norme = 1./(norm_X_minus_Xs.^3);
		d_norm_x = -3*(S(1)-X(:,1))./(norm_X_minus_Xs.^5); 
		d_norm_y = -3*(S(2)-X(:,2))./(norm_X_minus_Xs.^5); 
		d_norm_z = -3*(S(3)-X(:,3))./(norm_X_minus_Xs.^5); 
		
		J(1:length(normalized_shading),1) = -Phi(1)*(d_shading_x.*norme+shading.*d_norm_x);	
		J(1:length(normalized_shading),2) = -Phi(1)*(d_shading_y.*norme+shading.*d_norm_y);	
		J(1:length(normalized_shading),3) = -Phi(1)*(d_shading_z.*norme+shading.*d_norm_z);	
		J(length(normalized_shading)+1:2*length(normalized_shading),1) = -Phi(2)*(d_shading_x.*norme+shading.*d_norm_x);	
		J(length(normalized_shading)+1:2*length(normalized_shading),2) = -Phi(2)*(d_shading_y.*norme+shading.*d_norm_y);	
		J(length(normalized_shading)+1:2*length(normalized_shading),3) = -Phi(2)*(d_shading_z.*norme+shading.*d_norm_z);	
		J(2*length(normalized_shading)+1:3*length(normalized_shading),1) = -Phi(3)*(d_shading_x.*norme+shading.*d_norm_x);	
		J(2*length(normalized_shading)+1:3*length(normalized_shading),2) = -Phi(3)*(d_shading_y.*norme+shading.*d_norm_y);	
		J(2*length(normalized_shading)+1:3*length(normalized_shading),3) = -Phi(3)*(d_shading_z.*norme+shading.*d_norm_z);	
	end
end

