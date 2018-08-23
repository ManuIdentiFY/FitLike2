classdef ColeColeLong < DispersionModel
    % Cole-Cole background model - long version
    % Papers:
    % 1. Field-Cycling relaxometry of protein solutions and tissue: implications for MRI
    % 2. Magnetic Cross-Relaxation among Protons in Protein Solutions
    % 3. Protein Rotational Relaxation as Studied by Solvent lH and 2H Magnetic Relaxation
    % 4. Relaxometry of tissue
    %
    % Vasileios Zampetoulas, University of Aberdeen, 2016
    % Adapted by LB, 23/08/18
                 
    properties
        modelName = 'Cole-Cole, long';        
        modelEquation = ['y0 + A*(1 + (f/fcc)^(b/2)*cosd(45*b)) / '...
        '( 1 + 2*(f/fcc)^(b/2)*cosd(45*b)+(f/fcc).^b)'];    
        variableName = {'f'};     
        parameterName = {'y0', 'A',  'fcc',   'b'};    
        minValue =      [-10,    0,    1e2,   0];         
        maxValue =      [10,    110,   1e8,      5];         
        startPoint =    [0.4,   30,   1e5,     0.7];       
        isFixed = [0 0 0 0];
    end
end