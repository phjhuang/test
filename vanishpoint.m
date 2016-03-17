function [vpX ,vpY   ] =vanishpoint(colorImg, norient, outputPath  )

%%
% vpX=0;
% vpY=0;
% vpX0=0;
% vpY0=0;

%%
colorImgCopy = colorImg;
grayImg= rgb2gray(colorImg);
grayImgCopy = grayImg;

[imCopyH,imCopyW] = size(grayImgCopy);
largestDistence = sqrt(imCopyH*imCopyH + imCopyW*imCopyW);%对角线长度

%needIterationLabel = 1;%所需重复标志
% tmp_vpYCopy = round(imCopyH*0.9);

%%
% tmp_vpY1 = round(imCopyH*0.1); %%vpY;
% tmp_vpX1 = round(imCopyW*0.5); %%vpX;
% tmp_vpY = round(imCopyH*0.1); %%vpY;
% tmp_vpX = round(imCopyW*0.5); %%vpX;

%%
%edgeImg = edge(grayImg,'canny');%
%imwrite(edgeImg,[outputPath, int2str(numOfValidFiles),'vpEdgeImg0.bmp'], 'bmp');

%%   kernels
angleRange = 180;
angleInterval = angleRange/norient;
oddResponse = zeros(imCopyH,imCopyW);
evenResponse = zeros(imCopyH,imCopyW);
tmpW = min([imCopyH,imCopyW]); %%min([imCopyH,imCopyW]);
lamda = 2^(round(log2(tmpW)-5));
kerSize = round(10*lamda/pi);

if mod(kerSize,2)==0         %kersize/2的余数
    kerSize = kerSize + 1;
    halfKerSize = floor(kerSize/2);       %朝负方向舍入
else
    halfKerSize = floor(kerSize/2);
end

oddKernel = zeros(kerSize, kerSize, norient);
evenKernel = zeros(kerSize, kerSize, norient);
delta = kerSize/9;
tmpDelta = -1/(delta*delta*8);
c = pi/lamda; %%%%
% c = 2.2; %%%%


cosTheta = zeros(angleRange, 1);
sinTheta = zeros(angleRange, 1);
for theta = 1:angleRange
    cosTheta(theta) = cos((theta-1)*pi/180);
    sinTheta(theta) = sin((theta-1)*pi/180);
end

kerCenterY = halfKerSize + 1;
kerCenterX = halfKerSize + 1;

%% kernels
for theta = 90+1:angleInterval:angleRange-angleInterval+1+90
    tmpTheta = (theta - 1)*pi/180;
    for y= -halfKerSize:halfKerSize
        ySinTheta = y*sin(tmpTheta);
        yCosTheta = y*cos(tmpTheta);
        for x=-halfKerSize:halfKerSize
            xCosTheta = x*cos(tmpTheta);
            xSinTheta = x*sin(tmpTheta);
            a = xCosTheta+ySinTheta;
            b = -xSinTheta+yCosTheta;
            oddKernel(y+halfKerSize+1,x+halfKerSize+1,(theta - 1-90)/angleInterval+1) = exp(tmpDelta*(4*a*a+b*b))*sin(c*a);
            evenKernel(y+halfKerSize+1,x+halfKerSize+1,(theta - 1-90)/angleInterval+1) = exp(tmpDelta*(4*a*a+b*b))*cos(c*a);
        end
    end
end

%%normalized
normalizedOddKernel = zeros(kerSize, kerSize, norient);
normalizedEvenKernel = zeros(kerSize, kerSize, norient);
for i=1:norient
    tmpKernel = oddKernel(:,:,i)-mean(mean(oddKernel(:,:,i)));
    tmpKernel = tmpKernel/(norm(tmpKernel));%norm 算 最大奇异值
    normalizedOddKernel(:,:,i) = tmpKernel;
    
    tmpKernel = evenKernel(:,:,i)-mean(mean(evenKernel(:,:,i)));
    tmpKernel = tmpKernel/(norm(tmpKernel));
    normalizedEvenKernel(:,:,i) = tmpKernel;
end

%% show kernel images

allOutsOdd=[];
allOutsEven = [];
for i=1:6
    outRowOdd = [];
    outRowEven = [];
    for j=1:norient/6
        tmpKernel = normalizedOddKernel(:,:,(i-1)*norient/6+j);
        maxV = max(max(tmpKernel));
        minV = min(min(tmpKernel));
        tmpKernel = (tmpKernel - maxV)*255/(maxV-minV);
        outRowOdd = [outRowOdd, tmpKernel];
        
        tmpKernel = normalizedEvenKernel(:,:,(i-1)*norient/6+j);
        maxV = max(max(tmpKernel));
        minV = min(min(tmpKernel));
        tmpKernel = (tmpKernel - maxV)*255/(maxV-minV);
        outRowEven = [outRowEven, tmpKernel];
    end
    allOutsOdd = [allOutsOdd;outRowOdd];
    allOutsEven = [allOutsEven;outRowEven];
