pragma ton-solidity = 0.58.1;

interface IPlayerRoot {
    function updatePlayers(uint256 trackId, address[] playerAddresses, uint256[] totalPoints, uint32[] places) external view;
    function mintPlayerByWallet() external view;
    function getInfo() external view returns(
        TvmCell _playerCode,
        TvmCell _trackCode,
        address _trackRootAddr,
        uint128 _mintValue,
        uint128 _mintProcessingValue
    );
}