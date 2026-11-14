close all
clear all

vidObj = VideoReader('IMG_0306.MOV');
nFrames = vidObj.NumberOfFrames;
kernelSize = 13;
s = 0.5:0.5:2;
margine = 170;

kernel1 = [-13 2 7 2 -13 ; 2 17 22 17 2; 7 22 27 22 7 ; 2 17 22 17 2 ; -13 2 7 2 -13]/175;
kernel2 = [31 -5 -17 -5 31 ; -44 -62 -68 -62 -44 ; 0 0 0 0 0 ; 44 62 68 62 44 ; -31 5 17 5 -31]/420;
kernel3 = [31 -44 0 44 -31 ; -5 -62 0 62 5 ; -17 -68 0 68 17 ; -5 -62 0 62 5 ; 31 -44 0 44 -31]/420;
kernel4 = [2 2 2 2 2 ; -1 -1 -1 -1 -1 ; -2 -2 -2 -2 -2 ; -1 -1 -1 -1 -1 ; 2 2 2 2 2 ]/70;
kernel5 = [4 2 0 -2 -4 ; 2 1 0 -1 -2 ; 0 0 0 0 0 ; -2 -1 0 1 2 ; -4 -2 0 2 4 ]/100;
kernel6 = [2 -1 -2 -1 2 ; 2 -1 -2 -1 2 ; 2 -1 -2 -1 2; 2 -1 -2 -1 2 ; 2 -1 -2 -1 2 ]/70;
kernel7 = [-1 -1 -1 -1 -1 ; 2 2 2 2 2 ; 0 0 0 0 0 ; -2 -2 -2 -2 -2 ; 1 1 1 1 1 ]/60;
kernel8 = [-4 -2 0 2 4 ; 2 1 0 -1 -2 ; 4 2 0 -2 -4 ; 2 1 0 -1 -2 ; -4 -2 0 2 4 ]/140;
kernel9 = [-4 2 4 2 -4 ; -2 1 2 1 -2 ; 0 0 0 0 0 ; 2 -1 -2 -1 2 ; 4 -2 -4 -2 4 ]/140;
kernel10 = [-1 2 0 -2 1 ; -1 2 0 -2 1 ; -1 2 0 -2 1 ; -1 2 0 -2 1 ; -1 2 0 -2 1 ]/60;


%%
for frameIdx = 350:nFrames
imOrig = vidObj.read(frameIdx);
% im = imread('zebra.jpeg');

% im = double(rgb2gray(imrotate(imOrig,270)));
im = imrotate(double(imOrig(:,:,1)),270);
im = 255 * (im/255).^ (15);

response = zeros(size(im));
scaleSpace = zeros(size(im));

for i=1:size(s,2)
filter = fspecial('gaussian', kernelSize, s(i));

fs = imfilter(double(im) , double(filter),'same');
% fs = im;
    
[dfdx,~] = gradient(fs);
[d2fdx2,dfdxdy] = gradient(dfdx);
[~,dfdy] = gradient(fs);
[~,d2fdy2] = gradient(dfdy);

direction1 = atan(sqrt(abs( 2*dfdxdy ./ (d2fdx2 - d2fdy2) )));
direction2 =pi- atan(sqrt(abs( 2*dfdxdy ./ (d2fdx2 - d2fdy2) )));

grad1 = dfdx.*cos(direction1) + dfdy.*sin(direction1);
grad2 = dfdx.*cos(direction2) + dfdy.*sin(direction2);

alpha = direction2;
alpha(abs(grad1) > abs(grad2) ) =direction1(abs(grad1) > abs(grad2));

x= 1:size(im,2); y= 1:size(im,1);
[X,Y] = meshgrid(x,y);
% quiver(X,Y,cos(direction1) ,sin(direction1))
% % subplot(1,5,i)
% imshow((direction2),[])
alpha(isnan(alpha))=0;

