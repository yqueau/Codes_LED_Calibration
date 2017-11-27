function [F, J] = reprojection_error_isotropic(I,N,X,mu,do_refine_S,var)

	S = var(1:3); % Position
	Phi = var(4:6); % Intensity
	th = var(7);
	ph = var(8);
	Dir = [cos(th)*cos(ph) sin(th)*cos(ph) sin(ph)];
	
	X_minus_Xs = bsxfun(@minus,S',X); % Vector from surface to source
	norm_X_minus_Xs = sqrt((sum(X_minus_Xs.^2,2))); % Distance from source to surface

	anis = (sum(bsxfun(@times,Dir,-X_minus_Xs),2)).^mu;
	shading = sum(N.*X_minus_Xs,2);
	shading_anis = shading.*anis;
	norme = 1./(norm_X_minus_Xs.^(3+mu));
	
	F = [I(:,1)-Phi(1)*shading_anis.*norme;... % red channel
		I(:,2)-Phi(2)*shading_anis.*norme;... % green channel
		I(:,3)-Phi(3)*shading_anis.*norme]; % blue channel
		
	J = zeros(3*length(shading),8);
	J(1:length(shading),4) = -shading_anis.*norme;	
	J(length(shading)+1:2*length(shading),5) = -shading_anis.*norme;	
	J(2*length(shading)+1:3*length(shading),6) = -shading_anis.*norme;	
	
	if(do_refine_S)
		d_shading_x = N(:,1);
		d_shading_y = N(:,2);
		d_shading_z = N(:,3);
		d_anis_x = -mu*(sum(bsxfun(@times,Dir,-X_minus_Xs),2)).^(mu-1).*Dir(1);
		d_anis_y = -mu*(sum(bsxfun(@times,Dir,-X_minus_Xs),2)).^(mu-1).*Dir(2);
		d_anis_z = -mu*(sum(bsxfun(@times,Dir,-X_minus_Xs),2)).^(mu-1).*Dir(3);
		d_shading_anis_x = d_shading_x.*anis+shading.*d_anis_x;
		d_shading_anis_y = d_shading_y.*anis+shading.*d_anis_y;
		d_shading_anis_z = d_shading_z.*anis+shading.*d_anis_z;
		d_norm_x = -(3+mu)*(S(1)-X(:,1))./(norm_X_minus_Xs.^(5+mu)); 
		d_norm_y = -(3+mu)*(S(2)-X(:,2))./(norm_X_minus_Xs.^(5+mu)); 
		d_norm_z = -(3+mu)*(S(3)-X(:,3))./(norm_X_minus_Xs.^(5+mu)); 
		
		J(1:length(shading),1) = -Phi(1)*(d_shading_anis_x.*norme+shading_anis.*d_norm_x);	
		J(1:length(shading),2) = -Phi(1)*(d_shading_anis_y.*norme+shading_anis.*d_norm_y);	
		J(1:length(shading),3) = -Phi(1)*(d_shading_anis_z.*norme+shading_anis.*d_norm_z);
		J(length(shading)+1:2*length(shading),1) = -Phi(2)*(d_shading_anis_x.*norme+shading_anis.*d_norm_x);	
		J(length(shading)+1:2*length(shading),2) = -Phi(2)*(d_shading_anis_y.*norme+shading_anis.*d_norm_y);	
		J(length(shading)+1:2*length(shading),3) = -Phi(2)*(d_shading_anis_z.*norme+shading_anis.*d_norm_z);	
		J(2*length(shading)+1:3*length(shading),1) = -Phi(3)*(d_shading_anis_x.*norme+shading_anis.*d_norm_x);	
		J(2*length(shading)+1:3*length(shading),2) = -Phi(3)*(d_shading_anis_y.*norme+shading_anis.*d_norm_y);	
		J(2*length(shading)+1:3*length(shading),3) = -Phi(3)*(d_shading_anis_z.*norme+shading_anis.*d_norm_z);	
	end
	
	
	Dir_th =  [-sin(th)*cos(ph) cos(th)*cos(ph) 0];	
	Dir_ph =  [-cos(th)*sin(ph) -sin(th)*sin(ph) cos(ph)];	
	d_anis_th = shading.*norme.*mu.*((sum(bsxfun(@times,Dir,-X_minus_Xs),2)).^(mu-1)).*(sum(bsxfun(@times,Dir_th,-X_minus_Xs),2));
	d_anis_ph = shading.*norme.*mu.*((sum(bsxfun(@times,Dir,-X_minus_Xs),2)).^(mu-1)).*(sum(bsxfun(@times,Dir_ph,-X_minus_Xs),2));
	
	J(1:length(shading),7) = -Phi(1)*d_anis_th;	
	J(1:length(shading),8) = -Phi(1)*d_anis_ph;
	J(length(shading)+1:2*length(shading),7) = -Phi(2)*d_anis_th;
	J(length(shading)+1:2*length(shading),8) = -Phi(2)*d_anis_ph;
	J(2*length(shading)+1:3*length(shading),7) = -Phi(3)*d_anis_th;
	J(2*length(shading)+1:3*length(shading),8) = -Phi(3)*d_anis_ph;
end

