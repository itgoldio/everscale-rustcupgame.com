pragma ton-solidity = 0.58.1;

import "BoosterStruct.sol";

struct PlayerStruct {
    string carName;
    address playerWalletAddr;
    address playerStatisticAddr; 
    address carNftAddr;
    address carNftParametersAddr;
    uint8 speed;
    uint8 acceleration;
    uint8 braking;
    uint8 control;
    uint8 gameLobbyId;
    uint8 boosterId;
}