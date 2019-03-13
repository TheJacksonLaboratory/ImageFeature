%{
# extract training features from each image
->kidneys.TrainingImages
-----
features_path:longblob
mask_val:longblob
num_patches:smallint unsigned
%}

classdef TrainingFeatures < dj.Imported
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            net=alexnet;
            layer_name = 'fc6'; % Network layer to select features
            num_samp = 100; % Number of samples from each image (for each class)
            
            load prepath.mat large_storage_path
            Prepath=large_storage_path;
            image_path=fetch1(image.TrainingImages & key,'image_path');
            image_path=[Prepath,image_path];
            I=imread(image_path);
            BW=fetch1(image.TrainingImages & key,'mask');
            %% color corection
            I=histeq(I);
            
            
            %% patch selection
            rng default;
            % Read the image to classify
            sz = net.Layers(1).InputSize;
            skip=false;
            patch_features = zeros(2*num_samp,4096);
            mask_val = zeros(2 * num_samp, 1);
            patch_pos = zeros(2 * num_samp, 2);
            
            % From ROIs
            [roiI, roiJ] = find(BW);
            attempt=1;
            isamp = 1;
            while isamp <= num_samp
                if attempt>5000
                    warning(['Unable to find sufficient example patches,',...
                        ' skipping image.'])
                    skip=true;
                    patch_features=[];
                    mask_val=[];
                    key.mean=[];
                    key.hist=[];
                    break
                end
                
                disp([isamp,attempt])
                
                try
                    
                    n = randsample(length(roiI), 1);
                    
                    i = roiI(n);
                    j = roiJ(n);
                    
                    curr_patch = I(i + (1:sz(1)) - 114, j + (1:sz(2)) - 114, :);
                    
                    %imshow(curr_patch)
                    
                    patch_features(isamp,:) = activations(net, curr_patch, layer_name,...
                        'OutputAs','rows');
                    
                    mask_val(isamp) = BW(i, j);
                    
                    patch_pos(isamp, :) = [i, j];
                    
                    isamp = isamp + 1;
                    
                catch
                    disp('Outside image boundary.')
                end
                attempt=attempt+1;
            end
            
            if ~skip
                % From outside ROIs
                % Get distances to ROIs
                D = bwdist(BW);
                
                % Sample
                attempt=1;
                isamp = 1;
                while isamp <= num_samp
                    if attempt>5000
                        warning(['Unable to find sufficient example patches,'...
                            ' skipping image.'])
                        patch_features=[];
                        mask_val=[];
                        key.mean=[];
                        key.hist=[];
                        break
                    end
                    
                    disp([isamp,attempt])
                    
                    try
                        % Sample random distance
                        p = 1 / 115;
                        curr_dist = geornd(p);
                        [bandI, bandJ] = find((D >= curr_dist) & (D <= curr_dist + 1));
                        
                        % Sample random patch from chosen distance "band"
                        n = randsample(length(bandI), 1);
                        i = bandI(n);
                        j = bandJ(n);
                        
                        curr_patch = I(i + (1:sz(1)) - 114, j + (1:sz(2)) - 114, :);
                        
                        patch_features(isamp + num_samp, :) = activations(net, curr_patch, layer_name,'OutputAs','rows');
                        
                        mask_val(isamp + num_samp) = BW(i, j);
                        patch_pos(isamp + num_samp, :) = [i, j];
                        
                        isamp = isamp + 1;
                        
                    catch
                        disp('Outside image boundary.')
                    end
                    attempt=attempt+1;
                end
            end
            if ~isempty(patch_features)
                features_path=sprintf('KidneyDNN/TrainingFeatures/%s_%s',key.image_id,key.training_group);
                save([Prepath,features_path],'patch_features')
            else
                features_path='';
            end
            key.features_path=features_path;
            key.mask_val=mask_val;
            key.num_patches=num_samp*2;
            self.insert(key)
        end
    end
    
end