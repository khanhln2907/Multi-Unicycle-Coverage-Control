classdef (Abstract) Report_Base < handle
    properties (Access  = private)
        ID
    end
    
    methods
        function obj = Report_Base(initID)
            obj.ID = initID;
        end
        
        function printValue(obj)
            fprintf("Agent: %d\n", obj.ID);
            % Call the printing information of the child class
            obj.printInfo()
        end
        
        function out = getID(obj)
           out = obj.ID; 
        end
    end
    
    % Child class must declare these abstract methods 
    methods (Access = protected, Abstract)
        printInfo(obj)
    end    
end
