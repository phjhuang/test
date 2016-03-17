function  hough_lane(workimg, showimg, x,y )

 
g=rgb2gray(workimg);

[height ,width]= size(g);

% if(x>0.6*width || x<0.3*width)
%     x=0.5*width;
%     y=0.5*height;
% end
 
gs=rgb2gray(showimg);
g_value=mean(gs(:)) 
threshold= 0.024 ;                   %  阈值（需要调整）
c0=0.25;
if(g_value> 10  )
    threshold= 0.05;
    c0=0.25;
% elseif (g_value>=30 )
%     threshold= 0.11;
% elseif (g_value>=70 )
%     threshold= 0.11;
elseif (g_value>=90 )
    threshold= 0.15;
    c0=0.3;
elseif (g_value>=120 )
    threshold= 0.15;
        c0=0.3;
end
  
%g( 1:y-2,  :  ) =0;
% % g(height-30:height,  :  ) =0;
% g(height-40:height, width-50 : width ) =0;
% g(height-40:height, 1: 50 ) =0;


BWthin=gaboredge(g, threshold );
%BWthin=bwmorph(BWthin,'thin',inf);
%erode% BWthin=imopen(BWthin,strel('square',2));
%BWthin=edge(g,'canny',[0.02,0.1]);


%  figure, imshow(BWthin);title('thin');

% BWthin( 1:y+5,  :  ) =0;
% BWthin(height-45:height,  :  ) =0;
% BWthin(height-45:height, width-55 : width ) =0;
% BWthin(height-45:height, 1: 55 ) =0;

%  figure, imshow(BWthin);title('thin');
% imwrite(BWthin,  'BWthin.bmp' ,'bmp');

%%
[H,T,R] = hough(BWthin, 'Theta', -75:0.1:75,  'RhoResolution',    1);
c=ceil(c0*max(H(:)))    ;
P = houghpeaks(H,20 ,'threshold', c);
% global lines ;
  lines= houghlines(BWthin,T,R,P,'FillGap',25,'MinLength',20);  %






%%
%标记 删除短线，树，位置不对线


for k =  1:length(lines)
    flag1= abs(    lines(k).theta  )<10;
    flag2=  lines(k).point2(2) <height*0.7         &  lines(k).point1(2) <height*0.7;
    flag3 =  norm(lines(k).point1 - lines(k).point2)< 55    ;
    if flag1&& (flag2 || flag3)
        lines(k).theta=90;
    end
    
    flag4= lines(k).point1(1) < 0.35*width & lines(k).theta<0;
    flag5= lines(k).point1(1) > 0.65*width &  lines(k).theta>0;
    if flag4 ||  flag5
        lines(k).theta=90;
    end
end

for k =  1:length(lines)
    flag1 = lines(k).theta~=90;
    flag3= lines(k).theta>0  && lines(k).point2(1)>width*0.6   && lines(k).point2(2)< height*0.6 ;
    flag4= lines(k).theta<0  && lines(k).point1(1)<width*0.4   && lines(k).point1(2)< height*0.6 ;
    
    flag5=  lines(k).theta>0 && (lines(k).point1(2)+ lines(k).point2(2)   )<height   && lines(k).point1(1)< width*0.4 ;
    flag6=   lines(k).theta<0 && (lines(k).point1(2)+ lines(k).point2(2)   )<height   && lines(k).point2(1)> width*0.6 ;
    
    %         flag3= lines(k).theta>0  && lines(k).point1(1)>width*0.4   && lines(k).point1(2)< height*0.6 ;
    %     flag4= lines(k).theta<0  && lines(k).point2(1)<width*0.6   && lines(k).point1(2)< height*0.6 ;
    
    if flag1&&(flag3|| flag4  || flag5 || flag6     )
        lines(k).theta=90;
    end
end


%%
%删除距离消失点远的  or短线
for k =  1:length(lines)
    if    point_distance(x,y,  lines(k).point1, lines(k).point2  )   >50  ||   norm(lines(k).point1 - lines(k).point2  )  <30
        lines(k).theta=90;
    end