end
%imwrite(uint8(allOutsOdd),[outputPath, int2str(numOfValidFiles),'kernel_odd.bmp'], 'bmp');
%imwrite(uint8(allOutsEven),[outputPath, int2str(numOfValidFiles),'kernel_even.bmp'], 'bmp');
%   figure(300), imagesc(allOutsOdd),  title('odd gabor kernel','Interpreter','none')  , axis 'equal', colormap(gray)
%   figure(301), imagesc(allOutsEven),  title('even gabor kernel','Interpreter','none')  , axis 'equal', colormap(gray)


%%   convolution with gabor filter

filteredImgsOdd = zeros(imCopyH,imCopyW,norient*1);
filteredImgsEven = zeros(imCopyH,imCopyW,norient*1);
complexResponse = zeros(imCopyH,imCopyW,norient*1);
for i=1:norient
    filteredImgsOdd(:,:,i) = conv2(double(grayImg), normalizedOddKernel(:,:,i), 'same');
    filteredImgsEven(:,:,i) = conv2(double(grayImg), normalizedEvenKernel(:,:,i), 'same');
    complexResponse(:,:,i) = filteredImgsOdd(:,:,i).*filteredImgsOdd(:,:,i) + filteredImgsEven(:,:,i).*filteredImgsEven(:,:,i);
    complexResponse(:,:,i) = complexResponse(:,:,i)/(kerSize*kerSize);
end
%aveComplexResponse(1:10,1:10,1)
%aveComplexResponse(1:10,1:10,2)
%aveComplexResponse(1:10,1:10,3)

%%  the dominant orientation
confidenceMap = zeros(imCopyH,imCopyW);
confidenceMap1 = zeros(imCopyH,imCopyW);

orientationMap = zeros(imCopyH,imCopyW);
for i=1+halfKerSize:imCopyH-halfKerSize
    for j=1+halfKerSize:imCopyW-halfKerSize
        maxV = max(complexResponse(i,j,:));
        minV = min(complexResponse(i,j,:));
        complexResponseVector = (complexResponse(i,j,:)-minV)*100/(maxV-minV);
        maxLoc = find(complexResponseVector==100);
        if length(maxLoc)>0
            maxLoc = round(mean(maxLoc));
            if (maxLoc>2)&&(maxLoc<=34)
                complexResponseVector(maxLoc-2:maxLoc+2)=0;
            elseif (maxLoc<=2)
                complexResponseVector(maxLoc:maxLoc+2)=0;
            elseif (maxLoc>=35)
                complexResponseVector(maxLoc-2:maxLoc)=0;
            end
            
            [a,b] = sort(complexResponseVector,'descend');
            tmpContrast = (100 - mean(a(5:15)))^2;
            
            
            if maxV>1
                confidenceMap(i,j) = tmpContrast;
            end
        end
        
        maxma = max(complexResponse(i,j,:));
        indx = find(complexResponse(i,j,:)==maxma);
        orientationMap(i,j) = mean(indx); %%indx(1);
    end
end
%confidenceMap(1+halfKerSize:1+halfKerSize+20,1+halfKerSize:1+halfKerSize+20)
%%orientationMap = orientationMap.*(orientationMap<=36) + (orientationMap.*(orientationMap>36)-36);
orientationMap = (orientationMap-1)*angleInterval;
%orientationMap(1+halfKerSize:1+halfKerSize+20,1+halfKerSize:1+halfKerSize+20)

%  figure(5);
%   imshow(uint8(orientationMap));
% imwrite(uint8(orientationMap),[outputPath, int2str(numOfValidFiles),'vpOrientationMap0.bmp'], 'bmp');

maxV = max(max(confidenceMap(1+halfKerSize:imCopyH-halfKerSize,1+halfKerSize:imCopyW-halfKerSize)));
minV = min(min(confidenceMap(1+halfKerSize:imCopyH-halfKerSize,1+halfKerSize:imCopyW-halfKerSize)));
aaTmp = confidenceMap(1+halfKerSize:imCopyH-halfKerSize,1+halfKerSize:imCopyW-halfKerSize);
aaTmp = (aaTmp-minV)*255/(maxV-minV);
confidenceMap(1+halfKerSize:imCopyH-halfKerSize,1+halfKerSize:imCopyW-halfKerSize) = aaTmp;
% imwrite(uint8(confidenceMap),[outputPath, 'vpConfidence.bmp'], 'bmp');
%confidenceMap(1+halfKerSize:1+halfKerSize+20,1+halfKerSize:1+halfKerSize+20)

