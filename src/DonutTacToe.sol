// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

// @title: DonutTacToe
// @author: menuObj 
// @notice: Play tic tac toe against the contract on a donut (formally known as a torus), player 1 is O (user) and player 2 is X (contract)
contract DonutTacToe {
   /* the 72 rightmost bits represent the 36 pieces
      with each piece represented by 2 bits
      (00 = empty, 01 = user marker aka O, 10 = contract marker aka X) */
    uint256 torusState;
 
    // @notice Recursive function implementing minimax algorithm with alpha beta pruning with max depth 2
    // @param possibleTorus is the current state of the torus ("possible" because it contains hypothetical moves)
    // @param depth is how deep we currently are in the game tree
    // @param alpha and beta used for alpha beta pruning
    // @return at depth 0 returns the index of the cell to place marker at, at depth 1 returns the value of the best game possible, at depth 2 returns the value of the game     
    function searchForMove(uint256 possibleTorus, uint256 depth, int alpha, int beta) private pure returns (int) {  
        if(depth == 2) {    
            return evaluateTorus(possibleTorus);
        }
        if(depth == 1){   // user's turn
            int minPoints = type(int).max;
            for(uint256 posIndex; posIndex < 36; ++posIndex) {
                if( possibleTorus & (3 << posIndex*2) == 0 ){   // piece at index posIndex is empty
                    int points = searchForMove(possibleTorus | (1 << posIndex*2), depth + 1, alpha, beta);
                    if(points < minPoints){
                        minPoints = points;
                    } 
                    if(minPoints < beta){
                        beta = minPoints;
                    }
                    if(beta <= alpha){
                        break;
                    }
                }
            }
            return minPoints;
        }
        else {    //contract's turn
            uint256 emptyPosCount;
            uint256 emptyPosIndex;
            uint256 optimalMovePos;   // only used if depth is 0
            int maxPoints = type(int).min;
            for(uint256 posIndex; posIndex < 36; ++posIndex) {
                if( possibleTorus & (3 << posIndex*2) == 0 ){
                    emptyPosCount++;
                    emptyPosIndex = posIndex;
                    int points = searchForMove(possibleTorus | (1 << (posIndex*2+1)), depth + 1, alpha, beta);
                    if(points > maxPoints){
                        maxPoints = points;
					    /*if depth is 0 we don't want to return the max points attainable but
                          rather the position that gets us that max point: */
					    if(depth == 0){
				            optimalMovePos = posIndex;
					    }
                    }
                    if(maxPoints > alpha){
                        alpha = maxPoints;
                    }
                    if(beta <= alpha){
                        break;
                    }
                }
            }
            if(emptyPosCount == 1 && depth == 0 && evaluateTorus( possibleTorus | (1 << (emptyPosIndex*2+1)) ) != type(int).max ){   //donut is now full as contract has made the last available move, we return 40 or 41 as only 0~35 are returned for depth 0
            	return int(emptyPosIndex+72);    //game ends as tie
            }
            if(depth == 0){
                return int(optimalMovePos);
            }
            return maxPoints;
        }
    }
	
	
    // @notice Evaluates a given game state by scanning in groups of 6 (horizontal, vertical, both diagonals)
    // @dev the bitshifts are to check if there are 5, 4, or 3 markers in a line because if there are those should be considered first when evaluating
    // @param possibleTorus is the current state of the torus ("possible" because it contains hypothetical moves)
    // @return Returns the point value of the current donut
    function evaluateTorus(uint256 possibleTorus) private pure returns (int){
        uint256 torusData;     //contains data for horizontal, vertical, rd, ld from right to left and within each goes from 0th group to 5th group from right to left
        int totalPoints;
 
        unchecked{
            /* the ith cell is a part of the (i/6)th horizontal group, (i%6)th vertical group, ((i+(i/6)) % 6)th rd group, and ((i-(i/6)) % 6)th ld group */
            for(uint256 i; i < 36; ++i){
                if(possibleTorus & (3 << 2*i) == 0){        //no markers
                    continue;
                }
                else if( (possibleTorus >> 2*i) & 1 == 1){    //user marker
                    uint256 horizontalCount = (torusData >> (6 * (i/6))) & 7;
                    torusData = ( torusData & ( ( 7 << ( 6 * (i/6) ) )  ^ 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff ) ) + ( (horizontalCount + 1) << ( 6 * (i/6) ) );
                    uint256 verticalCount = (torusData >> (36 + 6 * (i % 6))) & 7;
                    torusData = ( torusData & ( ( 7 << ( 36 + 6 * (i % 6) ) )  ^ 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff ) ) + ( (verticalCount + 1) << ( 36 + 6 * (i % 6) ) );
                    uint256 rightDownCount = (torusData >> (72 + 6 * ((i + i/6) % 6))) & 7;
                    torusData = ( torusData & ( ( 7 << ( 72 + 6 * ((i + i/6) % 6) ) )  ^ 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff ) ) + ( (rightDownCount + 1) << ( 72 + 6 * ((i + i/6) % 6) ) );
                    uint256 leftDownCount = (torusData >> (108 + 6 * ((i - i/6) % 6))) & 7;
                    torusData = ( torusData & ( ( 7 << ( 108 + 6 * ((i - i/6) % 6) ) )  ^ 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff ) ) + ( (leftDownCount + 1) << ( 108 + 6 * ((i - i/6) % 6) ) );
                }
                else{    //contract marker
                    uint256 horizontalCount = (torusData >> (3 + 6 * (i/6))) & 7;
                    torusData = ( torusData & ( ( 7 << ( 3 + 6 * (i/6) ) )  ^ 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff ) ) + ( (horizontalCount + 1) << ( 3 + 6 * (i/6) ) );
                    uint256 verticalCount = (torusData >> (39 + 6 * (i % 6))) & 7;
                    torusData = ( torusData & ( ( 7 << ( 39 + 6 * (i % 6) ) )  ^ 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff ) ) + ( (verticalCount + 1) << ( 39 + 6 * (i % 6) ) );
                    uint256 rightDownCount = (torusData >> (75 + 6 * ((i + i/6) % 6))) & 7;
                    torusData = ( torusData & ( ( 7 << ( 75 + 6 * ((i + i/6) % 6) ) )  ^ 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff ) ) + ( (rightDownCount + 1) << ( 75 + 6 * ((i + i/6) % 6) ) );
                    uint256 leftDownCount = (torusData >> (111 + 6 * ((i - i/6) % 6))) & 7;
                    torusData = ( torusData & ( ( 7 << ( 111 + 6 * ((i - i/6) % 6) ) )  ^ 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff ) ) + ( (leftDownCount + 1) << ( 111 + 6 * ((i - i/6) % 6) ) );
                }
            }
            //need to loop through entire torus before returning anything UNLESS we have 5 X in a line (the order of precedence is XCount == 5 then OCount == 5 then XCount == 4 then OCount == 4 because evaluateTorus is only run at depth 2 which means user made the latest move
            bool fiveOCount = false;     
            bool fourXCount = false;
            bool fourOCount = false;
            for(uint256 i; i < 24; ++i){
                uint256 currGroup = (torusData >> (6 * i)) & 63;
                uint256 OCount = currGroup & 7;
                uint256 XCount = currGroup >> 3;
                if(OCount == 5){
                    fiveOCount = true;
                }
                if(XCount == 5){
                    return type(int).max;
                }
                if(OCount == 4 && XCount == 0){
                    fourOCount = true;
                }
                if(XCount == 4 && OCount == 0){
                    fourXCount = true;
                }
                totalPoints += int(XCount - OCount);
            }
            if(fiveOCount == true){
                return type(int).min;
            }
            if(fourXCount == true){
                return type(int).max;
            }
            if(fourOCount == true){
                return type(int).min;
            }
            return totalPoints;
        }
    }
    
	
    // @notice Checks if contract or user (depending on isContract) has won. Examines possibleTorus around the index of the most recent move because that is all that matters.
    // @dev This function enforces the logic of the torus board so we don't need a separate contract for the board logic (engine and board logic is combined).
    // @dev Onlychecking around the mostRecentMove significantly saves gas as we don't need to check the entire donut  
    // @dev Uses two structs Counts and Markers because local variables inside the function causes stack to run out of depth
    // @param mostRecentMove is the index of the new O (if isContract is false) or X (if isContract is true), only need to check if this new move causes a win
    // @param isContract simply indicates if we are checking a win for the user or the contract
    // @return Returns the point value of the current donut
    struct Counts {
        uint8 hCount;
        uint8 vCount;
        uint8 rdCount;
        uint8 ldCount;
    }
    struct Markers {
        uint256 hMarker;
        uint256 vMarker;
        uint256 rdMarker;
        uint256 ldMarker;
    }
    function checkWin(uint256 possibleTorus, uint256 mostRecentMove, bool isContract) private pure returns (bool) {
        //each cell in the list listed once in the 4 groups it belongs to
        uint256[6][6] memory horizontalGroups = [ [uint256(0x3), 0xC, 0x30, 0xC0, 0x300, 0xC00],
                                                  [uint256(0x3000), 0xC000, 0x30000, 0xC0000, 0x300000, 0xC00000],
                                                  [uint256(0x3000000), 0xC000000, 0x30000000, 0xC0000000, 0x300000000, 0xC00000000],
                                                  [uint256(0x3000000000), 0xC000000000, 0x30000000000, 0xC0000000000, 0x300000000000, 0xC00000000000],
                                                  [uint256(0x3000000000000), 0xC000000000000, 0x30000000000000, 0xC0000000000000, 0x300000000000000, 0xC00000000000000],
                                                  [uint256(0x3000000000000000), 0xC000000000000000, 0x30000000000000000, 0xC0000000000000000, 0x300000000000000000, 0xC00000000000000000] ];
     
        uint256[6][6] memory verticalGroups = [ [uint256(0x3), 0x3000, 0x3000000, 0x3000000000, 0x3000000000000, 0x3000000000000000],
                                                [uint256(0xC), 0xC000, 0xC000000, 0xC000000000, 0xC000000000000, 0xC000000000000000],
                                                [uint256(0x30), 0x30000, 0x30000000, 0x30000000000, 0x30000000000000, 0x30000000000000000],
                                                [uint256(0xC0), 0xC0000, 0xC0000000, 0xC0000000000, 0xC0000000000000, 0xC0000000000000000],
                                                [uint256(0x300), 0x300000, 0x300000000, 0x300000000000, 0x300000000000000, 0x300000000000000000],
                                                [uint256(0xC00), 0xC00000, 0xC00000000, 0xC00000000000, 0xC00000000000000, 0xC00000000000000000] ];
        uint256[6][6] memory rightDownGroups = [ [uint256(0x3), 0xC00000, 0x300000000, 0xC0000000000, 0x30000000000000, 0xC000000000000000],
                                               [uint256(0xC), 0x3000, 0xC00000000, 0x300000000000, 0xC0000000000000, 0x30000000000000000],
                                               [uint256(0x30), 0xC000, 0x3000000, 0xC00000000000, 0x300000000000000, 0xC0000000000000000],
                                               [uint256(0xC0), 0x30000, 0xC000000, 0x3000000000, 0xC00000000000000, 0x300000000000000000],
                                               [uint256(0x300), 0xC0000, 0x30000000, 0xC000000000, 0x3000000000000, 0xC00000000000000000],
                                               [uint256(0xC00), 0x300000, 0xC0000000, 0x30000000000, 0xC000000000000, 0x3000000000000000] ];
                             
        uint256[6][6] memory leftDownGroups = [ [uint256(0x3), 0xC000, 0x30000000, 0xC0000000000, 0x300000000000000, 0xC00000000000000000],
                                                [uint256(0xC), 0x30000, 0xC0000000, 0x300000000000, 0xC00000000000000, 0x3000000000000000],
                                                [uint256(0x30), 0xC0000, 0x300000000, 0xC00000000000, 0x3000000000000, 0xC000000000000000],
                                                [uint256(0xC0), 0x300000, 0xC00000000, 0x3000000000, 0xC000000000000, 0x30000000000000000],
                                                [uint256(0x300), 0xC00000, 0x3000000, 0xC000000000, 0x30000000000000, 0xC0000000000000000],
                                                [uint256(0xC00), 0x3000, 0xC000000, 0x30000000000, 0xC0000000000000, 0x300000000000000000] ];
        if(isContract == false){   //checking if user wins, if this returns true user has won and if it returns false game goes on
            Counts memory oCounts = Counts(0, 0, 0, 0);
            Markers memory markers = Markers(0, 0, 0, 0);
            for(uint256 i; i < 6; ++i){
                markers.hMarker = (possibleTorus & horizontalGroups[mostRecentMove / 6][i]) % 3;
                markers.vMarker = (possibleTorus & verticalGroups[mostRecentMove % 6][i]) % 3;
                markers.rdMarker = (possibleTorus & rightDownGroups[(mostRecentMove + (mostRecentMove / 6)) % 6][i]) % 3;
                markers.ldMarker = (possibleTorus & leftDownGroups[(mostRecentMove - (mostRecentMove / 6)) % 6][i]) % 3;
                if(markers.hMarker == 1){
                    oCounts.hCount++;
                }
                if(markers.vMarker == 1){
                    oCounts.vCount++;
                }
                if(markers.rdMarker == 1){
                    oCounts.rdCount++;
                }
                if(markers.ldMarker == 1){
                    oCounts.ldCount++;
                }
            }
            if(oCounts.hCount >= 5 || oCounts.vCount >= 5 || oCounts.rdCount >= 5 || oCounts.ldCount >= 5){
                return true;
            }
            return false;
        }
        else{                 //checking if contract wins, if this returns true contract has won and if it returns false game goes on
            Counts memory xCounts = Counts(0, 0, 0, 0);
            Markers memory markers = Markers(0, 0, 0, 0);
            for(uint256 i; i < 6; ++i){
                markers.hMarker = (possibleTorus & horizontalGroups[mostRecentMove / 6][i]) % 3;
                markers.vMarker = (possibleTorus & verticalGroups[mostRecentMove % 6][i]) % 3;
                markers.rdMarker = (possibleTorus & rightDownGroups[(mostRecentMove + (mostRecentMove / 6)) % 6][i]) % 3;
                markers.ldMarker = (possibleTorus & leftDownGroups[(mostRecentMove - (mostRecentMove / 6)) % 6][i]) % 3;
                if(markers.hMarker == 2){
                    xCounts.hCount++;
                } 
                if(markers.vMarker == 2){
                    xCounts.vCount++;
                }
                if(markers.rdMarker == 2){
                    xCounts.rdCount++;
                }
                if(markers.ldMarker == 2){
                    xCounts.ldCount++;
                }
            }
            if(xCounts.hCount >= 5 || xCounts.vCount >= 5 || xCounts.rdCount >= 5 || xCounts.ldCount >= 5){
                return true;
            }
            return false;
        }
    }


    // @notice Updates the torusState to reflect the most recent moves made by the user and contract
    // @dev the user's move and the contract's response is updated at once to save gas
    // @param userPieceIndex is the cell at which the user places their marker
    // @param contractPieceIndex is the cell at where the contract places it's response mvoe  
    function updateState(uint256 userPieceIndex, uint256 contractPieceIndex) private {   //update both user move and contract move at once to change state as less often as possible
        uint256 updates = (1 << userPieceIndex * 2) | (1 << (contractPieceIndex*2+1));
        torusState |= updates;
    }


    // @notice Simply resets the donut to 0 which represents an empty board with no markers
    function resetTorus() private {
        torusState = 0;
    }
    

    // @notice checks if user's move is valid, computes optimal move for contract, and calls updateState to reflect the user's move and contract's response move 
    // @dev initially called from frontend to start everything else
    // @dev 108 is returned => everything was normal and game is still ongoing, 0~35 is returned => user wins with last move at that index, 36~71 is returned => contract wins with last move at that number-36, 72~107 is returned => tie with contract last move at that number-72
    // @param the cell index where the user places their marker 
    function userMove(uint256 userPieceIndex) public returns (uint256) {
        require(torusState & (3 << userPieceIndex*2) == 0);   //check if piece at userPieceIndex is empty aka 00
        uint256 torusStateCopy = torusState;
        torusStateCopy |= (1 << userPieceIndex*2);
        if(checkWin(torusStateCopy, userPieceIndex, false) == true) {
            //game ends, display "User wins" on frontend
			resetTorus();
            return userPieceIndex;
        }
        uint256 contractPieceIndex = uint256( searchForMove(torusStateCopy, 0, type(int).min, type(int).max) );
        if(contractPieceIndex >= 72 && contractPieceIndex <= 107){
			//game is tied with contract last move at cell #(contractPieceIndex-72)
			resetTorus();
            return contractPieceIndex;  
        }
        updateState(userPieceIndex, contractPieceIndex);
        if(checkWin(torusState, contractPieceIndex, false) == true) {
            //game ends, display "Contract wins" on frontend
			resetTorus();
            return (contractPieceIndex+36);
        }
        return 108;
    }


    // @dev: simply allows frontend to access the torusState so it can update the THREE.js object appropriately
    function getTorusState() public view returns (uint256) {
        return torusState;
    }
}
