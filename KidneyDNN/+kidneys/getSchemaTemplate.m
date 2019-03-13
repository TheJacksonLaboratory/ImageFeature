% Replace <Database Schema Name> with the name of the target schema on the
% database (e.g. <username>_kidneys) and rename file to getSchema 
function obj = getSchema
persistent OBJ
if isempty(OBJ)
    OBJ=dj.Schema(dj.conn,'kidneys','<Database Schema Name>');
end
obj=OBJ;
end