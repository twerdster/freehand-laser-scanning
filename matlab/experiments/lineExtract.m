close all
clear all

%% initilization

margine = 150;
points = [];
Data = importdata('Data1590.csv',' ');
cameraMatrix = zeros(4,4,length(Data));
for i=1:length(Data)
   
    cameraMatrix(:,:,i) = reshape(Data(i,18:33),4,4);
    
end

% smoothing
% newCameraMatrix = cameraMatrix;
% lambda = 1;
% testVec = [1;0;0;1];
% 
% for i = 1:500
%    
% % %     t = cameraMatrix(1:3,4,i);
% %     smoothedT = (cameraMatrix(1:3,4,i-2)+cameraMatrix(1:3,4,i-1) + cameraMatrix(1:3,4,i) + cameraMatrix(1:3,4,i+1)+cameraMatrix(1:3,4,i+2))/5;
% %     
% %     quat = dcm2quat(cameraMatrix(1:3,1:3,i));
% %     prevQuat = dcm2quat(cameraMatrix(1:3,1:3,i-1));
% %     nextQuat = dcm2quat(cameraMatrix(1:3,1:3,i+1));
% %     prevQuat2 = dcm2quat(cameraMatrix(1:3,1:3,i-2));
% %     nextQuat2 = dcm2quat(cameraMatrix(1:3,1:3,i+2));
% %     
% %     
% %     quat = (prevQuat + quat + nextQuat +prevQuat2 + nextQuat2) /5;
% %     
% %     R = quat2dcm(quat);
% %     
% %     newCameraMatrix(:,:,i) = [[R ;[0 0 0]] [smoothedT;1]];
% 
% 
% newCameraMatrix(:,:,2:end-1) =(( cameraMatrix(:,:,1:end-2) + cameraMatrix(:,:,3:end) )/2 + lambda*cameraMatrix(:,:,2:end-1))/(1+lambda);
% newCameraMatrix(:,:,1) =(( cameraMatrix(:,:,2) ) + lambda*cameraMatrix(:,:,1))/(1+lambda);
% newCameraMatrix(:,:,end) =(( cameraMatrix(:,:,end-1) ) + lambda*cameraMatrix(:,:,end-1))/(1+lambda);
% residual(i)=sum(sum(sum((newCameraMatrix - cameraMatrix).^2)));
% cameraMatrix = newCameraMatrix;
% 
% end
% 
% for i=1:length(cameraMatrix)
%     hold on
%     finalVec=cameraMatrix(:,:,i)*testVec;
%     plot3(finalVec(1),finalVec(2),finalVec(3),'.');
% end
% axis image

K  = [455 , 0 ,242; 0 , 455 , 183;0,0,1];
projMatrix = reshape(Data(1,1:16),4,4);

vidObj = VideoReader('IMG_0303.MOV');
nFrames = vidObj.NumberOfFrames;


%% calibration 

for frameIdx = 1:130
   
    im = vidObj.read(frameIdx);
    im = imrotate(im,270);
    imGray = rgb2gray(im);
% imGray = im(:,:,3);



response = zeros(size(imGray));
for angle = 0:70:110
    ErxRot = imrotate(Erx,angle,'bilinear','crop');
    ElxRot = imrotate(Elx,angle,'bilinear','crop');

    
    filterlx = imfilter(double(imGray),double(ElxRot),'same');
    filterrx = imfilter(double(imGray),double(ErxRot),'same');


    filterrx(filterrx<0) =0;
    filterlx(filterlx<0) =0;
    response = max(response,min(filterlx,filterrx));
end

filter = ones(1,10);
response = conv2(response,filter);

[~ , idx ] =max(response(margine:end-margine,:),[],1);
idx = idx + margine;


result = zeros(size(imGray));
for i = 1:length(idx)
    result(idx(i),i)=255;
end
[H,T,R] = hough(result);


P  = houghpeaks(H,5,'threshold',ceil(0.3*max(H(:))));
lines = houghlines(result,T,R,P,'FillGap',5,'MinLength',7);

