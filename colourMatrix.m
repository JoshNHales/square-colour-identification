function result = colourMatrix(filename)

%Set values for colours based on Lab colour space

white = [128,128]; 
blue = [145,85]; 
yellow = [116,190];
green = [65,185]; 
red = [170,150];
colours = [white; blue; yellow; green; red];
   
                              %Transformation

Reference=imread('SimulatedImages\org_1.png'); %Read image to be reference for transformation.
Refbw=~im2bw(Reference,0.5); % Convert reference image to binary with threshold 0.5
medfilt=medfilt2(Refbw);  %Filter applied 

%Find circle regions

CC=bwconncomp(medfilt);
z=regionprops(medfilt,'Eccentricity','Centroid','Area');
Areas=[z.Area];


%Maximum area removed to isolate circles

for i = 1:CC.NumObjects
    if z(i).Area == max(Areas)
        z(i)=[];
        break
    end
end

Centroid=[z.Centroid]; %Take centroids of circles
FixedPoints = vec2mat(Centroid,2); %Set centroids as fixed points


% Load in image to be transformed

targImg=imread(filename) ; %load image for analysis

BW=~im2bw(targImg,0.5); % Convert target image to binary with threshold 0.5
BWfill=imfill(BW,'holes'); %Fill noise holes
medfilt=medfilt2(BWfill); %Filter applied 


%Find circle regions

CC=bwconncomp(medfilt);
Z=regionprops(medfilt,'Eccentricity','Centroid','Area');
Areas=[Z.Area];


%Maximum area removed to isolate circle

for i = 1:CC.NumObjects
    if Z(i).Area == max(Areas)  
       Z(i)=[];  
       break
    end
end



Centroid2=[Z.Centroid]; %Take centroids of circles
MovingPoints=vec2mat(Centroid2,2); %Set centroids as moving points


%Applying the transformation

tform=fitgeotrans(MovingPoints,FixedPoints, 'Projective');
trans=imwarp(targImg,tform);



R=imref2d(size(Reference)) %Resize transformed target image to same size as reference image
corrected2 = imwarp(targImg,tform,'OutputView',R);
figure(3)
imshow(corrected2); %Display the resized target image, post transformation.
title('Corrected image')


                      

                                    % Colour recognition
% Identify squares as objects

C = makecform('srgb2lab');
RefLab = applycform(Reference, C); %Convert image to lab colour space
v=fspecial('log',[3 3],0.5); % log filter used to detect edges  
BW=im2bw(Reference,0.1); BWref=im2bw(Reference,0.1);
Imgfilt=imfilter(BW,v,'replicate');Imgfiltref=imfilter(BWref,v,'replicate');
Imgfiltdil = imcomplement(imdilate(Imgfilt,ones(7))); %Dilate to fill holes and sharpen outlines
Imgfiltrefdil = imcomplement(imdilate(Imgfiltref,ones(7))); %Dilate to fill holes and sharpen outlines
h = fspecial('average',3);

% Locate centroids of squares

Z=regionprops(Imgfiltdil, 'Centroid', 'Extent','Area');
CC = bwconncomp(Imgfiltdil);
Centroids = [];
BW2=zeros(CC.ImageSize);
for p=1:CC.NumObjects  %Loop through each object
if Z(p).Extent < 0.9 || Z(p).Area < 10
continue;
else
Centroids = [Centroids; Z(p).Centroid];
end
end

%Add filter to colour channels to help with colour identification

medfiltImg = corrected2;
medfiltImg(:,:,1) = medfilt2(medfiltImg(:,:,1), [9 9]);
medfiltImg(:,:,2) = medfilt2(medfiltImg(:,:,2), [9 9]);
medfiltImg(:,:,3) = medfilt2(medfiltImg(:,:,3), [9 9]);
RefLab = applycform(medfiltImg, C); % Covert to lab colour space
Imgfiltrefdil = imdilate(im2bw(medfiltImg,0.5),ones(7)); %Dilate to fill holes and sharpen edges.

%Spliting the Image into seperate channels

L = RefLab(:,:,1);
a = RefLab(:,:,2);
b = RefLab(:,:,3);

  % Locating the squares, putting colour values into grids
  
Gcol = zeros(4,4);
  

for p=1:CC.NumObjects  %loop through each object
if Z(p).Extent < 0.9 || Z(p).Area < 10
continue;
else
match = abs(Z(p).Centroid -Centroids); % find matching squares between images
matchmin = min(match);
[~,index] = ismember(match,matchmin, 'rows');
index = find(index==1); % find index between reference square centroids

Aav = mean(a(ismember(labelmatrix(CC),p))); % Average a colour of square
Bav = mean(b(ismember(labelmatrix(CC),p))); % Average b colour of square
avAB = [Aav, Bav];
[mindist,colcode] = min(sqrt(sum((colours-avAB).^2,2))); % Difference between reference colour and square colour
x = ceil(index/4);
y = index -(x-1)*4; 
Gcol(y,x) = colcode;
end
  
end

% Return result

result = Gcol
end

       
  