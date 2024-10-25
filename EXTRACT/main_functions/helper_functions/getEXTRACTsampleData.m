function filename = getEXTRACTsampleData(datasetname)
% getEXTRACTsampleData - get a dataset filename, downloading if necessary
%
% FILENAME = GETEXTRACTSAMPLEDATA(DATASETNAME)
%
% Obtain a filename for a known dataset. The file will be downloaded if
% necessary.
%
% Right now, we only know DATASETNAME == 'jones.h5'
%
     % in the future, this function should just look up the datasets in a
     % json file
switch(datasetname),
    case 'jones.h5',
        if ~ismatlabonline()
            filename = char(fullfile(whichEXTRACT(),"Learning-materials",...
                "Sample data","jones.h5")); 
            if ~exist(filename,'file')
                disp(['Downloading 2.93 GB data file jones.h5'])
                websave(filename,'https://wds-matlab-community-toolboxes.s3.amazonaws.com/EXTRACT/jones.h5');
            end;
        else,
            filename = char(fullfile(whichEXTRACT(),"Learning-materials",...
                "Sample data","jones_small.h5")); 
            if ~exist(filename,'file')
                disp(['Downloading 750 MB data file jones_small.h5'])
                copyfile('s3://wds-matlab-community-toolboxes/EXTRACT/jones_small.h5',filename);
            end;
        end;
    otherwise,
        error(['Unknown dataset ' datasetname '.']);
end;

