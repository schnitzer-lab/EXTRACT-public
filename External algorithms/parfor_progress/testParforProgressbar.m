% 'numIterations' is an integer with the total number of iterations in the loop.
% Feel free to increase this even higher and see other progress monitors fail.
numIterations = 1000;
complexity = 2000;
res = zeros(numIterations, 1);

% Then construct a ParforProgMon object and provide the total number of
% iterations
% ppm = ParforProgressbar(numIterations); 
% Or show the progress of each individual worker too
% ppm = ParforProgressbar(numIterations,'showWorkerProgress',true); 
% Or maybe update the progressbar only every 3 seconds to save some time
% and give the total progress a fany name.
% ppm = ParforProgressbar(numIterations,'showWorkerProgress',true,'progressBarUpdatePeriod',3,'title','my fancy title'); 
% Or set the parpool parameter manually
ppm = ParforProgressbar(numIterations, 'parpool', {'local', 4});

pauseTime = 60/numIterations;

tic
parfor i = 1:numIterations
    % do some parallel computation
%     res(i) = mean(rand(complexity),[1 2]);
    pause(pauseTime);
    % increment counter to track progress
    ppm.increment();
end
toc

% Delete the progress handle when the parfor loop is done. 
delete(ppm);
  
%%
file_line = {{'fileA.txt',3},{'fileA.txt',5},{'fileB.txt',2}}; % probably much bigger
sz = length(file_line);
result = cell(sz, 1);
ppm = ParforProgressbar(sz);
parfor i = 1 : sz
    filename = file_line{i}{1};
    userData = ppm.getUserData();
    if(isempty(userData) || ~strcmp(userData{1}, filename))
        data = my_open_file_slow(filename);
        ppm.setUserData({filename, data});
    else
        data = userData{2};
    end
    result{i} = my_process_line_fast(data, file_line{i}{2});
end
delete(ppm)

function data = my_open_file_slow(filename)
    data = filename;
end
function res = my_process_line_fast(data, line)
    res = 1;
end