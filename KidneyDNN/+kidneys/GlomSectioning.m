%{
# my newest table
->kidneys.Images
-----
grid:longblob
labels:longblob
scores:longblob
roi_props:longblob
%}

classdef GlomSectioning < dj.Imported
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            jumpsz_init=100;
            jumpsz_sec=20;
            net=alexnet;
            sz = net.Layers(1).InputSize;
            load prepath.mat large_storage_path
            Prepath=large_storage_path;
            image_path=fetch1(kidneys.Images&key,'image_path');
            class_path=fetch1(kidneys.GlomSVMs&'training_group="original"',...
                'class_path');
            load([Prepath,class_path],'svm_model')
            I=imread([Prepath,image_path]);
            iidx=(std(double(I(:,:,3)),0,2))>6;
            jidx=(std(double(I(:,:,3))))>6;
            I(iidx,jidx,:)=histeq(I(iidx,jidx,:));
            isz=size(I);
            vi_init=115:jumpsz_init:isz(1)-114;
            vj_init=115:jumpsz_init:isz(2)-114;
            grid_init=false(isz(1),isz(2));
            grid_init(vi_init,vj_init)=true;
            [scan_i_idx,scan_j_idx]=find(grid_init);
            lab_init=nan(size(grid_init));
            for scan_num=1:length(scan_i_idx)
                curr_patch = I(scan_i_idx(ii) + (1:sz(1)) - 114,...
                    scan_j_idx(ii) + (1:sz(2)) - 114, :);
                if std2(double(curr_patch(:,:,1)))<15
                    lab_init(scan_i_idx(ii),scan_j_idx(ii))=0;
                else
                    curr_features ={activations(net, curr_patch,...
                        'fc6','OutputAs','rows')};
                    lab_init(scan_i_idx(ii),scan_j_idx(ii))=...
                        predict(svm_model,curr_features);
                end
            end
            [Xq, Yq] = meshgrid(1:size(grid, 2), 1:size(grid, 1));
            lab_init=interp2(vj_init,vi_init,lab_init,Xq,Yq,'nearest');
            lab_init([1:115,end-114:end],:)=0;
            lab_init(:,[1:115,end-114:end])=0;
            lab_init(bwdist(lab_init)<=40)=1;
            vi_sec=115:jumpsz_sec:isz(1)-114;
            vj_sec=115:jumpsz_sec:isz(2)-114;
            grid_sec=false(isz(1),isz(2));
            grid_sec(vi_sec,vj_sec)=true;
            lab_sec=nan(size(grid_sec));
            lab_sec(grid_sec&~lab_init)=0;
            scores=nan(size(grid_sec));
            scores(grid_sec&~lab_init)=0;
            [scan_i_idx,scan_j_idx]=find(grid_sec&lab_init);
            for scan_num=1:length(scan_i_idx)
                curr_patch = I(scan_i_idx(ii) + (1:sz(1)) - 114,...
                    scan_j_idx(ii) + (1:sz(2)) - 114, :);
                if std2(double(curr_patch(:,:,1)))<15
                    lab_sec(scan_i_idx(ii),scan_j_idx(ii))=0;
                else
                    curr_features ={activations(net, curr_patch,...
                        'fc6','OutputAs','rows')};
                    [lab_sec(scan_i_idx(ii),scan_j_idx(ii)),curr_score]=...
                        predict(svm_model,curr_features);
                    scores(scan_i_idx(ii),scan_j_idx(ii))=curr_score(1);
                end
            end
            lab_sec=lab_sec(vi_sec,vj_sec);
            scores=scores(vi_sec,vj_sec);
            ccs=bwconcomp(lab_sec);
            roi_props=regionprops(ccs,'Area','Centroid','Eccentricity');
            key.grid=sparse(grid_sec);
            key.labels=lab_sec;
            key.scores=scores;
            key.roi_props=roi_props;
            self.insert(key)
        end
    end
    
end