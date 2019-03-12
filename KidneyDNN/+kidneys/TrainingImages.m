%{
# Images used for training the classifier
image_id:varchar(20)
->kidneys.TrainingGroups
-----
image_path:varchar(50)
image_name:varchar(20)
mask:longblob
%}

classdef TrainingImages < dj.Manual
end