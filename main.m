     clear;close all;


     imgName = 'img\111.jpg' ;   %
      %  imgName = 'img\111.bmp' ;  
    colorimg = imread(imgName);
    grayimg = rgb2gray(colorimg);

    [H,W] = size(grayimg); 

    %%
    avg_value=mean(grayimg(:)) ;
    g1=grayimg( 1:H*0.3,  W*0.1:W*0.7      );
    g2=grayimg( H*0.75:H,  :   );
    gv1=mean(g1(:)) ; 
    gv2=mean(g2(:));

    type=0;
    flag1=gv1/avg_value>1.5;
    flag2=gv1/gv2>3;
    flag3 = gv1>120 ;
    flag4= gv2/avg_value<0.65;
    if(flag1 &  flag2 &   flag3 & flag4)
        type=1; %  1 outdoor type  sunshine or cloudy   0 otherwise
    end



        %%
    dctimg=dct2(grayimg);  %¼ÆËãDCT%
    dctimg(1: 19 ,1:45 )=0;
     dctimg( H-55:  H , W-55: W )=0;%
    dctimg=idct2(dctimg) ;% /255
    grayimg=gscale(dctimg, 'full8');


    %%
    
%   pw1=0.07;
%     pw2=0.5;   %É¾È¥ÓÒ±ß
    ph=0.1;
    newH=200;
    if(type==1)
        newH=100;
        ph=0.4;
    end

    scale=newH/H;  %0.5
    newW=round(W*scale);

    colorscale= imresize(colorimg, [newH,newW ]);

    skyline=max(1,newH*ph);
    belowimg=colorscale(skyline:newH*1,   :   ,    : );
 

    [x0, y0  ] = vanishpoint(belowimg, 36, 'img\');


    x=x0/scale;
    y=(y0+newH*ph)/scale;
 
    showimg=colorimg;
    workimg=colorimg ;
    workimg(1:y+20 , :   ,   : )=0;

    hough_lane(workimg, showimg,  x,y);

 
    [x0, y0  ]
 
    
    
 