%  figure(106);
%  imshow(uint8(confidenceMap));


confidenceMapBinary = (confidenceMap>80);
% confidenceMapBinary1 = (confidenceMap>15);

doim = zeros(imCopyH, imCopyW, 3);
doim(:,:,1) = grayImgCopy;
doim(:,:,2) = grayImgCopy;
doim(:,:,3) = grayImgCopy;
doim(:,:,1) = doim(:,:,1).*(1-confidenceMapBinary) ;
doim(:,:,2) = doim(:,:,2).*(1-confidenceMapBinary)+ confidenceMapBinary*255;
doim(:,:,3) = doim(:,:,3).*(1-confidenceMapBinary);

% imwrite(uint8(doim),[outputPath, 'vpConfidenceOverlap.bmp'], 'bmp');
%  figure(107);
%   imshow(uint8(doim));


%% orientation bar
doim = grayImgCopy;
doim = zeros(imCopyH, imCopyW, 3);
doim(:,:,1) = grayImgCopy;
doim(:,:,2) = grayImgCopy;
doim(:,:,3) = grayImgCopy;


orientationMapDisplay = orientationMap;
for i=10:8:imCopyH-10
    for j=10:8:imCopyW-10
        ori = orientationMapDisplay(i,j);
        if (ori==90)
            yy = i;
            xx = j;
            doim(yy:yy+7,xx-1:xx+1,1) =0;
            doim(yy:yy+7,xx-1:xx+1,2) = 220;
            doim(yy:yy+7,xx-1:xx+1,3) = 0;
        elseif ori==0
            doim(i-1:i+1,j:j+7,1) = 0;
            doim(i-1:i+1,j:j+7,2) = 220;
            doim(i-1:i+1,j:j+7,3) = 0;
        else
            kk = tan(ori*pi/180);
            for xx=j:j+7
                yy = round(kk*(xx-j) + i);
                if (yy>=i-7)&&(yy<=i+7)
                    doim(yy,xx-1:xx+1,1) =0;
                    doim(yy,xx-1:xx+1,2) = 220;
                    doim(yy,xx-1:xx+1,3) = 0;
                end
            end
        end
        
    end
end

% imwrite(uint8(doim), [outputPath ,'vpOrientationBarImg.bmp'], 'bmp');
% figure(108);
% imshow(uint8(doim));


%%  voting
edgeImg = double(confidenceMapBinary);
[rowInd, colInd] = find(double(edgeImg)==1);
numOfEdgePixels = sum(sum(double(edgeImg)));

%confidenceMap = confidenceMap/255;

votingMap = zeros(imCopyH, imCopyW);
interval = 1;
uppPercent = 0.9;
borderWidth = halfKerSize;


half_largestDistence1 = largestDistence*0.7;
qualter_largestDistence1 = largestDistence*0.35;
R = imCopyH*0.35;


half_largestDistence2 = largestDistence*0.4;
qualter_largestDistence2 = largestDistence*0.25;

adaptiveDistUnit1 = (half_largestDistence1 - qualter_largestDistence1)/(imCopyH*0.9);
adaptiveDistUnit2 = (half_largestDistence2 - qualter_largestDistence2)/(imCopyH*0.4);

half_imCopyH = imCopyH*0.5;
half_largestDistence = largestDistence*0.5;

halfImgH = round(imCopyH*0.6);

distenceConst = zeros(imCopyH,1);
for i=1:round(imCopyH*0.4)
    distenceConst(i) = sqrt(imCopyW*imCopyW + halfImgH*halfImgH);
end
for i=round(imCopyH*0.4)+1:imCopyH
    distenceConst(i) = sqrt(imCopyW*imCopyW + (imCopyH+1-i)*(imCopyH+1-i));
end

% for i=1:imCopyH
%     distenceConst(i) = sqrt(imCopyW*imCopyW + (imCopyH+1-i)*(imCopyH+1-i));
% end

adaptiveDistence = largestDistence*0.5;

