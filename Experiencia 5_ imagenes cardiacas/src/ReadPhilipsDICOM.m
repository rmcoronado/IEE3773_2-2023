function [metadata] = ReadPhilipsDICOM(path,TYPES)

    fprintf(sprintf('\n Reading DICOM file "%s"',path))

    % image types
    if nargin < 2
        TYPES = {'MAGNITUDE'};
    end

    % DICOM info
    SV = double(squeeze(dicomread(path)));
    info = dicominfo(path);
    
    %% rescale slope and intercept        
    % fieldnames
    fnames = fieldnames(info.PerFrameFunctionalGroupsSequence);
    
    % image size and number of frames
    Isz = size(SV);
    Nfr = info.NumberOfFrames;

    % user defined type indices
    ntps = numel(TYPES);
    indices = {};
    for i=1:ntps
        indices.(TYPES{i}) = NaN([1 Nfr]);
    end
   
    % copy types as struct
    TYPES_tmp = cell2struct(cell(1,ntps),TYPES,2);

    % scaling loop
    for i=1:Nfr
        
        % frame info
        info.PerFrameFunctionalGroupsSequence
        frinfo = info.PerFrameFunctionalGroupsSequence.(fnames{i});

        % frame type
        imageType = frinfo.MRImageFrameTypeSequence.Item_1.ComplexImageComponent;

        try
            TYPES_tmp.(imageType);
            indices.(imageType)(i) = 1;

            % slope and intercept
            m = double(frinfo.PixelValueTransformationSequence.Item_1.RescaleSlope);
            b = double(frinfo.PixelValueTransformationSequence.Item_1.RescaleIntercept);
            SV(:,:,i) = m*SV(:,:,i) + b;

        catch            
        end
        
    end
    
    % Output
    metadata = struct(...
        'DICOMInfo',    info);
    for i=1:ntps

        % metadata
        metadata.(TYPES{i}) = SV(:,:,~isnan(indices.(TYPES{i})));

    end


end