%{
# Classify Genotype based on Glomerular Features 
->kidneys.AnalysisGroups
-----
train_glom_ids:longblob
class_glom_ids:longblob
actual_genotype:longblob
predicted_genotype:longblob
svm_scores:longblob
roc_curve:longblob
%}

classdef GlomerularGenotypeSVM < dj.Imported

	methods(Access=protected)

		function makeTuples(self, key)
            load prepath.mat large_storage_path
            Prepath=large_storage_path;
            sections=fetch(kidneys.GlomFeatures,'*');
            glomeruli=struct('mouse_id',{[]},'glom_id',{[]},'genotype',{[]},...
                'center_pos',{[]},'features',{[]});
            gg=0;
            for ii=1:length(glomeruli)
                sec_key=rmfeild(sections(ii),{'glom_features_path','centers'});
                genotype=fetch1(kidneys.Mice&sec_key,'genotype');
                load([Prepath,sections(ii).glom_features_path],"glom_features")
                for jj=1:size(sections(ii).centers,1)
                    gg=gg+1;
                    glomeruli(gg).mouse_id=sections(ii).mouse_id;
                    glomeruli(gg).glom_id=sprintf('%s_g%02.f',...
                        sections(ii).image_id,gg);
                    glomeruli(gg).genotype=genotype;
                    glomeruli(gg).features=glom_features(jj,:); %#ok<IDISVAR,NODEF>
                end
            end
            KO_idx=strcmp({glomeruli.genotype},'KO');
            KO_features=vertcat(glomeruli(KO_idx).features);
            KO_ids={glomeruli(KO_idx).glom_id}';
            Het_idx=strcmp({glomeruli.genotype},'Het');
            class_Het_features=vertcat(glomeruli(Het_idx).features);
            class_Het_ids={glomeruli(Het_idx).glom_id}';
            WT_idx=strcmp({glomeruli.genotype},'WT');
            WT_features=vertcat(glomeruli(WT_idx).features);
            WT_ids={glomeruli(WT_idx).glom_id}';
            rng default;
            training_KO_idx=randperm(length(KO_ids),10);
            training_WT_idx=randperm(length(WT_ids),10);
            training_KO_features=KO_features(training_KO_idx,:);
            training_WT_features=WT_features(training_WT_idx,:);
            svm_model=fitcsvm([training_KO_features;training_WT_features],[ones(10,1);zeros(10,1)],...
                'Standardize', true, 'KernelFunction', 'polynomial',...
                'PolynomialOrder',3,'KernelScale', 'auto','ClassNames',[1,0]);
            class_KO_features=KO_features;
            class_KO_features(training_KO_idx)=[];
            class_KO_ids=KO_ids;
            class_KO_ids(training_KO_idx)=[];
            class_WT_features=WT_features;
            class_WT_features(training_WT_idx)=[];
            class_WT_ids=WT_ids;
            class_WT_ids(training_WT_idx)=[];
            KO_predicted=Cell(size(class_KO_ids));
            KO_scores=zeros(size(class_KO_ids));
            for ii=1:length(class_KO_ids)
                [class,score]=predict(svm_model,class_KO_features(ii,:));
                if class
                    KO_predicted{ii}='KO';
                else
                    KO_predicted{ii}='WT';
                end
                KO_scores(ii)=score(1);
            end
            Het_predicted=Cell(size(class_Het_ids));
            Het_scores=zeros(size(class_Het_ids));
            for ii=1:length(class_Het_ids)
                [class,score]=predict(svm_model,class_Het_features(ii,:));
                if class
                    Het_predicted{ii}='KO';
                else
                    Het_predicted{ii}='WT';
                end
                Het_scores(ii)=score(1);
            end
            WT_predicted=Cell(size(class_WT_ids));
            WT_scores=zeros(size(class_WT_ids));
            for ii=1:length(class_WT_ids)
                [class,score]=predict(svm_model,class_WT_features(ii,:));
                if class
                    WT_predicted{ii}='KO';
                else
                    WT_predicted{ii}='WT';
                end
                WT_scores(ii)=score(1);
            end
            [roc_curve.X,roc_curve.Y,roc_curve.T,roc_curve.AUC,roc_curve.OPTROCPT]=...
                perfcurve([ones(size(KO_scores));zeros(size(WT_scores))],...
                [KO_scores;WT_scores],1);
            key.train_glom_ids=[KO_ids(training_KO_idx);WT_ids(training_WT_idx)];
            key.class_glom_ids=[class_KO_ids;class_Het_ids;class_WT_ids];
            key.actual_genotype=[repmat({'KO'},size(class_KO_ids));...
                repmat({'Het'},size(class_Het_ids));repmat({'WT'},size(class_WT_ids))];
            key.predicted_genotype=[KO_predicted;Het_predicted;WT_predicted];
            key.svm_scores=[KO_scores;Het_scores;WT_scores];
            key.roc_curve=roc_curve;
			 self.insert(key)
		end
    end
end