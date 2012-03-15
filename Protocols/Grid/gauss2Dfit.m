function [RFstring muX muY sigmaX sigmaY]=gauss2Dfit(Xcoords,Ycoords,meanResp)
    x=Xcoords(1):-1:Xcoords(end);
    y=Ycoords(1):Ycoords(end);
    objSize=Ycoords(2)-Ycoords(1);
    meanRespIntp=interp2(Xcoords,Ycoords,meanResp,x,y','linear');
    errorFunc=@(p) sum((meanRespIntp(:)-gauss2D(p,x,y)).^2);
    peakResp=max(meanRespIntp(:));
    [peakYindex peakXindex]=find(meanRespIntp==peakResp);
    peakX=x(round(mean(peakXindex)));
    peakY=y(round(mean(peakYindex)));
    halfPeakDiff=abs(meanRespIntp-0.5*peakResp);
    [halfPeakDistYindex halfPeakDistXindex]=find(halfPeakDiff==min(halfPeakDiff(:)));
    halfPeakDistX=abs(peakX-x(round(mean(halfPeakDistXindex))));
    halfPeakDistY=abs(peakY-y(round(mean(halfPeakDistYindex))));
    seedValues=[peakResp*10,peakX,peakY,halfPeakDistX,halfPeakDistY];
    fitParams=fminsearch(errorFunc,seedValues,optimset('MaxFunEvals',1e5));
    roundFitParams=round(fitParams*10)/10;
    RFstring=['RF: center [' num2str(roundFitParams(2)) ',' num2str(roundFitParams(3)) '], sd [' num2str(roundFitParams(4)) ',' num2str(roundFitParams(5)) ']'];
    % convert mu and sigma from degrees to image pixel coordinates
    [~,muX]=min(abs(x-fitParams(2)));
    muX=(muX-1)/objSize+1;
    [~,muY]=min(abs(fliplr(y)-fitParams(3)));
    muY=(muY-1)/objSize+1;
    pixPerDeg=(numel(Ycoords)-1)/(Ycoords(end)-Ycoords(1));
    sigmaX=fitParams(4)*pixPerDeg;
    sigmaY=fitParams(5)*pixPerDeg;
end

function z=gauss2D(p,x,y)
    z=zeros(numel(y),numel(x));
    for i=1:numel(y)
        for j=1:numel(x)
            % p(1:5)=[A,muX,muY,sigmaX,sigmaY]
            z(i,j)=(p(1)/(2*pi*p(4)*p(5)))*exp(-((((x(j)-p(2))^2)/(2*p(4)^2))+(((y(i)-p(3))^2)/(2*p(5)^2))));
        end
    end
    z=z(:);
end
