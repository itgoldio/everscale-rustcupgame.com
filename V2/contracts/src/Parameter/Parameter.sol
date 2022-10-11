pragma ton-solidity = 0.58.1;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "../../interfaces/IParameter.sol";

import "../../errors/ParameterErrors.sol";

interface ParameterEvents {
    event UpdateParameter(uint32 prizePlace);
    event BurnParameter(address parameterRootAddr);
    event EditParameter(
        string carName,
        string carDescription,
        uint8 speed,
        uint8 acceleration,
        uint8 braking,
        uint8 control
    );
}

contract Parameter is IParameter, ParameterEvents {

    address static parameterRootAddr;
    address static carNftAddr;

    string carName;
    string carDescription;

    uint8 speed;
    uint8 acceleration;
    uint8 braking;
    uint8 control;

    uint32 totalRaces;
    uint32[] prizePlaces;

    constructor(
        string _carName,
        string _carDescription,
        uint8 _speed,
        uint8 _acceleration,
        uint8 _braking,
        uint8 _control,
        uint32 _totalRaces,
        uint32[] _prizePlaces
    ) public onlyParameterRoot {
        tvm.accept();
        carName = _carName;
        carDescription = _carDescription;
        speed = _speed;
        acceleration = _acceleration;
        braking = _braking;
        control = _control;
        totalRaces = _totalRaces;
        prizePlaces = _prizePlaces;
    }

    function updateParametersByParameterRoot(uint32 prizePlace) external override onlyParameterRoot {
        tvm.accept();
        totalRaces++;
        if(prizePlace < prizePlaces.length) {
            prizePlaces[prizePlace]++;
        }
        emit ParameterEvents.UpdateParameter(prizePlace);
    }

    function burnByParameterRoot() external override onlyParameterRoot {
        tvm.accept();
        emit ParameterEvents.BurnParameter(parameterRootAddr);
        selfdestruct(parameterRootAddr);
    }

    function editParametersByPlayerRoot(
        string _carName,
        string _carDescription,
        uint8 _speed,
        uint8 _acceleration,
        uint8 _braking,
        uint8 _control
    ) external override onlyParameterRoot {
        tvm.accept();
        carName = _carName;
        carDescription = _carDescription;
        speed = _speed;
        acceleration = _acceleration;
        braking = _braking;
        control = _control;
        emit ParameterEvents.EditParameter(
            carName,
            carDescription,
            speed,
            acceleration,
            braking,
            control
        );
    }

    function getInfo() external override responsible view returns(
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
    ) {
        return {
            value: 0,
            flag: 64
        }(
            parameterRootAddr,
            carNftAddr,
            carName,
            carDescription,
            speed,
            acceleration,
            braking,
            control,
            totalRaces,
            prizePlaces
        );
    }

    modifier onlyParameterRoot() {
        require(msg.sender == parameterRootAddr, ParameterErrors.sender_is_not_root);
        _;
    }
}