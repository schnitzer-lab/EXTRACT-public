function b = ismatlabonline()
% ISMATLABONLINE - are we running on Matlab Online?
%
% B = ISMATLABONILNE()
%
% Returns 1 if we are running on Matlab Online. This function tests whether
% we are running on Linux (isunix() == 1 & ismac() == 0) and
% if userpath == '/MATLAB DRIVE'.
%

b = (isunix()==1) & ...
    (ismac()==0) & ...
    strcmp(userpath,'/MATLAB Drive');

