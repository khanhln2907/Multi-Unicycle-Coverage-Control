classdef Class_Logger < handle
    %CLASS_LOGGER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        nAgent
        maxCnt 
        curCnt
        PoseVM 
        ControlOutput 
        CVT
        V_BLF 
        V_BLF_Den 
    end
    
    methods
        function obj = Class_Logger(amountAgent, maxIter)
            obj.nAgent = amountAgent;
            obj.maxCnt = maxIter;
            obj.curCnt = 0;
            obj.PoseVM = zeros(amountAgent, 2, maxIter);
            obj.ControlOutput = zeros(amountAgent, maxIter);
            obj.CVT = zeros(amountAgent, 2, maxIter);
            obj.V_BLF = zeros(amountAgent, maxIter);
            obj.V_BLF_Den = zeros(amountAgent, maxIter);
        end
        
        function updateBot(obj, curBot, newPoseVM, newWk, newCVT)
            if(obj.curCnt <= obj.maxCnt)
                obj.PoseVM(curBot, :,obj.curCnt)           = newPoseVM(:,:);
                obj.ControlOutput(curBot, obj.curCnt)    = newWk(:);
                obj.CVT(curBot,:, obj.curCnt)              = newCVT(:,:);
            else 
                disp('Max CNT already, logging stopped!');
            end
        end
        
        function updateBLF(obj, newV, newVden)
            obj.curCnt = obj.curCnt + 1;
            if(obj.curCnt <= obj.maxCnt)
                obj.V_BLF(:, obj.curCnt)            = newV(:);
                obj.V_BLF_Den(:, obj.curCnt)        = newVden(:);
            else 
                disp('Max CNT already, logging stopped!');
            end
        end
    end
end

