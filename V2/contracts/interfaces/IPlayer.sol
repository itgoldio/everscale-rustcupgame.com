pragma ton-solidity = 0.58.1;

interface IPlayer {
    function updateStatisticByPlayerRoot(uint256 _totalPoints, uint32 _place) external;
    function getInfo() external view responsible returns(
        address _playerRootAddr,
        address _playerWalletAddr,
        uint256 _totalPoints,
        uint32 _totalRaces,
        uint32[] _prizePlaces
    );
}