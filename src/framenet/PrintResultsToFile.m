% Aleksandar Stanic, Thomas Wiatowski, ETH Zurich, 2016
function PrintResultsToFile(fileID,table_index,tsfms,featureTransformType,nLayers,size_trainFeatureVectors_2,feature_vector_size_before_dimensionality_reduction,varThreshold,cStrt,cStep,cStop,gStrt,gStep,gStop,log2c_max,log2g_max,accuracy,max_cv_acc)
s = [num2str(table_index),' & '];
for i = 1:size(tsfms,1)
    switch tsfms{i,1}
        case 'morlet0'
            s = [s,tsfms{1,1},',3,6 '];
        case 'curvelet0'
            s = [s,tsfms{1,1},',abs,32,fdct_wrapping,0,1,0,8 '];
        otherwise
            for j = 1:size(tsfms,2)
                if isnumeric(tsfms{i,j})
                    s = [s,num2str(tsfms{i,j})];
                else
                    s = [s,tsfms{i,j}];
                end
                if j < size(tsfms,2) s = [s,',']; end
            end 
    end
    if i < size(tsfms,1) s = [s,' | ']; end
end

s = [s,' & ',featureTransformType,' & '];
fprintf(fileID,s);
fprintf(fileID,'%.10g & %.10g & %.10g & %.10g & $%.10g:%.10g:%.10g$ & $%.10g:%.10g:%.10g$ & $%.10g$ & $%.10g$ & %.10g \\%% & %.10g \\%% \\\\\n',...
    nLayers-1,size_trainFeatureVectors_2,feature_vector_size_before_dimensionality_reduction,varThreshold,cStrt,cStep,cStop,gStrt,gStep,gStop,...
    log2c_max,log2g_max,accuracy,max_cv_acc);

end

        
