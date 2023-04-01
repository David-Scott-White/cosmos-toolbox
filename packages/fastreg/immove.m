function g=immove(I,dx,dy)
% image move function
[m, n]=size(I);
T = [1 0 0; 0 1 0;  dy dx 1];
tform = maketform('affine',T);
g = imtransform(I,tform,'bilinear', 'XData',[1 n], 'YData',[1 m],'FillValue',0);
end