%{
# Trains and saves classifiers for determining if a pixel of the image
# lies within the training ROI.
->kidneys.TrainingGroups
-----
class_path:varchar(100)
kfold_loss:float
%}

classdef GlomSVMs < dj.Imported
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            training=fetch(kidneys.TrainingFeatures&key,'*');
            load prepath.mat large_storage_path
            Prepath=large_storage_path;
            num_patches=training(1).num_patches;
            features=nan(num_patches*length(training),4096);
            for ii=1:length(training)
                if ~isempty(training(ii).features)
                    load([Prepath,training(ii).features_path],features)
                    features((1:num_patches)+((ii-1)*num_patches),:)=...
                        patch_features;
                end
            end
            features(isnan(features(:,1)),:)=[];
            mask_val=vertcat(training.mask_val);
            disp('Training Score SVM')
            rng default
            svm_model = fitcsvm(features, mask_val,...
                'Standardize', true, 'KernelFunction', 'RBF', 'KernelScale', 150,...
                'BoxConstraint',377,'ScoreTransform', 'logit','ClassNames',[1,0],'Cost',[0,1;5,0]);
            disp('computing k-fold loss')
            cv_model=crossval(svm_model);
            kfold_loss=kfoldLoss(cv_model);
            disp('Training Prob SVM')
            prob_svm_model=fitSVMPosterior(svm_model); %#ok<NASGU>
            class_path=sprintf('Glom/GlomClassifiers/%s_svms',training_group);
            save([Prepath,prob_class_path],'svm_model','prob_svm_model')
            key.class_path=class_path;
            key.kfold_loss=kfold_loss;
            self.insert(key)
        end
    end
    
end