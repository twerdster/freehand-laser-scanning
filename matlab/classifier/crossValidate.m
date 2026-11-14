function [ result ] = crossValidate( trainFeatrues, trainClassify, p1, p2, p3, classifier, k)
%CROSSVALIDATE Summary of this function goes here
%   Detailed explanation goes here
    trainFeatureGroups = reshape(trainFeatrues,k,size(trainFeatrues,1)/k,size(trainFeatrues,2));
    trainClassifyGroups = reshape(trainClassify,k,size(trainClassify,1)/k,size(trainClassify,2));
    count=1;
    result = zeros(length(p1)*length(p2)*length(p3),5);
    for p1_i=1:length(p1)
        for p2_i=1:length(p2)
            for p3_i=1:length(p3)
                [ meanError , varError] = crossValidateSingle( trainFeatureGroups, trainClassifyGroups, p1{p1_i}, p2{p2_i}, p3{p3_i}, k, classifier);
                result(count,:) = [meanError varError p1_i p2_i p3_i];
                count = count+1;
                disp(count);
            end
        end
    end
end