hold on
imshow(im,[])
pt1 = [lines(1).point1';1];
pt2 = [lines(1).point2';1];

cameraWorldPoint1 = findCameraWorldPoint([pt1(2) ;pt1(1) ;1], cameraMatrix(:,:,frameIdx) , K);
cameraWorldPoint2 = findCameraWorldPoint([pt2(2); pt2(1) ;1]  , cameraMatrix(:,:,frameIdx) , K);

points = [points ;cameraWorldPoint1' ;cameraWorldPoint2'];

line([lines(1).point1(1) lines(1).point2(1)] , [ lines(1).point1(2) lines(1).point2(2)]);

drawnow

end


numPoints = length(points);
    
points = [points ones(length(points),1)];
points(isnan(points(:,1)),:)=[];
[U,S,V] = svd(points);
surfaceCoeffs = V(:,4);


%% calibration visual test

close all
x=-0.08:0.01:0.12;
y=x;
[X,Y] = meshgrid(x,y);
Z = (surfaceCoeffs(1)*X + surfaceCoeffs(2)*Y + surfaceCoeffs(4)) ./ -surfaceCoeffs(3);
hold on
scatter3(points(:,1),points(:,2),points(:,3),5,'o')
surface(X,Y,Z);
axis vis3d


%% reconstruction

writerObj1 = VideoWriter('linePos.avi') ;
writerObj2 = VideoWriter('response.avi') ;
open(writerObj1);
open(writerObj2);
finalPoints = zeros(4,1000000);
pointIdx=1;
actualFrame =0;
numPointsTotal = 0;
for frameIdx = 1:nFrames
    actualFrame = actualFrame + 1;
    
imOrig = vidObj.read(frameIdx);

im = imrotate(double(rgb2gray(imOrig)),270);
im = 255 * (im/255).^ (8);
% imGray = im(:,:,3);



response = zeros(size(im));
i=1;
for sigma = [0.5 2];
kernelSize = 11;

x = linspace(-kernelSize/2 , kernelSize/2  , 9);
y = linspace(-kernelSize/2-0.5 , kernelSize/2+0.5  , 10);

[X,Y] = meshgrid(x,y);

Elx  = diff(-exp(-((X+sigma).^2 + Y.^2)/sigma^2),1,2);
Erx  = diff(exp(-((X-sigma).^2 + Y.^2)/sigma^2),1,2);
for angle = 0:90:90
    ErxRot = imrotate(Erx,angle,'bilinear','crop');
    ElxRot = imrotate(Elx,angle,'bilinear','crop');
%     subplot(2,4,i)
%     surf(ErxRot);
%     title(['right kernel sigma: ' num2str(sigma) 'angle: ' num2str(angle) ' degrees']);
%     subplot (2,4,i+4)
%     surf(ElxRot)
%     title(['left kernel sigma: ' num2str(sigma) 'angle: ' num2str(angle) ' degrees']);
%     i=i+1;
    
%     Fr = fft2(ErxRot,size(im,1),size(im,2)); 

%     Fr = fftshift(Fr);
%     Fl = fft2(ElxRot,size(im,1),size(im,2)); 
%     Fr = fftshift(Fl);
%     ElxRotVec = reshape(ElxRot,1,[]);
%     ErxRotVec = reshape(ErxRot,1,[]);
%     dlmwrite(['ErxRotVec' num2str(angle) 'sigma' num2str(sigma) '.csv'], ErxRotVec ,'precision', '%.10f');
%     dlmwrite(['ElxRotVec' num2str(angle) 'sigma' num2str(sigma) '.csv'], ElxRotVec ,'precision', '%.10f');
    
    filterlx = imfilter(double(im),double(ElxRot),'same');
    filterrx = imfilter(double(im),double(ErxRot),'same');


% imFFT = (fft2(imGray));
% filterrx = (ifft2(imFFT.*Fl));
% filterlx = (ifft2(imFFT.*Fr));


    filterrx(filterrx<0) =0;
    filterlx(filterlx<0) =0;
    response = max(response,min(filterlx,filterrx));
    imshow(response,[]);
    frame = getframe(gcf)
    writeVideo(writerObj1,frame);

end

end


frameIdx


% filter = double(ones(3,12))';
% indices = double(repmat((1:480)',1,360));
% responseConv = conv2(response,filter);
% mass = conv2(indices.*response,filter)./responseConv;

% [~ , idx ] =max(response(margine:end-margine,:),[],1);
% idx = idx + margine;
% for i = 1:360

%     if im (idx(i),i,1) >200 &&(im (idx(i),i,1)>15+im (idx(i),i,2) || im (idx(i),i,1) > 15 + im (idx(i),i,3))
%         numPoints = numPoints+1;
%         im (idx(i),i,1) = 255;
%         im (idx(i),i,2) = 0;
%         im (idx(i),i,3) = 0;
    %     point = [idx(i);(i)]
%         point = [mass(idx(i),i);(i)];
%         laserPoints(i,frameIdx)=mass(idx(i),i);
x=1:size(im,2);
y=1:size(im,1);
[X Y] = meshgrid(x,y);
candidatesX = X.*(response>80);
candidatesY = Y.*(response>80);
candidatesX(candidatesX==0)=[];
candidatesY(candidatesY==0)=[];
% finalPoints = [];
x=-2:2;    
A = [ x(1)^3 x(1)^2 x(1) 1; 
    x(2)^3 x(2)^2 x(2) 1;
    x(3)^3 x(3)^2 x(3) 1;
    x(4)^3 x(4)^2 x(4) 1;
    x(5)^3 x(5)^2 x(5) 1];
pinvA = pinv(A);
points = [];
for i=1:size(candidatesX,2)
    if candidatesY(i)>3 && candidatesY(i)<size(im,1)-3
        x=-2:2;    
        y = response(candidatesY(i)-2:candidatesY(i)+2,candidatesX(i));
        coeffs=pinvA*y;
        a=3*coeffs(1); b=2*coeffs(2); c=coeffs(3);
        root1=(-b + sqrt(b^2-4*a*c))/(2*a);
        root2=(-b-sqrt(b^2-4*a*c))/(2*a); 
        
        % check second der
        maxCondRoot1=6*coeffs(1)*root1 + 2*coeffs(2)<0;
        maxCondRoot2=6*coeffs(1)*root2 + 2*coeffs(2)<0;
        
        if maxCondRoot1 && abs(root1)<0.7;
           point =  [ candidatesY(i)+root1;candidatesX(i)];
%            realWorldPoint = findRealWorldPointLaser(point, cameraMatrix(:,:,frameIdx), K ,surfaceCoeffs) ;
%            if abs(realWorldPoint(1))<0.5 && abs(realWorldPoint(2))<0.5 && abs(realWorldPoint(2))<2 
           points = [points point];
%            end
%            finalPoints(:,pointIdx) = realWorldPoint;
           pointIdx= pointIdx+1;
        elseif maxCondRoot2 && abs(root2)<0.7;
           point =  [ candidatesY(i)+root2;candidatesX(i)];
%            realWorldPoint = findRealWorldPointLaser(point, cameraMatrix(:,:,frameIdx), K ,surfaceCoeffs) ;
%            if abs(realWorldPoint(1))<0.5 && abs(realWorldPoint(2))<0.5 && abs(realWorldPoint(2))<2 
           points = [points point];
%            end
%            finalPoints(:,pointIdx) = realWorldPoint;
           pointIdx= pointIdx+1; 
        end
        

    end
end
        
%     end    

% end

% colors
%     if actualFrame >60
%         points = finalPoints(:,finalPoints(5,:) == actualFrame-59);
%         for i = 1:length(points)
%             pixel = round(findPixelFromWorldPoint(points(1:4,i) , cameraMatrix(:,:,frameIdx), K ));
%             if pixel(2) > 360; pixel(2) = 360; end
%             if pixel(2) < 1; pixel(2) = 1; end
%             if pixel(1) > 480; pixel(1) = 480; end
%             if pixel(1) < 1; pixel(1) = 1; end
%             color=squeeze(im(pixel(1),pixel(2),:));
%             pointRGB = [points(1:4,i) ; double(color)];
%             finalPointsRGB = [finalPointsRGB double(pointRGB)];
%         end
%          
%     end
% imshow(im);
% drawnow;
% imshow(imOrig)
% hold on
% scatter(points(1,:),360-points(2,:),'.')
% hold off
% frame = getframe(gcf);
% writeVideo(writerObj2,frame)


end

close(writerObj1);
close(writerObj2);

% finalPointsRGB = [finalPointsRGB(1:3,:) ; finalPointsRGB(5:7,:) ; zeros(1,length(finalPointsRGB)) ];
finalPoints = finalPoints(1:3,:);
% finalPointsRGB(:,abs(finalPointsRGB(1,:))>0.5 )=[];
% finalPointsRGB(:,abs(finalPointsRGB(2,:))>0.5 )=[];
% finalPointsRGB(:,abs(finalPointsRGB(3,:))>0.5 )=[];
finalPoints(:,pointIdx+1:end)=[];
finalPoints(:,abs(finalPoints(1,:))>0.5 )=[];
finalPoints(:,abs(finalPoints(2,:))>0.5 )=[];
finalPoints(:,abs(finalPoints(3,:))>0.5 )=[];
% finalPoints(:,finalPoints(1,:)<0 )=[];



finalPoints(1,:) = -finalPoints(1,:);
% fp = finalPointsRGB;
plot3(finalPoints(1,:),finalPoints(2,:),finalPoints(3,:),'r.');
axis equal; axis vis3d
% finalPoints = finalPoints';
% for i=1:length(finalPoints)
% finalPoints(i,:)=finalPoints(i,:)- sum(finalPoints)/length(finalPoints);
% end
% dlmwrite('bla.csv' , finalPoints' , ' ');
% mesh = pointCloud2rawMesh(finalPoints');
% makePly(mesh,'bla.ply')
% for i=1:length(laserPoints)
%    plot(laserPoints(:,i))
%    drawnow
%    pause(0.05)
% end
