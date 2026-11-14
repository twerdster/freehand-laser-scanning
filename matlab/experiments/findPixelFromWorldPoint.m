function pixel = findPixelFromWorldPoint(point, cameraMatrix, K )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
realWorldPoint = point;
cameraPoint = cameraMatrix*realWorldPoint;
% cameraPoint = cameraPoint / cameraPoint(4) ;
cameraPoint = cameraPoint(1:3);
pixel = K*cameraPoint;
pixel = pixel / pixel(3);
pixel = pixel(1:2);

end

