a=VideoReader('rubesh.mp4');
 for img = 1:a.NumFrames
 filename=strcat('frame',num2str(img),'.jpg');
 b = read(a, img);
 imwrite(b,filename); 
end
