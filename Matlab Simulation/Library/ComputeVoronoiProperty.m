%% This function returns ...
%
function [outList, adjacentList] = ComputeVoronoiProperty(pointCoord, CVTCoord, verList, verPtr)
    n = numel(verPtr);
    
    info = SimpleValue.empty(n,0);
    
    
    outList = zeros(n, n, 5); % Checkflag - dCix/dzjx - dCix/dzjy - dCiy/dzjx - dCiy/dzjy 
    [adjacentList] = computeAdjacentList(CVTCoord, verList, verPtr);
%     if(1)
%         global cellColors;
%         cellColors = summer(n);
%         [ax] = Plot_Cell(trueCoord, CVTCoord, verList, verPtr);
%     end
    % CVTCoord      : CVT information of each agent
    % adjacentList  : 
    for thisCell = 1:n
        thisCoord = pointCoord(thisCell, :);
        thisCVTCoord = CVTCoord(thisCell, :);
        verThisCell = verPtr{thisCell}(1:end-1);
        coordVertexX = verList(verThisCell,1);
        coordVertexY = verList(verThisCell,2);
        [mOmegai, denseXi, denseYi] = computePartitionMass(coordVertexX, coordVertexY);
        
        % Take the information of this cell's adjacent to compute the
        % derivative
        flagAdj =  adjacentList(thisCell,:,1);
        thisAdjList = find(flagAdj);
        ownParitialDerivative = zeros(2,2);
        for i = 1: numel(thisAdjList)
            adjIndex = thisAdjList(i);
            curAdjCoord = pointCoord(adjIndex, :);
            curAdjCVTCoord = CVTCoord(adjIndex, :);
            commonVertex1 = [adjacentList(thisCell, adjIndex, 6), adjacentList(thisCell, adjIndex, 7)];
            commonVertex2 = [adjacentList(thisCell, adjIndex, 8), adjacentList(thisCell, adjIndex, 9)];
            % Debugging
            %if(1)
            %    plot([commonVertex1(1) commonVertex2(1)] , [commonVertex1(2) commonVertex2(2)], 'Color', cellColors(thisCell,:));
            %end
            %[tmpdCidZi1, adjacentPartialDerivative1] = computePartialDerivativeCVT(thisCoord, curAdjCoord, commonVertex1, commonVertex2, mOmegai, denseXi, denseYi);
            [tmpdCidZi, adjacentPartialDerivative] = computePartialDerivativeCVTs(thisCoord, thisCVTCoord, curAdjCoord, curAdjCVTCoord, commonVertex1, commonVertex2, mOmegai);
            
            ownParitialDerivative = ownParitialDerivative + tmpdCidZi;
            % Update the desired information
            outList(thisCell, adjIndex, 1) = true; % Is neighbor ?
            outList(thisCell, adjIndex, 2) = adjacentPartialDerivative(1, 1);    % adjacentPartialDerivative dCix_dzjx
            outList(thisCell, adjIndex, 3) = adjacentPartialDerivative(1, 2);    % adjacentPartialDerivative dCix_dzjy
            outList(thisCell, adjIndex, 4) = adjacentPartialDerivative(2, 1);    % adjacentPartialDerivative dCiy_dzjx
            outList(thisCell, adjIndex, 5) = adjacentPartialDerivative(2, 2);    % adjacentPartialDerivative dCiy_dzjy
        end
        % Assign own partial deriveativ 
        outList(thisCell, thisCell, 2) = ownParitialDerivative(1, 1);    % adjacentPartialDerivative dCix_dzix
        outList(thisCell, thisCell, 3) = ownParitialDerivative(1, 2);    % adjacentPartialDerivative dCix_dziy
        outList(thisCell, thisCell, 4) = ownParitialDerivative(2, 1);    % adjacentPartialDerivative dCiy_dzix
        outList(thisCell, thisCell, 5) = ownParitialDerivative(2, 2);    % adjacentPartialDerivative dCiy_dziy
    end    
end

%% Compute the mass of Voronoi partition
function [mOmega, denseX, denseY] = computePartitionMass(coordVertexX, coordVertexY)
        IntDomain = struct('type','polygon','x',coordVertexX(:)','y',coordVertexY(:)');
        param = struct('method','gauss','points',6); 
        %param = struct('method','dblquad','tol',1e-6);
        %% The total mass of the region
        func = @(x,y) 1;
        mOmega = doubleintegral(func, IntDomain, param);
        
        %% The density over X axis
        denseFuncX = @(x,y) x;
        denseX = doubleintegral(denseFuncX, IntDomain, param);
        
        %% The density over Y axis
        denseFuncY = @(x,y) y;
        denseY = doubleintegral(denseFuncY, IntDomain, param);
end

