pragma ton-solidity = 0.58.1;

interface IParameterRoot {
    function updateParameters(uint256 trackId, address[] parameters, uint32[] prizePlaces) external view;
    function getInfo() external view returns(
        TvmCell _parameterCode,
        TvmCell _trackCode,
        address _trackRootAddr,
        uint128 _mintValue,
        uint128 _mintProcessingValue
    );
}