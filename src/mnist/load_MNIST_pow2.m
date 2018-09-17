function x_out = load_MNIST_pow2(filename, dim)
% LOAD_MNIST_PADDED  Loads MNIST where spatial dimensions are k=2^m

k = nextpow2(dim);
dim = 2^k;
fprintf('[%s] Resizing MNIST to %d x %d\n', mfilename, dim, dim);


x_raw = loadMNISTImages(filename);
n = size(x_raw,2);

x_raw = reshape(x_raw, 28, 28, n); % expand to a tensor

start_time = tic;
x_out = zeros(dim, dim, n);

for ii = 1:n
    x_out(:,:,ii) = imresize(x_raw(:,:,ii), [dim, dim], 'bilinear');
end

fprintf('[%s] Took %0.2f sec to load & resize MNIST\n', mfilename, toc(start_time));
