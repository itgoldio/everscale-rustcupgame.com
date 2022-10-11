pragma ton-solidity = 0.58.1;

import "../src/Player/Player.sol";

contract PlayerResolver {

    function resolvePlayer(TvmCell playerCode, address playerWalletAddr, address playerRootAddr) public responsible pure returns(address playerAddr) {
        return {
            value: 0,
            flag: 64
        }(address(tvm.hash(_buildPlayerState(playerCode, playerWalletAddr, playerRootAddr))));
    }

    function _buildPlayerState(TvmCell playerCode, address playerWalletAddr, address playerRootAddr) internal pure returns(TvmCell) {
        return tvm.buildStateInit({
            contr: Player,
            varInit: {
                playerRootAddr: playerRootAddr,
                playerWalletAddr: playerWalletAddr
            },
            code: playerCode
        });
    }

}