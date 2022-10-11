pragma ton-solidity = 0.58.1;

import "../errors/AccessErrors.sol";

abstract contract Manageable {

    uint256 private managerPubkey;

    event ChangeManager(uint256 previousManager, uint256 newManager);

    constructor(uint256 _managerPubkey) public {
        require(_managerPubkey != 0, AccessErrors.pubkey_is_zero);
        _changeManager(_managerPubkey);
    }

    function manager() external view virtual returns(uint256) {
        return managerPubkey;
    }

    modifier onlyManager() {
        require(msg.pubkey() == managerPubkey, AccessErrors.sender_is_not_manager);
        _;
    }

    function _changeManager(uint256 newManagerPubkey) internal virtual {
        uint256 oldManagerPubkey = newManagerPubkey;
        managerPubkey = newManagerPubkey;
        emit ChangeManager(oldManagerPubkey, newManagerPubkey);
    }
}