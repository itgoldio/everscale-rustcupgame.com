pragma ton-solidity = 0.58.1;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "../../interfaces/IRandomGenerator.sol";

import "../../access/Ownable.sol";
import "../../access/Manageable.sol";

interface RandomGeneratorEvents {
    event GenerateArray(uint8 [] randoms);
}

contract RandomGenerator is IRandomGenerator, Ownable, RandomGeneratorEvents {

    constructor(uint256 ownerPubkey)
    Ownable(ownerPubkey)
    public {
        tvm.accept();
    }

    function getRandomArray(uint8 size, uint8 limit, uint8 offset) external responsible override view returns(uint8[] randoms) {
        tvm.rawReserve(0, 4);
        for (uint8 i = 0; i < size; i++) {
            randoms.push(uint8(_getRandomNumber(limit) + offset));
        }
        emit RandomGeneratorEvents.GenerateArray(randoms);
        return {
            value: 0,
            flag: 128
        }(randoms);
    }

    function _getRandomNumber(uint8 limit) internal pure returns(uint64 number) {
        rnd.shuffle();
        number = uint64(rnd.next(limit));
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