clear all
close all
fileName = 'result.ply';
[vertex colors]= read_ply(fileName);

[plane, P, inliers]  = ransacfitplane(vertex(:,1:3)',0.2,1);
normalAbs = plane(1)^2+plane(2)^2+plane(3)^2;

% scatter3(vertex(inliers,1),vertex(inliers,2),vertex(inliers,3),'.');
outliers = vertex;
outliers(inliers,:)=[];
isInlier = zeros(size(vertex,1),1);
isInlier(inliers)=1;

% scatter3(outliers(:,1),outliers(:,2),outliers(:,3),'.');

f = fopen('frames.bin','r');
frameID = fread(f,inf,'int32');
vertex = [vertex frameID];
surfacePoints = [];

f = fopen('cameraMats.bin','r');
cameraMats =  fread(f,inf,'float');
cameraMats = reshape(cameraMats,4,4,[]);

cameraPos = [];
for i = 1:size(cameraMats,3)
    cameraMats(:,:,i) = inv(cameraMats(:,:,i));
    RT = cameraMats(1:3,1:3,i);
    T = cameraMats(1:3,4,i);
    C= RT*T;
    direction = RT*[0 0 1]';
    cameraPos = [cameraPos  [C ;direction]];
end


frameNum = 1;
%hold on
%axis vis3d
for i=min(frameID):max(frameID)
    
    frameInliers = find(isInlier==1 & vertex(:,4)==i);
    if (length(frameInliers)>1)
        numVerticesInliersForFrame=size(frameInliers,1);
        numVerticesForFrame=size(vertex(vertex(:,4)==i),1);
        planeRepInliers=repmat(plane(1:3),1,numVerticesInliersForFrame);
        planeRep=repmat(plane(1:3),1,numVerticesForFrame);
        
        pointToSurfaceVec =- vertex(frameInliers,1:3) + repmat(cameraPos(1:3,frameNum),1,numVerticesInliersForFrame)';
        alpha = -( sum(vertex(frameInliers,1:3).*planeRepInliers',2)+plane(4)) ./sum((planeRepInliers.*pointToSurfaceVec'),1)';
        closeSurfacePoints = vertex(frameInliers,1:3) + repmat(alpha,1,3).*pointToSurfaceVec;
        
        % plot3(vertex(frameInliers,1),vertex(frameInliers,2),vertex(frameInliers,3),'r.');
        % plot3(closeSurfacePoints(:,1),closeSurfacePoints(:,2),closeSurfacePoints(:,3),'b.');
        %pause
        r0=mean(vertex(frameInliers,1:3));
        r1=mean(closeSurfacePoints);
        a=bsxfun(@minus,vertex(frameInliers,1:3),r0);
        a1=bsxfun(@minus,closeSurfacePoints,r1);
        [~,~,V1]=svd(a,0);
        [~,~,V]=svd(a1,0);
        r = vrrotvec(a,a1);
        m = vrrotvec2mat(r);
        for j=0:numVerticesForFrame-1
            vertex(find(vertex(:,4)==i,1,'first')+j,1:3) =   vertex(find(vertex(:,4)==i,1,'first')+j,1:3) + (m*(vertex(find(vertex(:,4)==i,1,'first')+j,1:3))')';
        end
%         hold on
%         axis vis3d
%         plot3(vertex(:,1),vertex(:,2),vertex(:,3),'r.');
%         plot3(closeSurfacePoints(:,1),closeSurfacePoints(:,2),closeSurfacePoints(:,3),'g.');
%         drawnow
%         pause(0.5)

%         pointToSurfaceVec =- vertex(frameInliers,1:3) + repmat(cameraPos(1:3,frameNum),1,numVerticesInliersForFrame)';
%         alpha = -( sum(vertex(frameInliers,1:3).*planeRepInliers',2)+plane(4)) ./sum((planeRepInliers.*pointToSurfaceVec'),1)';
%         closeSurfacePoints = vertex(frameInliers,1:3) + repmat(alpha,1,3).*pointToSurfaceVec;
%         avgDist = sum(sum(sign(vertex(frameInliers,1:3)).*(closeSurfacePoints - vertex(frameInliers,1:3)).^2,2))/numVerticesInliersForFrame;
%            distanceInliersFromSurface= sum([r0 1]'.*plane);
%         for j=0:numVerticesForFrame-1
%             vertex(find(vertex(:,4)==i,1,'first')+j,1:3) =   vertex(find(vertex(:,4)==i,1,'first')+j,1:3) - avgDist*(vertex(find(vertex(:,4)==i,1,'first')+j,1:3)- cameraPos(1:3,frameNum)')  ; %(TR*vertex(find(vertex(:,4)==i,1,'first')+j,1:3)' + TT)';
%         end
    end
%     surfacePoints = [surfacePoints; closeSurfacePoints];
    
    frameNum = frameNum+1;
end

% hold on
% plot3(vertex(inliers,1),vertex(inliers,2),vertex(inliers,3),'r.');
% plot3(surfacePoints(:,1),surfacePoints(:,2),surfacePoints(:,3),'g.');
% plot3(vertex(~isInlier,1),vertex(~isInlier,2),vertex(~isInlier,3),'b.');
% quiver3(cameraPos(1,:),cameraPos(2,:),cameraPos(3,:),cameraPos(4,:),cameraPos(5,:),cameraPos(6,:));



f = fopen('out.ply','w+');
colors(isnan(vertex(:,1)),:)=[];

vertex(isnan(vertex(:,1)),:)=[];
fprintf(f,'ply\nformat binary_little_endian 1.0\nelement vertex %d\nproperty float x\nproperty float y\nproperty float z\nproperty uchar red\nproperty uchar green\nproperty uchar blue\nend_header\n',size(vertex,1));
for i = 1:size(vertex,1)
    fwrite(f,single(vertex(i,1:3)'),'single');
    fwrite(f,char(colors(i,:)'),'uchar');
end

