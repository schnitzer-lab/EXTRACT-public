function extractPath = whichEXTRACT()
% WHICHEXTRACT - returns the path to the EXTRACT root directory
%
% RD = WHICHEXTRACT()
%
% Returns the path to the EXTRACT toolbox root directory.
%

extractPath = fileparts(mfilename("fullpath"));
