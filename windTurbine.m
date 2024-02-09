classdef windTurbine
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        startingWindVelocity
        nominalWindVelocity
        maximumWindVelocity
        maximumPower
        coefficent1
        coefficent2
    end
    
    methods
        function obj = windTurbine(startingWindVelocity, nominalWindVelocity, ...
                maximumWindVelocity, maximumPower)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.startingWindVelocity = startingWindVelocity;
            obj.nominalWindVelocity = nominalWindVelocity;
            obj.maximumWindVelocity = maximumWindVelocity;
            obj.maximumPower = maximumPower;
            
            obj.coefficent1 = obj.maximumPower/(obj.nominalWindVelocity^3 ...
                -obj.startingWindVelocity^3);
            obj.coefficent2 = -obj.coefficent1*obj.startingWindVelocity^3;
        end
        
        function power = calculatePower(obj,windVelocity)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            power = zeros(length(windVelocity),1);
            
            power(windVelocity > obj.startingWindVelocity & ...
                windVelocity < obj.nominalWindVelocity) = obj.coefficent1*...
                windVelocity(windVelocity > obj.startingWindVelocity & ...
                windVelocity < obj.nominalWindVelocity).^3+obj.coefficent2;
            
            power(windVelocity >= obj.nominalWindVelocity & ...
                windVelocity < obj.maximumWindVelocity) = obj.maximumPower;
            
        end
    end
end

