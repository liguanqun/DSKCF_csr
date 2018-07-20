% clc;clear all;close all;
% %generate the orignal data
% mu = 0;
% sig2 = 2;
% A = 4;
% x=-10:.1:10;
% y=A/sqrt(2*pi*sig2)*exp(-(x-mu).^2/sig2/2)+.05*randn(1,length(x))
% subplot 211
% scatter(x,y,'k');grid on;
%  
% %%curve fitting
% %1-Gauss distribution
% p = polyfit(x,log(y),2)
% % sig2_est = -1/2/p(1)
% % mu_est = sig2*p(2)
% % A_est = exp(mu^2/2/sig2+p(3))*sqrt(2*pi*sig2)
%   sig2_est = -1/2/p(1)
%  mu_est = -(p(2)/2*p(1))
%  A_est = exp(p(3)+mu_est^2/2/sig2_est)*sqrt(2*pi*sig2_est)
% 
% %plot
% subplot 212
% %  scatter(x,y,'k');hold on;
% grid on;
%  plot(x,(A_est/sqrt(2*pi*sig2_est)*exp(-(x-mu_est).^2/2/sig2_est)),'r--','linewidth',2);
% plot(x,A/sqrt(2*pi*sig2)*exp(-(x-mu_est).^2/2/sig2),'r--','linewidth',2);
%% 
% clc;clear all;close all;
% %generate the orignal data
% mu = -3;
% sig2 = 2;
% A = 4;
% muu = 2;
% sig2u = 3;
% Au = 5;
% x=-10:.1:10;
% % y=A/sqrt(2*pi*sig2)*exp(-(x-mu).^2/sig2/2)+0.05*randn(1,length(x));
% y=A/sqrt(2*pi*sig2)*exp(-(x-mu).^2/sig2/2)+ Au/sqrt(2*pi*sig2u)*exp(-(x-muu).^2/sig2u/2)+0.05*randn(1,length(x));
% subplot 211
% scatter(x,y,'k');grid on;
%  
% %%curve fitting
% %1-Gauss distribution
% f = fittype('a*exp(-((x-b)/c)^2)+d*exp(-((x-e)/f)^2)');
% [cfun,gof] = fit(x(:),y(:),f);
% cfun.a
% cfun.b
% cfun.c
% cfun.d
% cfun.e
% cfun.f
% 
% 
% yo = cfun.a*exp(-((x-cfun.b)/cfun.c).^2)+cfun.d*exp(-((x-cfun.e)/cfun.f).^2);
% 
% subplot 212
% %  scatter(x,y,'k');hold on;
% grid on;
% plot(x,yo,'r--','linewidth',2);

%% 
% clc;clear all;
% x=1:1:66;
% y =depthimagehist
%  subplot 211
% %   scatter(x,y,'k');grid on;
% plot(x,y,'r--','linewidth',2);grid on;
% 
% f = fittype('a*exp(-((x-b)/c)^2)+d*exp(-((x-e)/f)^2)');
% [cfun,gof] = fit(x(:),y(:),f);
% 
% 
% yo = cfun.a*exp(-((x-cfun.b)/cfun.c).^2)+cfun.d*exp(-((x-cfun.e)/cfun.f).^2);
% 
% subplot 212
% %  scatter(x,y,'k');hold on;
% grid on;
% plot(x,yo,'r--','linewidth',2);
result_txt_path =('/home/orbbec/DSKCF_matlab_result/');
txt_files_tmp= dir([result_txt_path '*.txt']);
nameCell = cell(length(txt_files_tmp),1);
txt_files_full_path = cell(length(txt_files_tmp),1);
for i = 1:length(txt_files_tmp)
    nameCell{i} = txt_files_tmp(i).name; 
    txt_files_full_path{i} =[result_txt_path nameCell{i}];
end
txt_name= sort_nat(nameCell)
txt_full_path =sort_nat(txt_files_full_path)

for i = 1:length(txt_files_tmp)
x=load(txt_full_path{i});
txt_full_path{i}
for j=1:size(x,1)
    
        row_x =x(j,:);
    
        if(row_x(5) > 0)             
            name = ['/home/orbbec/DSKCF_matlab_result_modify/' txt_name{i}];
            fp=fopen(name,'a');       
            fprintf(fp,'%s\r\n','NaN,NaN,NaN,NaN,1'); 
            fclose(fp);
            disp('NaN,NaN,NaN,NaN,1');
        else
            a=[row_x(1:2) row_x(1:2)+row_x(3:4) 0]  ;
            name = ['/home/orbbec/DSKCF_matlab_result_modify/' txt_name{i}];
          fp=fopen(name,'a');
            fprintf(fp,'%d,%d,%d,%d,%d\r\n',a);%注意：\r\n为换
            fclose(fp);

        end
    
end


end















