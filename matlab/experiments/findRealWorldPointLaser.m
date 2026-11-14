function realWorldPoint = findRealWorldPointLaser(point, cameraMatrix, K ,surfaceCoeffs)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
imagePoint = [point;1];
result = inv(K) *imagePoint;
alpha = - surfaceCoeffs(4) / (result' * surfaceCoeffs(1:3));
cameraPoint = alpha*inv(K)*imagePoint;
realWorldPoint = inv(cameraMatrix) * [cameraPoint ; 1];

end

