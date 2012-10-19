%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [RFstring muX muY sigmaX sigmaY rotationAngle]=gauss2Dfit(Xcoords,Ycoords,meanResp)
x=Xcoords(1):-1:Xcoords(end);
y=Ycoords(1):Ycoords(end);
meanRespIntp=interp2(Xcoords,Ycoords,meanResp,x,y','linear');
errorFunc=@(p) sum((meanRespIntp(:)-gauss2D(p,x,y)).^2);
peakResp=max(meanRespIntp(:));
[peakYindex peakXindex]=find(meanRespIntp==peakResp);
peakX=x(round(mean(peakXindex)));
peakY=y(round(mean(peakYindex)));
halfPeakDiff=abs(meanRespIntp-0.6*peakResp);
[halfPeakDistYindex halfPeakDistXindex]=find(halfPeakDiff==min(halfPeakDiff(:)));
halfPeakDistX=abs(peakX-x(round(mean(halfPeakDistXindex))));
halfPeakDistY=abs(peakY-y(round(mean(halfPeakDistYindex))));
seedValues=[peakResp*2*pi*halfPeakDistX*halfPeakDistY,peakX,peakY,halfPeakDistX,halfPeakDistY,0];
fitParams=fminsearch(errorFunc,seedValues,optimset('MaxFunEvals',1e5,'MaxIter',1e5));
fitR=corrcoef(meanResp,gauss2D(fitParams,Xcoords,Ycoords));
fitRsq=round((fitR(1,2)^2)*100)/100;
roundFitParams=round(fitParams*10)/10;
RFstring=['RF: center [' num2str(roundFitParams(2)) ',' num2str(roundFitParams(3)) '], sd [' num2str(roundFitParams(4)) ',' num2str(roundFitParams(5)) '], rotation ' num2str(roundFitParams(6)) ' deg, fit r sq = ' num2str(fitRsq)];
rotationAngle=roundFitParams(6);
% convert mu and sigma from degrees to image pixel coordinates
pixPerDeg=(numel(Ycoords)-1)/(Ycoords(end)-Ycoords(1));
muX=pixPerDeg*(x(1)-fitParams(2))+1;
muY=pixPerDeg*(y(end)-fitParams(3))+1;
sigmaX=fitParams(4)*pixPerDeg;
sigmaY=fitParams(5)*pixPerDeg;


function z=gauss2D(p,x,y)
coords=allcombs(x,y);
% p(1:6)=[V,muX,muY,sigmaX,sigmaY,theta]
% 2D gauss with rotation, http://en.wikipedia.org/wiki/Gaussian_function
z = (p(1)/(2*pi*p(4)*p(5)))*exp(-(...
    ((cosd(p(6))^2)/(2*p(4)^2)+(sind(p(6))^2)/(2*p(5)^2))*((coords(:,1)-p(2)).^2) +...
    2*((sind(2*p(6)))/(4*p(4)^2)+(sind(2*p(6)))/(4*p(5)^2))*(coords(:,1)-p(2)).*(coords(:,2)-p(3)) +...
    ((sind(p(6))^2)/(2*p(4)^2)+(cosd(p(6))^2)/(2*p(5)^2))*((coords(:,2)-p(3)).^2)...
    ));
% 2D gauss without rotation
% z=(p(1)/(2*pi*p(4)*p(5)))*exp(-((((coords(:,1)-p(2)).^2)/(2*p(4)^2))+(((coords(:,2)-p(3)).^2)/(2*p(5)^2))));
