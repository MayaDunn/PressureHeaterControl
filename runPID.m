 % Controls Pressure through temperature. Returns the next heater percent
 % set point setPoint
 % Maya Dunn
 
% Last Updated - 3/16/15
 
    function  [heatpercent, Etotal] = runPID(p, setPoint, setPercentage,...
                                         Kp, Ki, errorMemory, Etotal, j)
        E = (setPoint - p);                             
        addedError = E;                                                     % only use Ki to correct steady state so as to restrict overshoot
        if (addedError > .5)
            addedError = .5;
        elseif (addedError < -.5)
            addedError = -.5;
        end
        errorMemory(floor(mod(j, length(errorMemory)))+1) = addedError;
        Etotal = Etotal + addedError - errorMemory(floor(mod(j+1, length(errorMemory)))+1);           % goes to zero
        heatpercent = Kp*(E) + Ki*Etotal + setPercentage;
        if (heatpercent > .45)
            heatpercent = .45;
        elseif (heatpercent < 0)
            heatpercent = 0;
        end
    end
