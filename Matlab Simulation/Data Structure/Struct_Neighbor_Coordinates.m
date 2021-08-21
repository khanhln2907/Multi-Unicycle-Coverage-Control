classdef Struct_Neighbor_Coordinates < Struct_Neighbor_Info_Base
    properties
        NAME = "Struct_Neighbor_Coordinates"
        Neighbor_Coord_2d
        CommonVertex_2d_1
        CommonVertex_2d_2
    end
    
    methods
        function obj = Struct_Neighbor_Coordinates(myID, neighborID)
            obj@Struct_Neighbor_Info_Base(myID, neighborID);
            obj.Neighbor_Coord_2d = zeros(2,1);
            obj.CommonVertex_2d_1 = zeros(2,1);
            obj.CommonVertex_2d_2 = zeros(2,1);
        end
        
        
    end
    
    methods (Access = protected)
        function printInfo(obj)

        end
    end
end
