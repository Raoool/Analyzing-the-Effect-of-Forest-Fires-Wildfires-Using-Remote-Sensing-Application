%% Code for Analyzing the Effect of Forest Fires / Wildfires Using Remote Sensing Application
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                 %
%               Author : Rahul Shah                               %
%                                                                 %
%     This script read satellite images (Landsat 8 Image),        %  
%   process metadata, calculate Surface Reflectance, NDVI, Burn   % 
%   Severity and information from the data.                       %
%                                                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



clear; close all; clc;

if ispc
    filepath = ('Z:\ImageDrive\OLI.TIRS\L8\P043\R033');
elseif isunix
    filepath = ('/home/rahul.shah/zdrive/ImageDrive/OLI.TIRS/L8/P043/R033');
end

date = dir(filepath);
date ([1 2])= [];

for dates = 100:148
    for bands = 1:7 %number of bands
        if exist(fullfile(filepath,date(dates).name,'L2C2'), 'dir')
            date_dir = dir(fullfile(filepath,date(dates).name,'L2C2'));
            %date_dir ([ 13 14 26 29 43 52 53 54 57]) = [];%deleting dates with no L1C2
            ImB1file = dir(fullfile(filepath,date(dates).name,'L2C2','*B1.TIF')); %listing the file of band 1
            Imfiles = dir(fullfile(filepath,date(dates).name,'L2C2',[ImB1file.name(1:end-5),num2str(bands),'.TIF']));
            disp('Read Image');
            [A, R] = geotiffread(fullfile(Imfiles.folder,Imfiles.name)); % reading the tif file from band 1 to 7, and getting the name of the file, except the last five characters that are the name of the band
            % Matrix A are Digital Numbers (DN) and R-Spatial referncing object
            disp('geotifread Image');
            Mtl = dir(fullfile(filepath,date(dates).name,'L2C2','*MTL.txt')); % reading the metadata .json file
            [MTL_list,value] = MTL_parser_L8(fullfile(Mtl.folder,Mtl.name)); %reading the files as text
            disp('Read Metadata File');
            RMUL = 2.75e-05; %reading the reflectance multiplicative factor
            RADD = -0.2; %reading the reflectance additive factor
            
            acq_date = MTL_list.PRODUCT_METADATA.DATE_ACQUIRED; %reading acquired date from metadata file
            disp('date of acquisition read');
            DecimalYear(dates) = str2dec_yr(acq_date); %converting date to day of decimal year
            DateStr = datevec(acq_date); %date vectors
            DayofYear(dates) = getDOY(DateStr(1,1), DateStr(1,2), DateStr(1,3));
            %             DecimalYear(dates) = DateVector(1,1)+DateVector(1,2)./12+DateVector(1,3)./365; %calculating decimal year
            clear acq_date DateStr
            disp('Decima Year Calculated');
            
            %calculating Surface Reflectance
            Sur_ref = (RMUL)*(single(A))+(RADD);
            
            mask_real_data = ones(size(A),'logical');
            mask_real_data(A==0)=0;  %masking fake data i.e, 0 values
            
            %read the file name for the Band Quality Accessment file (BQA)
            BQAFilename = dir(fullfile(filepath,date(dates).name,'L2C2','*QA_PIXEL.TIF'));
            if ~(exist(fullfile(BQAFilename.folder,BQAFilename.name)))
                continue
            end
            [BQAData]=  geotiffread(fullfile(BQAFilename.folder,BQAFilename.name));
            de_2_bi =  de2bi(BQAData,16);
            Binarymask = (de_2_bi(:,1)|... %fill values
                de_2_bi(:,2)|... %Dilated Cloud
                de_2_bi(:,4)|... %Cloud
                de_2_bi(:,5)|... %Cloud Shadow
                de_2_bi(:,10)|...%Cloud Confidence
                de_2_bi(:,12)|... %Cloud Shadow Confidence
                de_2_bi(:,16)); %Cirrus Condifdence
            
            Binarymask = reshape(Binarymask(:),height(BQAData),[]);
            CloudMask = ~Binarymask;
            % ROI with many points
            %             x1 = 709471.8311; y1 = 4275743.4229;
            %             x2 = 709734.3311; y2 = 4277355.9229;
            %             x3 = 710746.8311; y3 = 4278255.9229;
            %             x4 = 712059.3311; y4 = 4278180.9229;
            %             x5 = 710484.3384; y5 = 4284930.9229;
            %             x6 = 715359.3311; y6 = 4291455.9229;
            %             x7 = 721996.8384; y7 = 4293593.4229;
            %             x8 = 725559.3384; y8 = 4291155.9229;
            %             x9 = 735834.3384; y9 = 4292768.4229;
            %             x10 = 738721.8384; y10 = 4289918.4229;
            %             x11 = 738609.3384; y11 = 4286580.9229;
            %             x12 = 735384.3384; y12 = 4284593.4229;
            %             x13 = 733284.3384; y13 = 4285718.4229;
            %             x14 = 732271.8384; y14 = 4281030.9229;
            %             x15 = 722934.3384; y15 = 4271468.4229;
            %             x16 = 716259.3311; y16 = 4271093.4229;
            %             x17 = 709584.3311; y17 = 4274018.4229;
            %
            %             ROI_X = [x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17];
            %             ROI_Y = [y1,y2,y3,y4,y5,y6,y7,y8,y9,y10,y11,y12,y13,y14,y15,y16,y17];
            %
            %             [xIntrinsic,yIntrinsic] = worldToIntrinsic(R,ROI_X,ROI_Y); %converting mapping coordinate to pixel coordinate
            %             xIntrinsic = round(xIntrinsic);
            %             yIntrinsic = round(yIntrinsic);
            %             [img_row,img_col] = size(A);
            %             ROI_Mask = poly2mask(xIntrinsic, yIntrinsic, img_row, img_col);%converting ROI polygon to region mask
            %              clear x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x13 x14 x15 x16 x17 xIntrinsic img_row
            %              clear y1 y2 y3 y4 y5 y6 y7 y8 y9 y10 y11 y12 y13 y14 y15 y16 y17 yIntrinsic img_col
            %
            %             disp('ROI Created');
            
            % Rectangular ROI
            Upper_Left_Latitude = 716528.4448; Upper_Left_Longitude = 4286370.9375;
            Upper_Right_Latitude =  723424.5483; Upper_Right_Longitude = 4286370.9375;
            Lower_Right_Latitude = 723424.5483; Lower_Right_Longitude = 4279483.4033;
            Lower_Left_Latitude = 716528.4448; Lower_Left_Longitude = 4279483.4033;
            
            
            ROI_X = [Upper_Left_Latitude, Upper_Right_Latitude, Lower_Right_Latitude, Lower_Left_Latitude, Upper_Left_Latitude];
            ROI_Y = [Upper_Left_Longitude, Upper_Right_Longitude, Lower_Right_Longitude, Lower_Left_Longitude, Upper_Left_Longitude];
            
            [xIntrinsic,yIntrinsic] = worldToIntrinsic(R,ROI_X,ROI_Y); %converting mapping coordinate to pixel coordinate
            xIntrinsic = round(xIntrinsic);
            yIntrinsic = round(yIntrinsic);
            [img_row,img_col] = size(A);
            ROI_Mask = poly2mask(xIntrinsic, yIntrinsic, img_row, img_col);%converting ROI polygon to region mask
            clear Upper_Left_Lattitude Upper_Left_Longitude Upper_Right_Lattitude Upper_Right_Longitude Lower_Right_Lattitude Lower_Right_Longitude Lower_Left_Lattitude Lower_Left_Longitude
            clear ROI_X ROI_Y xIntrinsic yIntrinsic img_row img_col
            disp('ROI Created');
            %              Pixel =  TOA_REF.*ROI_Mask.* mask_real_data;
            %              L2Reflectance(bands).L2 = Pixel;
            
            %calculating Mean and Standard Deviation of TOA Reflectance
            Mean_SR(dates,bands) = mean(Sur_ref(CloudMask & mask_real_data & ROI_Mask));
            STD_SR(dates,bands) = std(Sur_ref(CloudMask & mask_real_data & ROI_Mask));
            CV(dates,bands) = (STD_TOA_REF(bands)/Mean_TOA_REF(bands))*100; %calculating coefficient of variation
            
            % Calculate NDVI (Normalized Difference Vegetation Index)
            if bands == 4 % Band 4 is Red
                Red = Sur_ref .* mask_real_data .* ROI_Mask;
            elseif bands == 5 % Band 5 is Near-Infrared
                NIR = Sur_ref .* mask_real_data .* ROI_Mask;
            end
            
            % Save the NDVI for each date
            if exist('Red', 'var') && exist('NIR', 'var')
                NDVI(dates) = (NIR - Red) ./ (NIR + Red);
                clear Red NIR;
            end
            
            % Rest of your code ...
        end
        
        % Calculate Burn Severity Index (BSI)
        if exist('Mean_SR', 'var') && exist('NDVI', 'var')
            % Choose an appropriate NDVI threshold based on your data
            NDVI_threshold = 0.2;
            
            % Calculate BSI using NDVI and mean surface reflectance
            BSI(dates) = (Mean_SR(dates, 5) - Mean_SR(dates, 4)) ./ (Mean_SR(dates, 5) + Mean_SR(dates, 4));
            
            % Classify burn severity based on NDVI and BSI thresholds
            if NDVI(dates) <= NDVI_threshold
                BurnSeverity(dates) = "Unburned";
            elseif NDVI(dates) > NDVI_threshold && BSI(dates) < 0.1
                BurnSeverity(dates) = "Low Severity";
            else
                BurnSeverity(dates) = "High Severity";
            end
            
            clear NDVI BSI;
            
        end
    end
    save('P43R33_CaldorFire2.mat','Mean_SR','STD_SR','DecimalYear','DayofYear', '-v7.3');
    disp('Done one date');
end


