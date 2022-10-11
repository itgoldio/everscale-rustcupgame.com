pragma ton-solidity = 0.58.1;

interface IParameter {
    function editParametersByPlayerRoot(
        string _carName,
        string _carDescription,
        uint8 _speed, 
        uint8 _acceleration, 
        uint8 _braking, 
        uint8 _control
    ) external;
    function updateParametersByParameterRoot(uint32 prizePlace) external;
    function burnByParameterRoot() external;
    function getInfo() external view responsible returns(
        address _parameterRootAddr,
        address _carNftAddr,
        string _carName,
        string _carDescription,
        uint8 _speed,
        uint8 _acceleration,
        uint8 _braking,
        uint8 _control,
        uint32 _totalRaces,
        uint32[] _prizePlaces
    );
}