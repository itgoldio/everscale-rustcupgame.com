pragma ton-solidity = 0.58.1;

import "../errors/AccessErrors.sol";

abstract contract Pausable {

    event Paused(address manager);
    event Unpaused(address manager);

    bool private paused;

    constructor() public {
        paused = false;
    }

    function status() public view virtual returns(bool) {
        return(paused);
    }

    modifier whenNotPaused() {
        require(!status(), AccessErrors.paused);
        _;
    }

    modifier whenPaused() {
        require(status(), AccessErrors.unpaused);
        _;
    }

    function _pause() internal virtual whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }
}