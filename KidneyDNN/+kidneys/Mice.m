%{
# Mice
->kidneys.AnalysisGroups
mouse_id:varchar(20) 
-----
genotype:enum('KO','Het','WT')
%}

classdef Mice < dj.Manual
end