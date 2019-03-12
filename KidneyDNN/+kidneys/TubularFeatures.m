%{
# my newest table
->kidneys.GlomSectiioning
-----
tubular_features_path:varchar(150)
patch_pos:longblob
%}

classdef TubularFeatures < dj.Imported

	methods(Access=protected)

		function makeTuples(self, key)
            load prepath large_storage_path
            Prepath=large_storage_path;
            image_path=fetch1(kidneys.Images&key,'image_path');
            net=alexnet;
            sz = net.Layers(1).InputSize;
            I=imread([Prepath,image_path]);
            scanned_labels=fetch1(kidneys.GlomSectioning&key,'labels');
            grid=fetch1(kidneys.GlomSectioning&key,'grid');
            [Xq, Yq] = meshgrid(1:size(grid, 2), 1:size(grid, 1));
            lab_interp=interp2(find(grid(115,:)),find(grid(:,115)),scanned_labels,Xq,Yq,'nearest');
            lab_interp([1:115,end-114:end],:)=2;
            lab_interp(:,[1:115,end-114:end])=2;
            [roiI,roiJ]=find(lab_interp==0);
            tub_features=zeros(500,4096);
            patch_pos=zeros(500,2);
            rng default
            k=1;
            pos_list=[];
            while k<501
                k
                skip=false;
                n = randsample(length(roiI), 1);
                i = roiI(n);
                j = roiJ(n);
                for z=1:size(pos_list,1)
                    if pos_list(z,1)-i>-20 && pos_list(z,1)-i<20 &&...
                            pos_list(z,2)-j>-20 && pos_list(z,2)-j<20
                        skip=true;
                        break
                    end
                end
                if sum(sum(lab_interp(i + (1:sz(1)) - 114, j + (1:sz(2)) - 114, :)))>0||skip
                    continue
                else
                    curr_patch = I(i + (1:sz(1)) - 114, j + (1:sz(2)) - 114, :);                        
                    tub_features(k,:) = activations(net, curr_patch, 'fc6',...
                        'OutputAs','rows');
                    patch_pos(k,:)=[i,j];
                    k=k+1;
                    pos_list=[pos_list;i,j];
                end
            end
            tub_features_path=sprintf('KidneyDNN/TrainingFeatures/%s_%s_tub',...
                key.image_id,key.analysis_group);
            save([Prepath,tub_features_path],'tub_features')
            key.tubular_features_path=tub_features_path;
            key.patch_pos=patch_pos;
			 self.insert(key)
		end
	end

end