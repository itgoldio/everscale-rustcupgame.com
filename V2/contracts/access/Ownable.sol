pragma ton-solidity = 0.58.1;

import "../errors/AccessErrors.sol";

abstract contract Ownable {

    uint256 private ownerPubkey;

    event OwnershipTransfered(uint256 previousKey, uint256 newOwner);

    constructor(uint256 _ownerPubkey) public {
        require(_ownerPubkey != 0, AccessErrors.pubkey_is_zero);
        _transferOwnership(_ownerPubkey);
    }

    function owner() public view virtual returns(uint256) {
        return ownerPubkey;
    }

    modifier onlyOwner() {
        require(owner() == msg.pubkey(), AccessErrors.sender_is_not_owner);
        _;
    }

    function transferOwnership(uint256 newPubkey) external virtual onlyOwner {
        require(newPubkey != 0, 100);
        tvm.accept();
        _transferOwnership(newPubkey);
    }

    function _transferOwnership(uint256 newPubkey) internal virtual {
        uint256 oldPubkey = ownerPubkey;
        ownerPubkey = newPubkey;
        emit OwnershipTransfered(oldPubkey, newPubkey);
    }
}