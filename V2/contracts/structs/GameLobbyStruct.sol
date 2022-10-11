pragma ton-solidity = 0.58.1;

import "./PlayerStruct.sol";
import "./BoosterStruct.sol";

struct GameLobbyStruct {
    string name;
    string description;
    uint8 maxPlayers;
    uint128 price;
    uint8 minRegions;
    uint8 maxRegions;
    uint8[] rewardSchema;
    string[] carName;
    address[] playerWalletAddr;
    address[] playerStatisticAddr; 
    address[] carNftAddr;
    address[] carNftParametersAddr;
    uint8[] speed;
    uint8[] acceleration;
    uint8[] braking;
    uint8[] control;
    BoosterStruct[] boosters;
    uint256[] results;
}