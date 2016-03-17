function [ dis ] = point_distance( x,y, point1,point2 )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

a=[x,y];
b=[point1(1), point1(2)  ];
c=[point2(1), point2(2)    ];
ab=sqrt((a(1,1)-b(1,1))^2+(a(1,2)-b(1,2))^2);
ac=sqrt((a(1,1)-c(1,1))^2+(a(1,2)-c(1,2))^2);
bc=sqrt((c(1,1)-b(1,1))^2+(c(1,2)-b(1,2))^2);
cos_theta=(ab^2+bc^2-ac^2)/(2*ab*bc);
dis=ab*sqrt(1-cos_theta*cos_theta);




end

