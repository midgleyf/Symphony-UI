function [X Y] = calcEllipse(x,y,a,b,angle)
% calculate points for plotting ellipse
X=x+(a*cosd(0:360)*cosd(angle)-b*sind(0:360)*sind(angle));
Y=y+(a*cosd(0:360)*sind(angle)+b*sind(0:360)*cosd(angle));