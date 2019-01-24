classdef QPKimmichWinter < DispersionModel
    % Model for 14N quadrupolar peaks in biological tissues.
    %
    % Original paper: 
    % F. Winter., R. Kimmich
    % Spin lattice relaxation of dipole nuclei (I = 1/2) coupled to quadrupole nuclei (S = 1)
    % Mol. Phys. 45, 33-49
    %
    % A = 1/3* C^2 / hb^2 * 2/(sigma * pi)          Amplitude of the peaks
    % C = mu0/(4*pi) * gammaH*gammaN*hb^2/rHN^3     
    % w0 = K/hbar                                   Centre frequency of the peaks
    % K = e0^2*q*Q/4
    %
    % gammaH gammaN: gyromagnetic ratios
    % rHN: distance between nuclei
    % mu0: magnetic permeability
    % hb: reduced Plank constant
    % thetS: polar angle between rHN and the z-axis of the
    % principal axes system of the field gradient tensor
    % e0: elementary charge
    % q: electric field gradient along the z-axis of the PAS
    % Q: quadrupolar moment
    % eta: asymetry parameter, (qx-qy)/qz
    %
    % Note: Low-field condition satisfied for 14N
    % (B0<e0^2*q*Q/(4*hb*gammaN)
    % Vasileios Zampetoulas, 2016
    % Modified by Lionel Broche for compatibility, 23/08/18
    
    properties
        modelName     = 'Quadrupolar peaks, Kimmich-Winter model';
        modelEquation = ['A * (sigma/2)^2/((f0*(1+eta/3)-f)^2+(sigma/2)^2) + '...
                         'A * (sigma/2)^2/((f0*(1-eta/3)-f)^2+(sigma/2)^2) + '...
                         'A * (4/3-sin(thetaS)^2)/((2/3+sin(thetaS)^2)/2) * (sigma/2)^2/((f0*2*eta/3-f)^2  +(sigma/2)^2)'];
        variableName  = {'f'};
        parameterName = {'A',  'sigma', 'f0',  'eta', 'thetaS'};
        minValue      = [0,    0.2e6,   2.3e6,  0,     -pi];    
        maxValue      = [Inf,  2e6,     2.6e6,  0.6,    pi];    
        startPoint    = [0.5,  0.35e6,  2.5e6,  0.4,   -pi/4]; 
        isFixed       = [  0     0       0       0        0];
        visualisationFunction@cell = {};
    end
    
    methods
         function this = QPKimmichWinter
             % call superclass constructor
             this = this@DispersionModel;
         end
    end
end