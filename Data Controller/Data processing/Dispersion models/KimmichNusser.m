classdef KimmichNusser < DispersionModel
    % Kimmich-Nusser model
    % From:
    % Molecular Theory for Nuclear Magnetic Relaxation in Protein...
    % Solutions and Tissue: Surface Diffusion and Free-Volume Analogy
    %
    % Vasileios Zampetoulas, University of Aberdeen, 2016
    % Adapted by LB, 23/08/18
    
    properties
        modelName = 'KimmichNusser';        
        modelEquation = ['pp*Cp*(((2*b1*kp*gamma(slope)*((taut^(slope))/((1+((2*pi*f*taut)^2))^(slope/2)))*cosd(slope*atand(2*pi*f*taut)))'...
            '+(b2*((2*taut)/(1+((2*pi*f*taut)^2)))))'...
            '+(4*((2*b1*kp*gamma(slope)*((taut^(slope))/((1+((4*pi*f*taut)^2))^(slope/2)))*cosd(slope*atand(4*pi*f*taut)))'...
            '+(b2*((2*taut)/(1+((4*pi*f*taut)^2)))))))'...
            '+(Ch*ph*(((2*(1-a2)*taur)+kh*(((1/(sqrt(taum)))-(1/(sqrt(taup)))).*((2*taum)./(1+((2*pi*f*taum)^2)))'...
            '+(1./(sqrt(2*2*pi*f))).*(((1/2)*log((1+sqrt(2*2*pi*f*taum)+(2*pi*f*taum))./(1-sqrt(2*2*pi*f*taum)+(2*pi*f*taum))))'...
            '+pi-atand(sqrt(2./(2*pi*f*taum))-1)-atand(sqrt(2./(2*pi*f*taum))+1))))'...
            '+(4*((2*(1-a2)*taur)+kh*(((1/(sqrt(taum)))-(1/(sqrt(taup)))).*((2*taum)./(1+((2*2*pi*f*taum)^2)))'...
            '+(1./(sqrt(2*2*2*pi*f))).*(((1/2)*log((1+sqrt(2*2*2*pi*f*taum)+(2*2*pi*f*taum))./(1-sqrt(2*2*2*pi*f*taum)+(2*2*pi*f*taum))))'...
            '+pi-atand(sqrt(2./(2*2*pi*f*taum))-1)-atand(sqrt(2./(2*2*pi*f*taum))+1)))))))'...
            '+(pf*Cf*((2*tauf)+(4*(2*tauf))))'];
        variableName = {'f'};     
        parameterName = {'Cp',  'b1',   'kp',   'slope',   'taut',   'taum',   'ph', 'kh',  'taur',   'b2',  'pp',  'Ch',   'a2',  'taup',  'pf',  'Cf',  'tauf' };    
        minValue = [ 0,      0,      0,      0,       0,         0,      0,     0,      0,       0,      0,     0,      0,      0,     0,     0,     0];         
        maxValue = [Inf,   Inf,     Inf,    -5,       Inf,      Inf,     Inf,   Inf,    Inf,    Inf,    Inf,   Inf,    Inf,     Inf,   Inf,  Inf,   Inf];         
        startPoint = [1,      2,       3,     -0.75,     5,        6,      7,     8,      9,       10,     11,     12,     13,     14,    15,    16,    17];       
        isFixed = [ 0,      0,      0,      0,       0,         0,      0,     0,      0,       0,      0,     0,      0,      0,     0,     0,     0]; 
        visualisationFunction@cell = {};
    end
    
    methods
        function this = KimmichNusser
            % call superclass constructor
            this = this@DispersionModel;
        end
    end
         
end