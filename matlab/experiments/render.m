clear all
close all

writerObj = VideoWriter('toys.avi') ;
open(writerObj);

for i=0:100
   
    str =sprintf('%04d',i);
    file = ['../toyrender/'  str '.jpg'];
    im = imread(file);
    writeVideo(writerObj,im);
    
end

close(writerObj);

