pragma ton-solidity = 0.58.1;

import "../src/Parameter/Parameter.sol";

contract ParameterResolver {

    function resolveParameter(TvmCell parameterCode, address carNftAddr, address parameterRootAddr) public responsible pure returns(address parameterAddr) {
        return {
            value: 0,
            flag: 64
        }(address(tvm.hash(_buildParameterState(parameterCode, carNftAddr, parameterRootAddr))));
    }

    function _buildParameterState(TvmCell parameterCode, address carNftAddr, address parameterRootAddr) internal pure returns(TvmCell) {
        return tvm.buildStateInit({
            contr: Parameter,
            varInit: {
                parameterRootAddr: parameterRootAddr,
                carNftAddr: carNftAddr
            },
            code: parameterCode
        });
    }

}