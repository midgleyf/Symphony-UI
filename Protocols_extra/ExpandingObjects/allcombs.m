%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function A = allcombs(varargin)

% simplified version of Jos van der Geest's allcomb.m function from the matlab file exchange
% modified so it can take a scalar (or vector) as the first input

% modified part1
if numel(varargin{1})==1
    varargin{1} = [varargin{1} NaN];
end
    
% simplified version of allcomb function
q = ~cellfun('isempty',varargin);
ni = sum(q) ;
ii = ni:-1:1 ;
if ni==0,
    A = [] ;
else
    args = varargin(q) ;

    if ni==1,
        A = args{1}(:) ;
    else
        % flip using ii if last column is changing fastest
        [A{ii}] = ndgrid(args{ii}) ;
        % concatenate
        A = reshape(cat(ni+1,A{:}),[],ni) ;
    end
end
% end of allcomb function

% modified part2
A(isnan(A(:,1)),:) = [];
