function [ sampleClass ] = trainSystem( testFeatures , trainFeatures , trainClass, p1 , p2, p3, classifier)
%TRAINSYSTEM Summary of this function goes here
%   Detailed explanation goes here
    if strcmp(classifier,'KNN')
        sampleClass = knnclassify(testFeatures , trainFeatures , trainClass, p1, p2, p3);    
    elseif strcmp(classifier,'Bayes')
        nb = NaiveBayes.fit(trainFeatures, trainClass, 'Distribution',p1, 'Prior', p2, 'KSType', p3);
        sampleClass = predict(nb,testFeatures);
    else
        dtree = decisionTreeTrain(trainFeatures',trainClass, p1, p2);
        sampleClass = decisionTreePredict(dtree, testFeatures')';
    end        
end


