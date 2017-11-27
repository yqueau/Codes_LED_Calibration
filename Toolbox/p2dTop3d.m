function points3d = p2dTop3d(plan,pixels,IM)
% Code written by Tom Lucas during his internship at IRIT

    pixels(:,3) = 1;
    points = pixels(:,[2,1,3])/IM;
    n = plan(2,:);
    numerateur = dot(n,plan(1,:));
    points3d = bsxfun(@times,(numerateur./sum(bsxfun(@times,points,n),2)),points);
end
