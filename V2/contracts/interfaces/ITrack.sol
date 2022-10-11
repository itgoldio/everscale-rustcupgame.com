pragma ton-solidity = 0.58.1;

import "../structs/RegionStruct.sol";
import "../structs/GameLobbyStruct.sol";

interface ITrack {
    function destructByRoot(address dst) external;
    function withdrawByRoot(uint128 value, address dst) external;
    function getInfo() external view returns(
        address _trackRootAddr,
        uint256 _trackId,
        address _formulaAddr,
        address _randomGeneratorAddr,
        address _playerRootAddr,
        address _parameterRootAddr,
        address _feeAccumulationAddr,
        uint8[] _regionIndexes,
        uint8[] _regionDifficulties,
        GameLobbyStruct _lobby,
        RegionStruct[] _regions
    );
}