end
lines ( [lines.theta ] ==90 )=[];

 
%% 画出  线段,'border','tight','initialmagnification','fit',  set (gcf,'Position',[0,0,width,height])

figure(1100);
imshow(workimg), hold on
 
for k = 1:length(lines)
    xy = [lines(k).point1; lines(k).point2];
    plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
    % Plot beginnings and ends of lines
       plot(xy(1,1),xy(1,2),'x','LineWidth',4,'Color','yellow');
         plot(xy(2,1),xy(2,2),'x','LineWidth',5,'Color','red');
    
         text(xy(1,1),xy(1,2),   num2str(k)   ,  'FontSize',20,  'horiz','center','color','cyan')
         lines(k).point1,  lines(k).point2,  lines(k).theta, lines(k).rho
    %   pause( );
end
 
%  saveas(gcf,'line.png','jpg')


 %%
%  ·······················left
 
% 合并相同线段
for k =  1:length(lines)
    for j= k+1:length(lines)
        flag1 = abs( lines(k).rho -  lines(j).rho)<3  &&  abs( lines(k).theta -  lines(j).theta )<1 ;
        
        leftpoint= lines(k).point1 *(    lines(k).point1(1) <=   lines(j).point1(1)   )    + lines(j).point1 *(    lines(k).point1(1) >  lines(j).point1(1)   )    ;
        rightpoint = lines(k).point2 *(    lines(k).point2(1) >=  lines(j).point2(1)   )    + lines(j).point2 *(    lines(k).point2(1) <  lines(j).point2(1)   )    ;
        kjlen= norm( leftpoint - rightpoint);
        klen = norm(lines(k).point1 - lines(k).point2);
        jlen = norm(lines(j).point1 - lines(j).point2);
        flag3=   kjlen<2.5*(klen+jlen);
         
        if  flag1   & flag3
            lines(k).point1 =leftpoint  ;
            lines(k).point2=rightpoint  ;
            lines(k).theta= (lines(k).theta  +lines(j).theta)/2;
            lines(k).rho= (lines(k).rho  +lines(j).rho)/2;
            lines(j).theta=90;
        end
    end
end

lines (     [lines.theta ] ==90  )=[];

for k =  1:length(lines)
    if    norm(lines(k).point1 - lines(k).point2  )  <50
        lines(k).theta=90;
    end
end
lines ( [lines.theta ] ==90 )=[];



    
%% 画出  线段,'border','tight','initialmagnification','fit',  set (gcf,'Position',[0,0,width,height])

figure(117);
imshow(workimg), hold on
 
for k = 1:length(lines)
    xy = [lines(k).point1; lines(k).point2];
    plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
    % Plot beginnings and ends of lines
       plot(xy(1,1),xy(1,2),'x','LineWidth',4,'Color','yellow');
         plot(xy(2,1),xy(2,2),'x','LineWidth',5,'Color','red');
    
         text(xy(1,1),xy(1,2),   num2str(k)   ,  'FontSize',20,  'horiz','center','color','cyan')
         lines(k).point1,  lines(k).point2,  lines(k).theta, lines(k).rho
    %   pause( );
end
 
%  saveas(gcf,'line.png','jpg')



