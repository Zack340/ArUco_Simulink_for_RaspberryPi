classdef aruco_raspi_wrapper < realtime.internal.SourceSampleTime ...
        & coder.ExternalDependency ...
        & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.CustomIcon

    %#codegen
    %#ok<*EMCA>
    
    properties
        % Public, tunable properties.
    end
    
    properties (Nontunable)
        markLength = 0.1; % Marker length (m)
        dictionary = 'DICT_ARUCO_ORIGINAL'; % ArUco dictionary
        camSource = 0; % Camera source
        calibFile = '/home/pi/calibration.yml'; % Calibration source
        samplingTime = 0.2; % SampleTime(sec)
    end
        
    properties(Nontunable, PositiveInteger)
        arraySize = 4; % Array row size
        capWidth = 640; % Width (px)
        capHeight = 480; % Height (px)
    end
    
    properties (Nontunable, Logical)
        isOutCorners = true; % Enable corner data
        isOutVectors = false; % Enable vectors data
        isOutImage = false; % Enable post image data
    end
    
    properties (Constant, Hidden)      
        dictionarySet = matlab.system.StringSet({'DICT_4X4_50', 'DICT_4X4_100',...
                'DICT_4X4_250', 'DICT_4X4_1000', 'DICT_5X5_50', 'DICT_5X5_100',...
                'DICT_5X5_250', 'DICT_5X5_1000', 'DICT_6X6_50', 'DICT_6X6_100',...
                'DICT_6X6_250', 'DICT_6X6_1000', 'DICT_7X7_50', 'DICT_7X7_100',...
                'DICT_7X7_250', 'DICT_7X7_1000', 'DICT_ARUCO_ORIGINAL',...
                'DICT_APRILTAG_16h5', 'DICT_APRILTAG_25h9',...
                'DICT_APRILTAG_36h10', 'DICT_APRILTAG_36h11'});
        outputName = {'status', 'ids', 'corners', 'rvecs', 'tvecs', 'image'};
        outputType = {'boolean', 'int32', 'single', 'double', 'double', 'uint8'};
    end
    
    properties (Access = private)
        dictionaryId = uint8(0);
        dictionaryName = {'DICT_4X4_50', 'DICT_4X4_100',...
                'DICT_4X4_250', 'DICT_4X4_1000', 'DICT_5X5_50', 'DICT_5X5_100',...
                'DICT_5X5_250', 'DICT_5X5_1000', 'DICT_6X6_50', 'DICT_6X6_100',...
                'DICT_6X6_250', 'DICT_6X6_1000', 'DICT_7X7_50', 'DICT_7X7_100',...
                'DICT_7X7_250', 'DICT_7X7_1000', 'DICT_ARUCO_ORIGINAL',...
                'DICT_APRILTAG_16h5', 'DICT_APRILTAG_25h9',...
                'DICT_APRILTAG_36h10', 'DICT_APRILTAG_36h11'};
    end
       
