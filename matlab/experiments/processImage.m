
d = dir('*.JPG');

for i=1:length(d)
    
    I = imread(d(i).name);
    
    I = imresize(I,0.25);
    I = imrotate(I,-90);
    bw = rgb2gray(I);
    r = I(:,:,1);
    g = I(:,:,2);
    b = I(:,:,3);
    hsv = rgb2hsv(I);
    
    if 0
        e = edge(bw);imagesc(e); title('bw'); axis equal; pause
        e = edge(r);imagesc(e); title('r'); axis equal; pause
        e = edge(g);imagesc(e); title('g'); axis equal; pause
        e = edge(b);imagesc(e); title('b'); axis equal; pause
    end
    
    th = r>g/0.9 & r>b/0.9 & r>220;
    
    figure(1);
    subplot(121);
    imagesc(th); axis equal; axis off;
    subplot(122);
    imagesc(edge(hsv(:,:,3))); axis equal; axis off;
    figure(2)
    imagesc(edge(hsv(:,:,3)) & th);
    colormap gray; 
    axis equal; axis off;
    pause
end