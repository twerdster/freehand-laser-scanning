
%% Load data
clear all;
close all;
clc;

load('training.mat');
load('class.mat')


k=10;
treeDepth=7;


% ratio = length(class(class==1))/length(class);                       %dilute bG samples to reach ratio of 1/10
% [~, ind] = sort(class);
% ind(1:(length(class(class==1)))*(1/ratio-11))=[];

indBG = find(class==0); nBG = length(indBG);
indL = find(class==1); nL = length(indL);
outRatio = 0.1;
alpha = nL/(outRatio*nBG);

indRand = randperm(nBG)';
indRand = indRand(1:alpha*nBG);

ind = [indBG(indRand) ; indL];
ind = ind(randperm(length(ind)));


class = class(ind);
training = double(training(ind,:));

training(end-mod(size(training,1),k)+1:end,:)=[];
training = [training rgb2hsv(uint8(training))];
class(end-mod(size(class,1),k)+1:end)=[];
%%

% reducedSize = round(size(training,1)/5);
% training(reducedSize+1:end,:)=[];
% class(reducedSize+1:end)=[];

 
% training =[training rgb2hsv(training)];
% [COEFF,SCORE,latent] = princomp(training);
% training = SCORE(:,1:3);
% % goodDirection = mean(training(class==1,:));
% % goodDirection/norm(goodDirection,2);
% % 
% % X = goodDirection;
% % X = X/norm(X);
% % Y = [0 1 0] - ([0 1 0]*X')*X;
% % Y=Y/norm(Y);
% % Z = [0 0 1] - ([0 0 1]*X')*X - ([0 0 1]*Y')*Y;
% % Z=Z/norm(Z);
% % 
% % trainingProjX = sum(training.*repmat(X,size(training,1),1),2);
% % trainingProjY = sum(training.*repmat(Y,size(training,1),1),2);
% % trainingProjZ = sum(training.*repmat(Z,size(training,1),1),2);
% % 
% % training = [trainingProjX trainingProjY trainingProjZ];
% 
% 
% %% Cross Validate Tree classifier
% 
% p1_Tree = {2 3 4 5};
% p2_Tree = {'entropy'};
% p3_Tree = {'none'};

% 
% % cross_result = crossValidate( training, class, p1_Tree, p2_Tree, p3_Tree, 'Tree', k);
% 
% %% Train Tree model with cross validate optimal parameters
% 

trainFeatures = training(1:9*size(training,1)/k,:);
trainClass = class(1:9*size(training,1)/k);

testFeatures = training(9*size(training,1)/10+1:end,:);
testClass = class(9*length(class)/10+1:end);

% dtree = decisionTreeTrain(trainFeatures,trainClass,treeDepth, 'entropy');
t= classregtree(trainFeatures,logical(trainClass));
t2=t.prune('level',200);

% % dtree.plot;
% sampleClass = decisionTreePredict(dtree, testFeatures');
% error = sum(sampleClass~=testClass')/length(testClass)


createClassifyer(t);

sampleClass = t2.eval(testFeatures);
sampleClass = classify(testFeatures');
error = sum(sampleClass~=testClass)/length(testClass)
%%
% classify and show images
vidObj = VideoReader('IMG_0063.MOV');
frameNum = vidObj.NumberOfFrames;
convWindowSize = 12;
window = ones (convWindowSize,1);
side = zeros (convWindowSize,1);
side(convWindowSize/3:2*convWindowSize/3)=1;


for i=300:frameNum
    im = vidObj.read(i);
    [m n ~] = size(im);
    features = double(reshape(im,[],3));
    features = [double(features) rgb2hsv(uint8(features))];
    class = classify( features');

    mask = reshape(class ,m,n);
    
%     intensity = sqrt(double(im(:,:,1)).^2 + double(im(:,:,2)).^2 +double(im(:,:,3)).^2);
%     intensity = intensity./max(max(intensity));
% 
%     [Fx Fy] = gradient(intensity);
    
    conv = conv2(mask,window,'valid');
    conv = conv2(conv,[1 1 1 1 1 1 1] ,'valid');
    [~ , ind ] =max(conv,[],1);
    ind = sub2ind(size(mask),ind,1:size(conv,2));

    mask2 = zeros(size(mask));
    mask2(ind) =1;
% 
%     im2 = intensity.*mask;

    imshow(mask2(600:1100,:),[]);

    drawnow;
end



%%

% for i=1:length(d)
%     im = imread(d(i).name);
% [m n ~] = size(im);
% features = double(reshape(im,[],3));
% features = [double(features) rgb2hsv(uint8(features))];
% % coeff = COEFF(:,1:3);
% % features1 = sum(features.*repmat(coeff(:,1)',size(features,1),1),2);
% % features2 = sum(features.*repmat(coeff(:,2)',size(features,1),1),2);
% % features3 = sum(features.*repmat(coeff(:,3)',size(features,1),1),2);
% % features = [features1 features2 features3];
% 
% class = classify( features');
% 
% mask = reshape(class ,m,n);
% 
% im2 = uint8(repmat(mask,[1 1 3])).*reshape(im ,m,n,3);
% 
% subplot(1,length(d),i);
% imshow(im2);
% 
% 
% end



