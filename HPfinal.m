classdef HPfinal
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        aCOP
        aPower
    end

    methods
        function obj = HPfinal(COP, Power, T)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            fun = @(a,T)a(1)+a(2)*T(:,1)+a(3)*T(:,2)+a(4)*T(:,1).*T(:,2)...
                +a(5)*T(:,1).*T(:,1)+a(6)*T(:,2).*T(:,2);
            a0 = [1 1 1 1 1 1];
            obj.aCOP = lsqcurvefit(fun, a0, T, COP);
            obj.aPower = lsqcurvefit(fun, a0, T, Power);
        end

        function [Heat, Power, COP] = calculateHeat(obj, Th, Tc)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            COP = obj.aCOP(1)+obj.aCOP(2)*Th+obj.aCOP(3)*Tc ...
                +obj.aCOP(4)*Th.*Tc+obj.aCOP(5)*Th.*Th ...
                +obj.aCOP(6)*Tc.*Tc;
            Power = obj.aPower(1)+obj.aPower(2)*Th+obj.aPower(3)*Tc ...
                +obj.aPower(4)*Th.*Tc+obj.aPower(5)*Th.*Th ...
                +obj.aPower(6)*Tc.*Tc;
            Heat = Power.*COP;
        end
        
    end
end