% Function to set heater inside a particular zone
% Note that percentage will add to whatever the heater is 
% telling itself to do.
% refuses to change if the temperature is too high or too low.
% Maya Dunn 3/2016

function response = setHeater(percent, tupperlimit, tlowerlimit, output)
   %query = ['OUTMODE ' num2str(output) ',2,' num2str(input) ',0']
   %response = lakeshoreQuery(query)
    try
        temp = str2num(lakeshoreQuery('KRDG? A'));
        if(temp < tupperlimit && temp > tlowerlimit) 
           query = ['MOUT ' num2str(output) ',' num2str(percent)];
           lakeshoreQuery(query);
           response = 1;
        else
           response = 0;
        end

    catch err
       warning('Error setting heater!')
    end
end