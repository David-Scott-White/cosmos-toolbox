function fastregdemo
% the demo of fastreg function. 
si=imread('lena.png');

dx0 = 10.123;            %the displacement in X
dy0 = -0.789;           %the displacement in Y

ci=immove(si,dx0,dy0); %moving image SI to CI by dx and dy

[dx dy]=fastreg(si,ci); % the calculated the displacement in X and Y by function fastreg

fprintf('The calculated displacements are %6.3f and %6.3f pixels,\n and the error are %6.3f and %6.3f pixel.\n',dx,dy,dx+dx0,dy+dy0);


function g=immove(I,dx,dy)
% image move function 
[m n]=size(I);
T = [1 0 0; 0 1 0;  dy dx 1];
tform = maketform('affine',T);
g = imtransform(I,tform,'bicubic', 'XData',[1 n], 'YData',[1 m],'FillValue',0);