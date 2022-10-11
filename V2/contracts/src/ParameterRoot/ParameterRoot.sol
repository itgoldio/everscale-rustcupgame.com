pragma ton-solidity = 0.58.1;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "../../access/Ownable.sol";
import "../../access/Mintable.sol";
import "../../access/Manageable.sol";

import "../../interfaces/IParameter.sol";
import "../../interfaces/IParameterRoot.sol";

import "../../abstract/WorkTax.sol";

import "../Parameter/Parameter.sol";

import "../../errors/ParameterRootErrors.sol";

import "../../resolvers/ParameterResolver.sol";
import "../../resolvers/TrackResolver.sol";

library ParameterRootConstants {
    uint128 constant mint_value = 0.2 ton;
    uint128 constant mint_processing_value = 0.1 ton;
    uint128 constant work_tax_value = 0.05 ton;
}

interface ParameterRootEvents {
    event MintParameter(
        address carNftAddr,
        string carName,
        string carDescription,
        uint8 speed,
        uint8 acceleration,
        uint8 braking,
        uint8 control,
        uint32 totalRaces,
        uint32[] prizePlaces
    );
    event UpdateParameters(
        uint256 trackId, 
        address[] parameters, 
        uint32[] prizePlaces
    );
    event EditParameter(
        address parameterAddr,
        string carName,
        string carDescription,
        uint8 speed,
        uint8 acceleration,
        uint8 braking,
        uint8 control
    );
    event BurnParameter(
        address parameterAddr
    );
}

contract ParameterRoot is
IParameterRoot,
Ownable,
Mintable,
Manageable,
ParameterResolver,
TrackResolver,
WorkTax,
ParameterRootEvents {
    
    TvmCell parameterCode;
    TvmCell trackCode;
    address trackRootAddr;

    constructor(
        uint256 ownerPubkey,
        uint256 minterPubkey,
        uint256 managerPubkey,
        address _trackRootAddr,
        TvmCell _parameterCode,
        TvmCell _trackCode
    )
    Ownable(ownerPubkey)
    Mintable(minterPubkey)
    Manageable(managerPubkey)
    WorkTax(ParameterRootConstants.work_tax_value)
    public {
        tvm.accept();
        trackRootAddr = _trackRootAddr;
        parameterCode = _parameterCode;
        trackCode = _trackCode;
    }

    function mintParameter(
        address carNftAddr,
        string carName,
        string carDescription,
        uint8 speed,
        uint8 acceleration,
        uint8 braking,
        uint8 control,
        uint32 totalRaces,
        uint32[] prizePlaces
    ) external view onlyMinter returns(address newParameter) {
        require(address(this).balance > ParameterRootConstants.mint_value + ParameterRootConstants.mint_processing_value, ParameterRootErrors.contract_has_low_balance);
        tvm.accept();
        newParameter = new Parameter {
            code: parameterCode,
            value: ParameterRootConstants.mint_value,
            varInit: {
                parameterRootAddr: address(this),
                carNftAddr: carNftAddr
            }
        }(
            carName,
            carDescription,
            speed,
            acceleration,
            braking,
            control,
            totalRaces,
            prizePlaces
        );
        emit ParameterRootEvents.MintParameter(
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

    function updateParameters(uint256 trackId, address[] parameters, uint32[] prizePlaces) external override view {
        require(msg.sender == resolveTrack(trackCode, trackId, trackRootAddr), ParameterRootErrors.sender_is_not_updater);
        tvm.accept();
        for (uint8 i = 0; i < parameters.length; i++) {
            IParameter(parameters[i]).updateParametersByParameterRoot {
                value: _getCalculateTaxValue(1),
                flag: 0
            }(prizePlaces[i]);
        }
        emit ParameterRootEvents.UpdateParameters(
            trackId,
            parameters,
            prizePlaces
        );
    }

    function editParameter(
        address parameterAddr,
        string carName,
        string carDescription,
        uint8 speed,
        uint8 acceleration,
        uint8 braking,
        uint8 control
    ) external pure onlyManager {
        tvm.accept();
        IParameter(parameterAddr).editParametersByPlayerRoot {
            value: ParameterRootConstants.mint_processing_value,
            flag: 0
        }(
            carName,
            carDescription,
            speed,
            acceleration,
            braking,
            control
        );
        emit ParameterRootEvents.EditParameter(
            parameterAddr,
            carName,
            carDescription,
            speed,
            acceleration,
            braking,
            control
        );
    }

    function burnParameter(address parameterAddr) external pure onlyManager {
        tvm.accept();
        IParameter(parameterAddr).burnByParameterRoot {
            value: ParameterRootConstants.mint_processing_value,
            flag: 0
        }();
        emit ParameterRootEvents.BurnParameter(parameterAddr);
    }

    function resolveParameterCodeHash() external view returns(uint256 codeHash) {
        return(tvm.hash(parameterCode));
    }

    function changeMinter(uint256 newMinterPubkey) external onlyOwner {
        tvm.accept();
        _changeMinter(newMinterPubkey);
    }

    function changeManager(uint256 newManagerPubkey) external onlyOwner {
        tvm.accept();
        _changeManager(newManagerPubkey);
    }

    function setParameterCode(TvmCell newParameterCode) external onlyManager {
        tvm.accept();
        parameterCode = newParameterCode;
    }

    function setTrackCode(TvmCell newTrackCode) external onlyManager {
        tvm.accept();
        trackCode = newTrackCode;
    }

    function setTrackRootAddress(address newTrackRootAddr) external onlyManager {
        tvm.accept();
        trackRootAddr = newTrackRootAddr;
    }

    function getInfo() external override view returns(
        TvmCell _parameterCode,
        TvmCell _trackCode,
        address _trackRootAddr,
        uint128 _mintValue,
        uint128 _mintProcessingValue
    ) {
        return(
            parameterCode,
            trackCode,
            trackRootAddr,
            ParameterRootConstants.mint_value,
            ParameterRootConstants.mint_processing_value
        );
    }

    function withdraw(address dest, uint128 value, bool bounce) external pure onlyOwner {
        tvm.accept();
        dest.transfer(value, bounce, 0);
    }

    function destruct(address addr) external onlyOwner {
        tvm.accept();
        selfdestruct(addr);
    }
}