pragma ton-solidity = 0.58.1;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "../../interfaces/IPlayer.sol";
import "../../interfaces/IQueue.sol";
import "../../errors/PlayerErrors.sol";

interface PlayerEvents{
    event UpdateStatistics(
        uint256 totalPoints, 
        uint32 place
    );
}

contract Player is IPlayer, PlayerEvents {

    address static playerRootAddr;
    address static playerWalletAddr;

    uint256 totalPoints;
    uint32 totalRaces;
    uint32[] prizePlaces;

    constructor(
        uint256 _totalPoints,
        uint32 _totalRaces,
        uint32[] _prizePlaces
    ) public onlyPlayerRoot {
        tvm.accept();
        totalPoints = _totalPoints;
        totalRaces = _totalRaces;
        for (uint8 i = 0; i < _prizePlaces.length; i++) {
            prizePlaces.push(_prizePlaces[i]);
        }
    }

    function updateStatisticByPlayerRoot(uint256 _totalPoints, uint32 _place) external override onlyPlayerRoot {
        tvm.accept();
        totalPoints += _totalPoints;
        totalRaces++;
        if(_place < prizePlaces.length) {
            prizePlaces[_place]++;
        }
        emit PlayerEvents.UpdateStatistics(
            _totalPoints,
            _place
        );
    }

    function getInfo() external override responsible view returns(
        address _playerRootAddr,
        address _playerWalletAddr,
        uint256 _totalPoints,
        uint32 _totalRaces,
        uint32[] _prizePlaces
    ) {
        return {
            value: 0,
            flag: 64
        }(
            playerRootAddr,
            playerWalletAddr,
            totalPoints, 
            totalRaces, 
            prizePlaces
        );
    }

    modifier onlyPlayerRoot() {
        require(msg.sender == playerRootAddr, PlayerErrors.sender_is_not_root);
        _;
    }
}