XI=X+cos(alpha)*s(i);
YI=Y+sin(alpha)*s(i);
Z=fs;
ZI = interp2(Z,XI,YI,'linear');
[Gx,Gy]=gradient(ZI);
Rl=-Gx.*cos(alpha)-Gy.*sin(alpha);

XI=X+cos(alpha)*s(i);
YI=Y+sin(alpha)*s(i);
Z=fs;
ZI = interp2(X,Y,Z,XI,YI);
[Gx,Gy]=gradient(ZI);
Rr=-Gx.*cos(alpha)-Gy.*sin(alpha);

Rl(Rl<=0)=0;
Rr(Rr<=0)=0;


% x = linspace(-(kernelSize-1)/2 ,(kernelSize-1)/2, kernelSize+1);
% y = linspace(-(kernelSize-1)/2 ,(kernelSize-1)/2, kernelSize);
% 
% [X,Y] = meshgrid(x,y);
% 
% Elx  = -diff(exp(-((X+s(i)).^2 + Y.^2)/s(i)^2),1,2);
% Erx  = diff(exp(-((X-s(i)).^2 + Y.^2)/s(i)^2),1,2);
% Elx = Elx/sum(Elx(:));
% Erx = Erx/sum(Erx(:));
% 
% x = linspace(-5 ,5, kernelSize);
% y = linspace(-5 ,5, kernelSize+1);
% [X,Y] = meshgrid(x,y);
% 
% Ely  = -diff(exp(-((Y+s(i)).^2 + X.^2)/s(i)^2),1,1);
% Ery  = diff(exp(-((Y-s(i)).^2 + X.^2)/s(i)^2),1,1);
% Ely = Ely/sum(Ely(:));
% Ery = Ery/sum(Ery(:));
% 
% for angle = 50:10:130
% 
%     filterl = imrotate(Elx,angle,'bilinear','crop');
%     filterr = imrotate(Erx,angle,'bilinear','crop');
%     
%     subplot(1,2,1)
%     imshow(filterl,[])
%    
%     subplot(1,2,2)
%     imshow(filterr,[])
%     
%     Rl = imfilter(double(im),double(filterl),'same');
%     Rr = imfilter(double(im),double(filterr),'same');
% 
% 
%     Rl(Rl<0) =0;
%     Rr(Rr<0) =0;
%     
%     response = max(response,min(Rl,Rr));
%     imshow(min(Rl,Rr))
%     drawnow
%     scaleSpace( response ==  min(Rl,Rr) ) =i;
%     
% 
%     
% end

response = max(response,min(Rl,Rr));
scaleSpace( response ==  min(Rl,Rr) ) =i;
    
end
imshow(response>10,[])

respons.*(respons>10)
drawnow
% 
% k1=conv2(im,kernel1,'same');
% k2=conv2(im,kernel2,'same');
% k3=conv2(im,kernel3,'same');
% k4=conv2(im,kernel4,'same');
% k5=conv2(im,kernel5,'same');
% k6=conv2(im,kernel6,'same');
% k7=conv2(im,kernel7,'same');
% k8=conv2(im,kernel8,'same');
% k9=conv2(im,kernel9,'same');
% k10=conv2(im,kernel10,'same');
% 
% alphaP = 0.5*atan(k5./(k6-k4));
% alphaM = -0.5*atan(k5./(k6-k4));
% 
% A = k7.*sin(alphaM).^3 + (k8.*sin(alphaM).^2).*cos(alphaM) +k9.*(cos(alphaM).^2).*sin(alphaM) + k10.*cos(alphaM).^3;
% B = k4.*sin(alphaM).^2 + k5.*sin(alphaM).*cos(alphaM) + k6.*cos(alphaM).^2;
% C = k2.*sin(alphaM) + k3.*cos(alphaM);
% 
% rhol = (-B - sign(B).*sqrt(B.^2 - 4.*A.*C))./(2*A).*(B.^2 - 4.*A.*C>0);
% rhos = (C./A).*rhol;
% imshow(2*A.*rhos + B>0);
% 
% imshow( rhos<1 & rhos>-1 & rhos~=0 )
end