function [dCi_dzi_AdjacentJ, dCi_dzj] = computePartialDerivativeCVTs(thisCoord, thisCVT, adjCoord, adjCVT, vertex1, vertex2, mVi)
    v1x = vertex1(1);
    v1y = vertex1(2); 
    v2x = vertex2(1);
    v2y = vertex2(2);
    % Own info
    zix = thisCoord(1);
    ziy = thisCoord(2);
    cix = thisCVT(1);
    ciy = thisCVT(2);
    % Adj Info
    zjx = adjCoord(1);
    zjy = adjCoord(2);
    %cjx = adjCVT(1);
    %cjy = adjCVT(2);
    
    mViSquared = mVi^2;    
    
    %% Function definition for partial derivative
    % rho = @(x,y) 1;
    distanceZiZj = sqrt((zix - zjx)^2 + (ziy - zjy)^2);
    dq__dZix_n = @(qX, ziX) (qX - ziX) / distanceZiZj; %        ((zjX - ziX)/2 + (qX - (qXY + zjX)/2)) / distanceZiZj; 
    dq__dZiy_n = @(qY, ziY) (qY - ziY) / distanceZiZj; %        ((zjY - ziY)/2 + (qY - (ziY + zjY)/2)) /distanceZiZj; 
    dq__dZjx_n = @(qX, zjX) (zjX - qX) / distanceZiZj; %        ((zjX - ziX)/2 - (qX - (ziX + zjX)/2)) /distanceZiZj; 
    dq__dZjy_n = @(qY, zjY) (zjY - qY) / distanceZiZj; %        ((zjY - ziY)/2 - (qY - (ziY + zjY)/2))/distanceZiZj; 
    
    
    
    %% Integration parameter: t: 0 -> 1
    XtoT = @(t) v1x + (v2x - v1x)* t;
    YtoT = @(t) v1y + (v2y - v1y)* t;
    dqTodtParam = sqrt((v2x - v1x)^2 + (v2y - v1y)^2);  % Factorization of dq = param * dt for line integration
    
    %% dCi_dzix
    dCi_dzix_secondTermInt = integral(@(t) dq__dZix_n(XtoT(t), zix) * dqTodtParam , 0, 1);
    dCix_dzix = (integral(@(t) XtoT(t) .* dq__dZix_n(XtoT(t), zix) .* dqTodtParam, 0, 1) + dCi_dzix_secondTermInt * cix) / mVi;
    dCiy_dzix = (integral(@(t) YtoT(t) .* dq__dZix_n(XtoT(t), zix) .* dqTodtParam, 0, 1) + dCi_dzix_secondTermInt * ciy) / mVi;
    
    %% dCi_dziy
    dCi_dziy_secondTermInt = integral(@(t) dq__dZiy_n(YtoT(t), ziy) * dqTodtParam , 0, 1);
    dCix_dziy = (integral(@(t) XtoT(t) .* dq__dZiy_n(YtoT(t), ziy) .* dqTodtParam, 0, 1) + dCi_dziy_secondTermInt * cix) / mVi;
    dCiy_dziy = (integral(@(t) YtoT(t) .* dq__dZiy_n(YtoT(t), ziy) .* dqTodtParam, 0, 1) + dCi_dziy_secondTermInt * ciy) / mVi;
    
    %% dCi_dzjx
    dCi_dzjx_secondTermInt = integral(@(t) dq__dZjx_n(XtoT(t), zjx) * dqTodtParam , 0, 1 ) / mViSquared;
    dCix_dzjx = (integral(@(t) XtoT(t) .* dq__dZjx_n(XtoT(t), zjx) .* dqTodtParam, 0, 1) + dCi_dzjx_secondTermInt * cix) / mVi;
    dCiy_dzjx = (integral(@(t) YtoT(t) .* dq__dZjx_n(XtoT(t), zjx) .* dqTodtParam, 0, 1) + dCi_dzjx_secondTermInt * ciy) / mVi;
    
    %% dCi_dzjy
    dCi_dzjy_secondTermInt = integral(@(t) dq__dZjy_n(YtoT(t), zjy) * dqTodtParam , 0, 1 ) / mViSquared;
    dCix_dzjy =  (integral(@(t) XtoT(t) .* dq__dZjy_n(YtoT(t), zjy) .* dqTodtParam, 0, 1) + dCi_dzjy_secondTermInt * cix) / mVi;
    dCiy_dzjy =  (integral(@(t) YtoT(t) .* dq__dZjy_n(YtoT(t), zjy) .* dqTodtParam, 0, 1) + dCi_dzjy_secondTermInt * ciy) / mVi;
    
    %% Return
    dCi_dzi_AdjacentJ   = [ dCix_dzix, dCix_dziy; 
                            dCiy_dzix, dCiy_dziy];
    dCi_dzj             = [ dCix_dzjx, dCix_dzjy ;
                            dCiy_dzjx, dCiy_dzjy];   
