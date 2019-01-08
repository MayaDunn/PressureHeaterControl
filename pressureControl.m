% Uses feedback on a heater to bring pressure to a set point
% Relies on other functions in folder to communicate with heater, create
% GUI, Execute PID loop etc. This file controls the timer that calls the
% PID loop and the GUI callbacks.
% Note - Previous setpoint = 4.165 K
% The steady state is around 24% with internal control
% Maya Dunn

%   4/6/15
%   Updated to accomadate a second heater using caller parameter and
%       arrays
%        - Fixed minor bug where Etotal was a 60x60 matrix
%   3/16/15
%   Updated to increase default Kp and SetPercentage and
%           decreased Ki by restricing the amount that can be added to the error
%           array. Also added a memory purge upon stopping.
%           - Planned changes: Save user inputted settings to a file,
%               remember last time data was taken and clear memory
%               if too much time has passed.        

function  pressureControl()
   % Timer Vatiables                 
    presTimer = [1, 1];
    timerRunning = [0, 0]; 
    
   % supress incorrect warning
           
   %GUI control variables 
    fig = pressureControlGUI();
        
    set(fig.stop,'Callback', {@stopPTimer, 1});
    set(fig.start,'Callback', {@resetPTimer, 1});
    set(fig.stop2,'Callback', {@stopPTimer, 2});
    set(fig.start2,'Callback', {@resetPTimer, 2});
    set(fig.GUI, 'CloseRequestFcn', @closeFigure);
    set(fig.changeSettings, 'callback', {@changeSettingsCallback});
    warning('off', 'instrument:query:unsuccessfulRead');
    
   %PID Control Variables
   pPIDSet = [0, 0, 0, 0; 0, 0, 0, 0];
    %if (exist('pPIDSet.dat', 'file'))
    %    load('pPIDSet.dat','-ascii', 'pPIDSet')
    %end
    if (pPIDSet(1) == 0)
        pPIDSet = [1.5        .24            .45    .07  ;
        %          setpoint,  set percent,   kP,    kI
                    1.5        .24            .45    .07];   
    end 
    set(fig.setPoint, 'String', num2str(pPIDSet(1, 1)));
    set(fig.kP, 'String', num2str(pPIDSet(1, 3)));
    set(fig.kI, 'String', num2str(pPIDSet(1, 4)));
    set(fig.setPoint2, 'String', num2str(pPIDSet(2, 1)));
    set(fig.steadyState2, 'String', num2str(pPIDSet(2, 2)));
    set(fig.kP2, 'String', num2str(pPIDSet(2, 3)));
    set(fig.kI2, 'String', num2str(pPIDSet(2, 4)));
    labels = [fig.runningLabel, fig.runningLabel2];
    delays = [fig.delay, fig.delay2];
    readouts = [fig.readout, fig.readout2];
    Etotal = [0, 0];                                                             % Integrated Error
    errorMemory = zeros(2, 60);                                             % Only integrate error from last minute 
    j = 1;                                                                  % Error Memory Index
    callskipped = 0;
    
   %Heater Control Variables
    input = 1;% For  A
    output1 = 1;          
    zoneupperlimit = 4.30;
    zonelowerlimit = 4.05;
    
    previousHeaterPercent = 0;
    
    
    % The actual PID loop can be called from the GUI
    % Turned this into a callback function
    function pressureControlLoop(~,~, caller)
        readouts(caller).ForegroundColor = 'blue';
        if (caller == 1)
            p = cryostatPressure();
        else
            p = str2double(lakeshoreQuery('KRDG? B'));
        end
        
        % error
        if (p>(-50))
            out = runPID(p, pPIDSet(caller, 1), pPIDSet(caller, 1),...
                                         pPIDSet(caller, 1), pPIDSet(caller, 1), errorMemory(caller, :), Etotal(caller), j);
            
            heaterPercent = out(1);
            Etotal(caller) = out(2);
            heaterPercent = round(heaterPercent * 10000) / 100;                  % to 2 decimals

            if (p < .2) 
                stopPTimer(caller)
            end

            if (heaterPercent ~= previousHeaterPercent)
                setHeater(heaterPercent, zoneupperlimit, zonelowerlimit, caller);
                pressure = [num2str(heaterPercent) ', ' num2str(p)];
                set(fig.readout, 'String', pressure)
                previousHeaterPercent = heaterPercent;
            end
            j = j + 1;
            callskipped = 0;
        else
            callskipped = callskipped + 1;
            if(callskipped > 120/str2double(get(delays(caller), 'String')))      %wait 2 minutes
                warning('Pressure cannot be read')
                stopPTimer(caller)
            end
        end
        readouts(caller).ForegroundColor = 'black';
    end

    % modified from MagnetLog
    function resetPTimer(~,~, caller)
        delay = str2double(get(delays(caller), 'String'));                       % delay time - from GUI
        set(labels(caller), 'String', 'Initializing');
        presTimer(caller) = timer('Name', 'pressureControl1Timer',...
                'ExecutionMode', 'FixedSpacing', 'Period', delay);
        presTimer(caller).TimerFcn = {@pressureControlLoop, caller};
        presTimer(caller).StopFcn = {@timerStopFcn, caller};
        if ((caller == 1 && switchPIDVals(input, output1, 0, 0, 0)) || caller == 2)
            start(presTimer(caller));
            set(labels(caller), 'String', 'Running');
            timerRunning(caller) = 1;
        else
            set(labels(caller), 'String', 'Not Running');
            errordlg('Not able to change heater settings. Will not start.')
        end
    end
    
    function changeSettingsCallback(~,~)
         pPIDSet(1, 1) = str2double(get(fig.setPoint, 'String')); %%%
         pPIDSet(1, 3) = str2double(get(fig.kP, 'String'));
         pPIDSet(1, 4) = str2double(get(fig.kI, 'String')); %%%%%%%%
         pPIDSet(2, 1) = str2double(get(fig.setPoint2, 'String'));
         pPIDSet(2, 2) = str2double(get(fig.steadyHeating, 'String'));
         pPIDSet(2, 3) = str2double(get(fig.kP2, 'String'));
         pPIDSet(2, 4) = str2double(get(fig.kI2, 'String'));
         stop(presTimer(1));
         presTimer(1).Period = str2double(get(fig.delay, 'String'));
         
         stop(presTimer(2));
         presTimer(2).Period = str2double(get(fig.delay2, 'String')); 
    end

    % stop the PID loop and give the heater back executive control.
    function restoreSucess = stopPTimer(~,~, caller)
        %save pPIDSet.dat pPIDSet
        if (timerRunning(caller) == 0)                                              %Don't try to turn the timer off if it hasn't started
            restoreSucess = 1;
            errorMemory = zeros(60);                                        % Delete Memory
        else
            if (caller == 1)
                restoreSucess = restore();
            else
                restoreSucess = 1; %%% use this space to add a restore for the other heater.
            end
            if (restoreSucess)
                stop(presTimer(caller));
                timerRunning(caller) = 0;
                set(labels(caller), 'String', 'Not Running');
                errorMemory = zeros(2, 60);
            else
                errordlg('Failed change heater settings.')
            end
        end
    end

    function timerStopFcn(~,~, caller)
        if (timerRunning(caller) ~= 0)                                              %Don't try to turn the timer off if it hasn't started
            timerRunning(caller) = 0;
            stop(presTimer(caller));
        end
    end

    % restore the heater to its normal PID values instead of 0.
    % Indirectly returns 1 if able, 0 if not
    function sucess = restore()
        normalP = 50;
        normalI = 200;
        normalD = 0;
        sucess = switchPIDVals(input, output1, normalP, normalI, normalD);
        setHeater(0, 325, 0, output1);
    end
    
    % Callback function for when the window is closed. Makes sure that the
    % heater is controlling itself.
    function closeFigure(~,~)
        % Clean up things
        if (stopPTimer(1))
            delete(presTimer(1));
            if (stopPTimer(2))
                delete(presTimer(2));
                delete(fig.GUI);
                warning('on', 'instrument:query:unsuccessfulRead');
            end
        end
    end
end