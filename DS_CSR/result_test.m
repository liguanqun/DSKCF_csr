

% files = dir('/home/orbbec/dskcf_result_save/DSKCF_simaple/testall1/*.txt');
% len=length(files);
% for i=1:len
%     oldname=files(i).name;
%     newname=oldname([1:end-9 end-3:end])
%     
%     
% %     system(['rename ' oldname ' ' newname])
%     
%     movefile(oldname,newname)
% %     command = ['rename' 32 oldname 32 newname];
% %     status = dos(command);
% %     if status == 0
% %         disp([oldname, ' 已被重命名为 ', newname])
% %     else
% %         disp([oldname, ' 重命名失败!'])
% %     end
% end


%  ground_truth =load('/home/orbbec/data/bear_front/bear_front.txt');
%   ground_truth =load('/home/orbbec/data/child_no1/child_no1.txt');
%     ground_truth =load('/home/orbbec/data/face_occ5/face_occ5.txt');
 %   ground_truth =load('/home/orbbec/data/new_ex_occ4/new_ex_occ4.txt');
   ground_truth =load('/home/orbbec/data/zcup_move_1/zcup_move_1.txt');
       ground_truth(isnan(ground_truth))=0;
        dsKCFoutput =load('/home/orbbec/dskcf_result_save/DSKCF_simaple/zcup_move_1_DSKCF.txt');
%   dsKCFoutput =load('/home/orbbec/dskcf_result_save/DSKCF_simaple/minarea010/child_no1_ours.txt');
%  dsKCFoutput =load('/home/orbbec/dskcf_result_save/DSKCF_simaple/csr-dcf/child_no1.txt');

    dsKCFoutput = load('/home/orbbec/dskcf_result_save/DSKCF_simaple/padding3_conf_init/zcup_move_1.txt');
dsKCFoutput(isnan(dsKCFoutput))=0;


len =size(ground_truth,1);
len_ =size(dsKCFoutput,1);

if len == len_
    overlap = zeros(len,1);
    overlap_sum =0;
    success_times=0;
    for i=1:len
        
        if   isempty_target(ground_truth(i,:)) &&isempty_target(dsKCFoutput(i,:))
            overlap(i,1) =1;
            overlap_sum  = overlap_sum+1;
            success_times = success_times +1;
        end
        if ~isempty_target(ground_truth(i,:)) && isempty_target(dsKCFoutput(i,:))
            overlap(i,1) = -1;
            overlap_sum  = overlap_sum -1;
        end
        if isempty_target(ground_truth(i,:)) && ~isempty_target(dsKCFoutput(i,:))
            overlap(i,1) = -1;
            overlap_sum  = overlap_sum -1;
        end
        if  ~isempty_target(ground_truth(i,:)) && ~isempty_target(dsKCFoutput(i,:))
            xs = max(ground_truth(i,1) , dsKCFoutput(i,1));
            xe =min(ground_truth(i,1) + ground_truth(i,3), dsKCFoutput(i,1) + dsKCFoutput(i,3) );
            ys = max(ground_truth(i,2) , dsKCFoutput(i,2));
            ye = min(ground_truth(i,2) + ground_truth(i,4), dsKCFoutput(i,2) + dsKCFoutput(i,4));
            if (xs> xe || ys > ye)
                disp('error');
            else
                areaInt = (xe-xs)*(ye-ys);
                overlap(i,1) =  areaInt/( ground_truth(i,3)*ground_truth(i,4)+dsKCFoutput(i,3)*dsKCFoutput(i,4)-areaInt);
                overlap_sum = overlap_sum +overlap(i,1);
                if  overlap(i,1)>0.5
                    success_times = success_times+1;
                end
            end
            
        end
        
    end
    plot(overlap);
    success_rate = success_times/len;
    disp([' success rate of the seq    is  '  num2str(success_rate,'%.4f') '   ' num2str(success_times) '/' num2str(len)]);
end