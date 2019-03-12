%{
# Images used for training the classifier
training_group:varchar(20) 
-----
transform_path = NULL:varchar(100)
%}
% n.b training_group='original' is used in the rest of the package to 
% reffer to the provided training images and masks.
classdef TrainingGroups < dj.Manual
end