end

%% Determine which CVTs are adjacent CVTs
function [adjacentList] = computeAdjacentList(centroidPos, vertexes, vertexHandler)
    % Check for all agent
    nAgent = numel(vertexHandler);
    % Return the result [adjacentList] with the following information - 9 columns 
    % CheckNeighborflag - [thisCVT: x y] - [neighborCVT: x y] - [vertex1: x y] - [vertex2: x y]
    
    AgentReport(nAgent) = struct();
    % Tmp Variable to scan the collaborative agent
    FriendAgentInfo(nAgent) = struct();
    for k = 1:nAgent
        % Instatinate struct data to carry all information of another agent
        AgentReport(k).ID = k;
        AgentReport(k).CVT.x = 0;
        AgentReport(k).CVT.y = 0;
        % Define how the info structure of friend agents looks like
        for friendID = 1:nAgent
            FriendAgentInfo(friendID).ID = friendID;
            FriendAgentInfo(friendID).isVoronoiNeighbor = false;
            FriendAgentInfo(friendID).CVT.x = 0;
            FriendAgentInfo(friendID).CVT.y = 0;
            FriendAgentInfo(friendID).CommonVertex.Vertex1.x = 0;
            FriendAgentInfo(friendID).CommonVertex.Vertex1.y = 0;
            FriendAgentInfo(friendID).CommonVertex.Vertex2.x = 0;
            FriendAgentInfo(friendID).CommonVertex.Vertex2.y = 0;
        end
        AgentReport(k).FriendInfo = FriendAgentInfo;
    end
    
    adjacentList = zeros(nAgent,nAgent, 9);
    
    %% Start searching for common vertexes to determine neighbor agents
    for thisID = 1 : nAgent
        thisVertexList = vertexHandler{thisID}(1:end - 1);
        % Checking all another CVTs
        for friendID = 1: nAgent
              if(friendID ~= thisID)
                    nextVertexList = vertexHandler{friendID}(1:end-1); 
                       % Comparing these 2 arrays to find out whether it is the
                       % adjacent CVT or not  -> currentVertexes vs vertexBeingChecked
                       commonVertex = intersect(thisVertexList, nextVertexList);        % There are some bugs here. Same vertex coord but different index list. Most happens when the vexter lies on the boundary lines
                       nComVer = numel(commonVertex);
                       if(nComVer == 0)
                            % not adjacent
                            adjacentList(thisID, friendID, 1) = false;
                            AgentReport(thisID).FriendAgentInfo(friendID).isVoronoiNeighbor = false;
                       elseif(nComVer == 1)
                           disp("Warning: only 1 common vertex found");
                       elseif(nComVer == 2)
                           % Adjacent flag
                           adjacentList(thisID, friendID, 1) = true;
                           % Assign CVT coords
                           adjacentList(thisID, friendID,2) = centroidPos(thisID,1); % this Cx
                           adjacentList(thisID, friendID,3) = centroidPos(thisID,2); % this Cy
                           adjacentList(thisID, friendID,4) = centroidPos(friendID,1); % adj Cx
                           adjacentList(thisID, friendID,5) = centroidPos(friendID,2); % adj Cy
                           % Assign first common vertex
                           adjacentList(thisID, friendID,6) = vertexes(commonVertex(1),1); % v1x
                           adjacentList(thisID, friendID,7) = vertexes(commonVertex(1),2); % v1y
                           adjacentList(thisID, friendID,8) = vertexes(commonVertex(2),1); % v2x
                           adjacentList(thisID, friendID,9) = vertexes(commonVertex(2),2); % v2y 
                           
                           % Adjacent flag
                           AgentReport(thisID).CVT.x = centroidPos(thisID,1);
                           AgentReport(thisID).CVT.y = centroidPos(thisID,2);
                           AgentReport(thisID).FriendAgentInfo(friendID).isVoronoiNeighbor = true;
                           AgentReport(thisID).FriendAgentInfo(friendID).CVT.x = centroidPos(friendID,1);
                           AgentReport(thisID).FriendAgentInfo(friendID).CVT.x = centroidPos(friendID,2);
                           AgentReport(thisID).FriendAgentInfo(friendID).CommonVertex.Vertex1.x = vertexes(commonVertex(1),1);
                           AgentReport(thisID).FriendAgentInfo(friendID).CommonVertex.Vertex1.y = vertexes(commonVertex(1),2);
                           AgentReport(thisID).FriendAgentInfo(friendID).CommonVertex.Vertex2.x = vertexes(commonVertex(2),1);
                           AgentReport(thisID).FriendAgentInfo(friendID).CommonVertex.Vertex2.y = vertexes(commonVertex(2),2);
                       else
                           error("More than 3 vertexes for 1 common line detected");
                        end
              end
         end
    end
end
