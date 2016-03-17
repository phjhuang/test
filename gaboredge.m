 
 
function [ G ] =gaboredge(src,threshold)

 
if(ndims(src)==3)
    img=rgb2gray(src);
else
    img=src;
end;
 
X=double(img);
SIZE=length(X);   
[H,W] = size(img);
 
m=1.0;
delta=2^m; 

 
N=24;   
for index_x=1:N;
    for index_y=1:N;
        x=index_x-(N+1)/2;
        y=index_y-(N+1)/2;
        phi_x(index_x,index_y)=(x/delta^2).*exp(-(x.*x+y.*y)/(2*delta^2));
        phi_y(index_x,index_y)=(y/delta^2).*exp(-(x.*x+y.*y)/(2*delta^2));
    end
end; 

 
Gx=conv2(X,phi_x,'same');
Gy=conv2(X,phi_y,'same'); 

 
Grads=sqrt((Gx.*Gx)+(Gy.*Gy)); 

 
angle_array=zeros(H,W);  

 
for i=1:H;
    for j=1:W
        if (abs(Gx(i,j))>eps*100)   
            p=atan(Gy(i,j)/Gx(i,j))*180/pi;   
            if (p<0)         
                p=p+360;
            end;
            if (Gx(i,j)<0 & p>180)      
                p=p-180;
            elseif (Gx(i,j)<0 & p<180)  
                p=p+180;
            end
        else  
            p=90;
        end
        angle_array(i,j)=p;   
    end
end; 

 
edge_array=zeros(H,W); 

 
for i=2:H-1
    for j=2:W-1
        if ((angle_array(i,j)>=(-22.5) & angle_array(i,j)<=22.5) | ...
            (angle_array(i,j)>=(180-22.5) & angle_array(i,j)<=(180+22.5)))     %  0/180
            if (Grads(i,j)>Grads(i+1,j) & Grads(i,j)>Grads(i-1,j))
                edge_array(i,j)=Grads(i,j);
            end
        elseif ((angle_array(i,j)>=(90-22.5) & angle_array(i,j)<=(90+22.5)) | ...
                (angle_array(i,j)>=(270-22.5) & angle_array(i,j)<=(270+22.5))) %  90/270
            if (Grads(i,j)>Grads(i,j+1) & Grads(i,j)>Grads(i,j-1))
                edge_array(i,j)=Grads(i,j);
            end
        elseif ((angle_array(i,j)>=(45-22.5) & angle_array(i,j)<=(45+22.5)) | ...
                (angle_array(i,j)>=(225-22.5) & angle_array(i,j)<=(225+22.5))) %  45/225
            if (Grads(i,j)>Grads(i+1,j+1) & Grads(i,j)>Grads(i-1,j-1))
                edge_array(i,j)=Grads(i,j);
            end
        else  %  135/215
            if (Grads(i,j)>Grads(i+1,j-1) & Grads(i,j)>Grads(i-1,j+1))
                edge_array(i,j)=Grads(i,j);
            end
        end
    end
end 

 
MAX_E=max(max(edge_array).');     
edge_array=edge_array/MAX_E;       


 
for m=1:H
    for n=1:W
        if (edge_array(m,n)>threshold)
            edge_array(m,n)=1;
        else
            edge_array(m,n)=0;
        end
    end
end 

 
% figure(1)
% subplot(1,2,1)
% imshow(X,map)
% title('Í¼Ïñ')
% subplot(1,2,2)
% imshow(edge_array)
% title('±ßÔµ') 

 G= edge_array;
 end