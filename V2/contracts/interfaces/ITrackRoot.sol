pragma ton-solidity = 0.58.1;

import "../structs/GameLobbyStruct.sol";

interface ITrackRoot {
    function mintTrack(GameLobbyStruct lobby) external;
    function getInfo() external view returns(
        address _queueAddr,
        address _randomGeneratorAddr,
        address _formulaAddr,
        address _playerRootAddr,
        address _parameterRootAddr,
        address _feeAccumulationAddr,
        TvmCell _trackCode,
        uint256 _trackSupply
    );
}