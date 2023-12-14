function I = imbalance_ratio(Vbid_volume,Vask_volume)
%Imbalance is a ratio of limit order volumes between the bid and ask side
%this function assumes 1 timestep
x=1:length(Vbid_volume);
weight=exp(-.5.*x);
Vbid=sum(weight.*Vbid_volume);
if Vbid_volume ~= Vask_volume
    x=1:length(Vask_volume);
    weight=exp(-.5.*x);
end
Vask=sum(weight.*Vask_volume);
I=(Vbid-Vask) / (Vbid+Vask);
end

