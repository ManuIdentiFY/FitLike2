classdef ColeColeShort < DispersionModel
    % Cole-Cole background model - simplest version
    % Papers:
    % 1. Field-Cycling relaxometry of protein solutions and tissue: implications for MRI
    % 2. Magnetic Cross-Relaxation among Protons in Protein Solutions
    % 3. Protein Rotational Relaxation as Studied by Solvent lH and 2H Magnetic Relaxation
    % 4. Relaxometry of tissue
    %
    % Vasileios Zampetoulas, University of Aberdeen, 2016
    % Adapted by LB, 23/08/18
               
    properties

        modelName = 'Cole-Cole, short';        
        modelEquation = 'y0 + A/(1+(f/fcc)^2)';    
        variableName = {'f'};     
        parameterName = {'y0', 'A',  'fcc'};    
        minValue =      [-10,   0,    1e2];         
        maxValue =      [20,  20,    20e6];         
        startPoint =    [9,    4,    1e6];       
        isFixed = [0 0 0];
    end
end