% %%
% 
%     flag0=  lines(k).theta>0  ;
%     flag1= abs( lines(k).theta- lines(leftindex).theta)<5 ;
%     flag2 =  abs( lines(k).rho- lines(leftindex).rho)<18 ;
%     flag20 =  abs( lines(k).theta- lines(leftindex).theta) +  2*abs( lines(k).rho- lines(leftindex).rho)<46;
%     l_k =   abs( lines(k).point1(1) - lines(k).point2(1)) ;
%     l_leftindex =abs(  lines(leftindex).point1(1) - lines(leftindex).point2(1) ) ;
%     
%     flag3 =l_k /l_leftindex >2.2 ;
%     flag4 = l_k /l_leftindex >1.5 ;
%     flag5=   point_distance(x,y,  lines(leftindex).point1, lines(leftindex).point2  )  > point_distance(x,y,  lines(k).point1, lines(k).point2  )+10    ;
%     flag6 = flag3||(flag4&&flag5);
%     
%     if   flag0 &&flag1 && flag2 &&  flag6  && flag20
%         leftindex=k;
% 
%     
%     
%     flag0=  lines(k).theta<0  ;
%     flag1= abs( lines(k).theta- lines(rightindex).theta)<5 ;
%     flag2 =  abs( lines(k).rho- lines(rightindex).rho)<18 ;
%     flag20 =  abs( lines(k).theta- lines(rightindex).theta) +  2*abs( lines(k).rho- lines(rightindex).rho)<46;
%     
%     l_k =   abs( lines(k).point1(1) - lines(k).point2(1)) ;
%     l_rightindex =abs(  lines(rightindex).point1(1) - lines(rightindex).point2(1) ) ;
%     flag3 = l_k/ l_rightindex>2.2 ;
%     flag4 = l_k /l_rightindex >1.5 ;
%     flag5=   point_distance(x,y,  lines(rightindex).point1, lines(rightindex).point2  )  > point_distance(x,y,  lines(k).point1, lines(k).point2  )  +10;
%     flag6 = flag3||(flag4&&flag5);
%     
%     if   flag0 &&flag1 && flag2 &&  flag6  && flag20
%         leftindex=k;
%     end
%     
% end





%%   




%%
%找到车道线
sx=x;
sy=y;


left=90;right=-90;leftindex=1;rightindex=1;
for k = 1:length(lines)
    flag1=  lines(k).theta>0 && lines(k).theta<left ;
    flag2 =    lines(k).point1(1)+lines(k).point2(1)  < sx*2     &&     lines(k).point1(2)+lines(k).point2(2) > sy*2 ;
    flag3 =  lines(k).point1(1) < sx  &&  lines(k).point1(2) > sy;
    flag31=  lines(k).point1(1) < sx-55  ||  lines(k).point1(2) > sy+75;
    
    if  flag1 && flag2 &&  flag3 && flag31
        left=lines(k).theta;
        leftindex=k;
    end
    
    flag4 =lines(k).theta<0  && lines(k).theta>right;
    flag5=   lines(k).point1(1)+lines(k).point2(1)   >2*sx         &&          lines(k).point1(2)+lines(k).point2(2) > sy*2                ;
    flag6 = lines(k).point2(1) > sx   &&   lines(k).point2(2)>sy;
    flag61 = lines(k).point2(1) > sx+55   &&   lines(k).point2(2)>sy+75;
    if   flag4 && flag5  &&  flag6&& flag61
        right=lines(k).theta;
        rightindex=k;
    end
end





%%  最后结果

showimg(y-1:y+1,x-17:x+17,1) = 0;
showimg(y-17:y+17,x-1:x+1,1) = 0;
showimg(y-1:y+1,x-17:x+17,2) = 220;
showimg(y-17:y+17,x-1:x+1,2) = 220;
showimg(y-1:y+1,x-17:x+17,3) = 0;
showimg(y-17:y+17,x-1:x+1,3) = 0;

figure, imshow(showimg), hold on

leftline = [lines(leftindex).point1; lines(leftindex).point2];
rightline= [lines(rightindex).point1; lines(rightindex).point2];

plot(rightline(:,1),rightline(:,2),'LineWidth',3,'Color','green');
plot(leftline(:,1),  leftline(:,2),'LineWidth',3,'Color','green');

% plot([ lines(leftindex).point1(1)-4, lines(leftindex).point2(1)-4   ],    [ lines(leftindex).point1(2), lines(leftindex).point2(2)   ] ,    'LineWidth',3,'Color','g' );
% plot(rightline(:,1),rightline(:,2),'LineWidth',3,'Color','red');








%%







