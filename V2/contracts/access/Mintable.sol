pragma ton-solidity = 0.58.1;

import "../errors/AccessErrors.sol";

abstract contract Mintable {

    uint256 private minterPubkey;

    event ChangeMinter(uint256 previousMinter, uint256 newMinter);

    constructor(uint256 _minterPubkey) public {
        require(_minterPubkey != 0, AccessErrors.pubkey_is_zero);
        _changeMinter(_minterPubkey);
    }

    function minter() external view virtual returns(uint256) {
        return minterPubkey;
    }

    modifier onlyMinter() {
        require(msg.pubkey() == minterPubkey, AccessErrors.sender_is_not_minter);
        _;
    }

    function _changeMinter(uint256 newMinterPubkey) internal virtual {
        uint256 oldMinterPubkey = newMinterPubkey;
        minterPubkey = newMinterPubkey;
        emit ChangeMinter(oldMinterPubkey, newMinterPubkey);
    }
}