methods
        % Constructor
        function obj = Source(varargin)
            % Support name-value pair arguments when constructing the object.
            setProperties(obj,nargin,varargin{:});
        end

    end
    
    methods (Access=protected)
        function setupImpl(obj) %#ok<MANU>
            if isempty(coder.target)
                % Place simulation setup code here
            else
                % Call C-function implementing device initialization
                coder.cinclude('aruco_raspi_wrapper.hpp');
                
                for i = 1:length(obj.dictionaryName)
                    if(strcmp(obj.dictionary, obj.dictionaryName{i}))
                        obj.dictionaryId = uint8(i-1);
                    end
                end
                
                [width, height] = getImageRatio(obj);
                params = struct('markLength', obj.markLength,... 
                                'samplingTime', obj.samplingTime,...
                                'dictionaryId', uint8(obj.dictionaryId),...
                                'arraySize', uint8(obj.arraySize),...
                                'capWidth', uint16(obj.capWidth),...
                                'capHeight', uint16(obj.capHeight),...
                                'imgWidth', width,...
                                'imgHeight', height,...
                                'camSource', int32(obj.camSource),...
                                'isOutCorners', obj.isOutCorners,...
                                'isOutVectors', obj.isOutVectors,...
                                'isOutImage', obj.isOutImage);
                str1 = char(obj.calibFile);
                str1Size = uint8(size(str1, 2));
                
                coder.cstructname(params, 'Parameters', 'extern', 'HeaderFile', 'aruco_raspi_wrapper.hpp');
                coder.ceval('setup', coder.ref(params), coder.ref(str1), str1Size);
            end
        end
        
        function varargout = stepImpl(obj)   %#ok<MANU>
            [width, height] = getImageRatio(obj);
            u1 = zeros(obj.arraySize, 1, obj.outputType{2});
            u2 = zeros(obj.arraySize, 4, 2, obj.outputType{3});
            u3 = zeros(obj.arraySize, 3, obj.outputType{4});
            u4 = zeros(obj.arraySize, 3, obj.outputType{5});
            u5 = zeros(width, height, 3, obj.outputType{6});
            y = false;
            
            if isempty(coder.target)
                % Place simulation output code here
            else
                % Call C-function implementing device output
                y = coder.ceval('getData', coder.ref(u1), coder.ref(u2), coder.ref(u3),...
                                           coder.ref(u4), coder.ref(u5));
            end
            
            u = {y, u1, u2, u3, u4, u5};
            
            index = getOutputIndex(obj);
            j = 1;
            for i = 1:length(index)
                if index(i)
                    varargout{j} = u{i};
                    j = j + 1;
                end
            end
        end
        
        function releaseImpl(obj) %#ok<MANU>
            if isempty(coder.target)
                % Place simulation termination code here
            else
                % Call C-function implementing device termination
                coder.ceval('release');
            end
        end
        
        function index = getOutputIndex(obj)
            index = [true, true, obj.isOutCorners,...
                     obj.isOutVectors , obj.isOutVectors, obj.isOutImage];
        end
        
        function size = getOutputSizes(obj)
            [width, height] = getImageRatio(obj);
            size = {[1, 1], [obj.arraySize, 1], [obj.arraySize, 4, 2],...
                    [obj.arraySize, 3], [obj.arraySize, 3], [width, height, 3]};
        end
        
        function [width, height] = getImageRatio(obj)
            maxPixel = 500000;
            width = uint16(obj.capWidth);
            height = uint16(obj.capHeight);
            if ~obj.isOutImage
                width = uint16(1);
                height = uint16(1);
            elseif obj.capWidth * obj.capHeight > maxPixel
                ratio = realsqrt(maxPixel / (obj.capWidth * obj.capHeight));
                width = uint16(obj.capWidth * ratio);
                if rem(width, 2) == 1
                    width = width - 1;
                end
                height = uint16(obj.capHeight * ratio);
                if rem(height, 2) == 1
                    height = height - 1;
                end
            end
        end
    end
    
    methods (Access=protected)
        %% Define output properties
        function num = getNumInputsImpl(~)
            num = 0;
        end
        
        function num = getNumOutputsImpl(obj)
            num = sum(getOutputIndex(obj));
        end
        
        function flag = isOutputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputFixedSizeImpl(obj,~)
            for i = 1:sum(getOutputIndex(obj))
                varargout{i} = true;
            end
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputComplexImpl(obj)
            for i = 1:sum(getOutputIndex(obj))
                varargout{i} = false;
            end
        end
        
        function varargout = getOutputSizeImpl(obj)
            index = getOutputIndex(obj);
            size = getOutputSizes(obj);
            j = 1;
            for i = 1:length(index)
                if index(i)
                    varargout{j} = size{i};
                    j = j + 1;
                end
            end
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            index = getOutputIndex(obj);
            j = 1;
            for i = 1:length(index)
                if index(i)
                    varargout{j} = obj.outputType{i};
                    j = j + 1;
                end
            end
        end
        
        function varargout = getOutputNamesImpl(obj)
            index = getOutputIndex(obj);
            j = 1;
            for i = 1:length(index)
                if index(i)
                    varargout{j} = obj.outputName{i};
                    j = j + 1;
                end
            end
        end
        
        function icon = getIconImpl(obj)
            % Define a string as the icon for the System block in Simulink.
            name = 'ArUco\nMarkerDetection';
            if obj.isOutVectors
                name = 'ArUco\nPoseEstimation';
            end
            icon = {name, '', ['Marker length: ', num2str(obj.markLength), ' m'],...
                              ['Dictionary: \n', obj.dictionary],...
                              ['Dimension: ', num2str(obj.capWidth), ' x ', num2str(obj.capHeight)]};
        end
        
        function sts = getSampleTimeImpl(obj)
            sts = createSampleTime(obj, 'Type', 'Discrete', 'SampleTime', obj.samplingTime);
        end
    end
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
    end
    
    methods (Static, Access=protected)
        function header = getHeaderImpl
            % Define header panel for System block dialog
           header = matlab.system.display.Header(...
               mfilename('class'), 'Title', aruco_raspi_wrapper.getDescriptiveName());
        end
        
        function groups = getPropertyGroupsImpl
           configGroup = matlab.system.display.Section(...
               'Title', 'General configuration', 'PropertyList', {'markLength', 'dictionary', 'samplingTime'});
           subOutputGroup1 = matlab.system.display.Section(...
               'Title','Number of detections', 'PropertyList', {'arraySize'});
           subOutputGroup2 = matlab.system.display.Section(...
               'Title','Detecting data', 'PropertyList', {'isOutCorners', 'isOutVectors'});
           subOutputGroup3 = matlab.system.display.Section(...
               'Title','Image', 'PropertyList', {'isOutImage'});
           outputGroup = matlab.system.display.SectionGroup(...
               'Title','Output', 'Sections', [subOutputGroup1, subOutputGroup2, subOutputGroup3]);
           subCameraGroup1 = matlab.system.display.Section(...
               'Title','Source', 'PropertyList', {'camSource', 'calibFile'});
           subCameraGroup2 = matlab.system.display.Section(...
               'Title', 'Resolution', 'PropertyList', {'capWidth', 'capHeight'}); 
           cameraGroup = matlab.system.display.SectionGroup(...
               'Title','Camera', 'Sections',[subCameraGroup1, subCameraGroup2]);
           groups = [configGroup, outputGroup, cameraGroup];
        end
        
        function flag = isInactivePropertyImpl(obj, propertyName)
            if strcmp(propertyName, 'calibFile')
                flag = ~obj.isOutVectors;
            else
                flag = false;
            end
        end
        
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'aruco_raspi_wrapper';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % Update buildInfo
                srcDir = fullfile(fileparts(mfilename('fullpath')),'src'); %#ok<NASGU>
                includeDir = fullfile(fileparts(mfilename('fullpath')),'include');
                addIncludePaths(buildInfo,includeDir);
                % Use the following API's to add include files, sources and
                % linker flags
                addSourceFiles(buildInfo,'aruco_raspi_wrapper.cpp', srcDir);
                addSourceFiles(buildInfo,'aruco_raspi.cpp', srcDir);
                addCompileFlags(buildInfo,'-O3');
                addCompileFlags(buildInfo,'-fopenmp');
                addCompileFlags(buildInfo,'-mcpu=cortex-a53');
                addCompileFlags(buildInfo,'-mcpu=cortex-a72');
                addCompileFlags(buildInfo,'-mfpu=neon-fp-armv8');
                addCompileFlags(buildInfo,'-mfloat-abi=hard');
                addLinkFlags(buildInfo,'-lopencv_core');
                addLinkFlags(buildInfo,'-lopencv_aruco');
                addLinkFlags(buildInfo,'-lopencv_videoio');
                addLinkFlags(buildInfo,'-lopencv_imgproc');
                addLinkFlags(buildInfo,'-fopenmp');
            end
        end
    end
end
