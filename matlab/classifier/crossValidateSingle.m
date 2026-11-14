function [ meanError , varError] = crossValidateSingle( trainFeatureGroups, trainClassifyGroups, p1, p2, p3, k, classifier)
%CROSSVALIDATESINGLE Summary of this function goes here
%   Detailed explanation goes here
    error = zeros(k,1);
    
    for i=1:k
        mask = true(k,1);
        mask(i)=false;
        trainFeatures = trainFeatureGroups(mask,:,:);
        trainFeaturesMat(:,:,i) = reshape(trainFeatures,[],size(trainFeatures,3));
        testFeatures = trainFeatureGroups(~mask,:,:);
        testFeaturesMat(:,:,i) = reshape(testFeatures,[],size(testFeatures,3));
        trainClass = trainClassifyGroups(mask,:);
        trainClassMat(:,i) = reshape(trainClass,[],1);
        testClass = trainClassifyGroups(~mask,:);
        testClassMat(:,i) = reshape(testClass,[],1);   
    end
    
    parfor i = 1:k

        sampleClass  = trainSystem( testFeaturesMat(:,:,i) , trainFeaturesMat(:,:,i) , trainClassMat(:,i)', p1 , p2, p3, classifier); 
        error(i) = 100*sum (sampleClass ~= testClassMat(:,i)) / length(sampleClass);
    end

    meanError = mean(error);
    varError = var(error);
end

