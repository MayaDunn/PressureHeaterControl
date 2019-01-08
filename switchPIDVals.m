% Change the heater's inernal PID values.
% returns 1 if values were updated, 0f they were not. Default 0.
% Used in pressure control to toggle between manual (1, 1, 0, 0, 0)
% and the system's normal settings (1, 1, 10, 200, 0)
% Maya Dunn 3/2016

function sucess = switchPIDVals(input, output, P, I, D)
    sucess = 0;
    q1 = ['PID ' num2str(output) ',' num2str(P) ',' num2str(I) ',' num2str(D)];
    lakeshoreQuery(q1);
    testChange = ['PID? ' num2str(output)];
    pidvals = strsplit(lakeshoreQuery(testChange), ',');
    if (str2double(pidvals(1)) == P && str2double(pidvals(2)) == I && ...
            str2double(pidvals(3)) == D)
        sucess = 1;
    end
end