for i=1:interval:round(imCopyH*0.9) %%+round(imCopyH/4)
    %    adaptiveDistence = half_largestDistence1 - (adaptiveDistUnit1*i);
    for j=borderWidth+1:interval:imCopyW-borderWidth
        for ind=1:numOfEdgePixels
            
            if (sqrt((rowInd(ind)-i)^2+(colInd(ind)-j)^2)<=R) && (sqrt((rowInd(ind)-i)^2+(colInd(ind)-j)^2)>0) && (rowInd(ind) >= i)
                %                  if rowInd(ind) >= i
                %               if (rowInd(ind)>i)&&(rowInd(ind)<i+halfImgH)
                tmpI = rowInd(ind)-i;
                tmpJ = colInd(ind)-j;
                tempDist = sqrt(tmpJ*tmpJ+tmpI*tmpI);
                
                alpha = acos(tmpJ/tempDist)*180/pi;
                theta = orientationMap(rowInd(ind), colInd(ind)); %%orientationMap(ii, jj);
                angleDiffer = abs(alpha - theta);
                distRatio = tempDist/largestDistence ;
                angleThreshold = angleInterval/(1+2*distRatio);
                %                     tempAngleThreshold = angleInterval/(1+distRatio); %% + angleInterval*0.2;
                %                     if angleDiffer<=tempAngleThreshold
                %                        if tempDist<adaptiveDistence
                %                            votingMap(i,j) = votingMap(i,j)+exp(-angleDiffer*distRatio);
                %                        end
                %                     end
                
                if angleDiffer <= angleThreshold
                    %                        if tempDist<adaptiveDistence %%half_largestDistence %%
                    votingMap(i,j) = votingMap(i,j) + 1/(1+(angleDiffer*distRatio)^2); %%1/(1+(tempDist*angleDiffer/half_largestDistence)^2); %%;
                    %                        end
                end
                
            end
        end
    end
end
%votingMap


max_votingMap = max(max(votingMap(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imCopyW-borderWidth)));
min_votingMap = min(min(votingMap(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imCopyW-borderWidth)));
% votingMap1 = (max_votingMap-votingMap(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth))*255/(max_votingMap-min_votingMap);
votingMap1 = (votingMap(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imCopyW-borderWidth)-min_votingMap)*255/(max_votingMap-min_votingMap);
votingMap(1:interval:round(imCopyH*uppPercent),borderWidth+1:interval:imCopyW-borderWidth) = votingMap1;

% votingMap(1:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth) = 255-votingMap(1:round(imCopyH*uppPercent),borderWidth+1:interval:imgW-borderWidth);

tmpVotingMap = votingMap;

max_votingMap = max(max(tmpVotingMap(1:1:round(imCopyH*uppPercent),borderWidth+1:1:imCopyW-borderWidth)));
[r,c] = find(tmpVotingMap(1:1:round(imCopyH*uppPercent),borderWidth+1:1:imCopyW-borderWidth)==max_votingMap);

if length(r)>1
    r = round(mean(r));
    c = round(mean(c))+borderWidth;
else
    r = r;
    c = c+borderWidth;
end


% r_hough = r;
% c_hough = c;
% pause;


votingMapHH = votingMap;
% votingMapHH(2:2:imgH,:) = votingMapHH(1:2:imgH-1,:);
% votingMapHH(:,borderWidth+2:2:imgW-borderWidth) = votingMapHH(:,borderWidth+1:2:imgW-borderWidth-1);
votingMapBin = (votingMapHH>210);


vpX=c;%初始消失点
vpY=r;%初始消失点

%%%%%%%%%%%%%%
 
%
doim = colorImgCopy;
%% vp figure
coord3 = [r,c];
if (coord3(1)<=7)
    coord3(1) = 8;
end
if (coord3(1)>=180-8)
    coord3(1)=180-8;
end

if (coord3(2)<=7)
    coord3(2) = 8;
end

if (coord3(2)>=240-8)
    coord3(2) = 240-8;
end
y = coord3(1);
x = coord3(2);
doim(y-1:y+1,x-9:x+9,1) = 0;
doim(y-9:y+9,x-1:x+1,1) = 0;
doim(y-1:y+1,x-9:x+9,2) = 220;
doim(y-9:y+9,x-1:x+1,2) = 220;
doim(y-1:y+1,x-9:x+9,3) = 0;
doim(y-9:y+9,x-1:x+1,3) = 0;

% figure(109);
% imshow(uint8(doim));
% imwrite(uint8(doim),  'vp1Map_ini.bmp' , 'bmp');
 
%
votingArea = zeros(imCopyH,imCopyW);  %%%%%%%%%%%%%%%%%%%%%%%%%%%%% voting area
vanishingPointCandArea = zeros(imCopyH,imCopyW);
aOffsetVoteArea = round(imCopyH/12);
aOffsetVpCandArea = round(imCopyH/8);

 
 

end