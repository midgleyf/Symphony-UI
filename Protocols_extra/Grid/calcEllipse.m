%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [X Y] = calcEllipse(x,y,a,b,angle)
% calculate points for plotting ellipse
X=x+(a*cosd(0:360)*cosd(angle)-b*sind(0:360)*sind(angle));
Y=y+(a*cosd(0:360)*sind(angle)+b*sind(0:360)*cosd(angle));