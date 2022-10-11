pragma ton-solidity = 0.58.1;
pragma AbiHeader expire;
pragma AbiHeader pubkey;
pragma AbiHeader time;

import "../../access/Ownable.sol";

import "../../interfaces/IFormula.sol";

contract Formula is IFormula, Ownable {

    uint16 constant POINTS_DIV_VALUE = 2;

    constructor(uint256 ownerPubkey) Ownable(ownerPubkey)
    public {
        tvm.accept();
    }

    function calculate(
        RegionStruct region,
        uint8 playersCount,
        uint8[] speed,
        uint8[] acceleration,
        uint8[] braking,
        uint8[] control,
        uint8 lastVel,
        uint8 random,
        uint8 regionNumber,
        bool isLastRegion
    ) external responsible override view returns(
        uint256[] totalPoints,
        uint8 currentVel,
        bool[] controlLosses,
        uint8 currentRegionNumber
    ) {
        tvm.rawReserve(0, 4);
        for(uint8 i = 0; i < playersCount; i++) {
            if(regionNumber == 0) {
                totalPoints.push(speed[i] + acceleration[i] + braking[i]);
            }
            else {
                if(region.vel > lastVel) {
                    if(region.vel < 5) {
                        totalPoints.push(speed[i] + braking[i]);
                    }
                    else {
                        totalPoints.push(speed[i] + acceleration[i]);
                    }
                }
                else if(region.vel == lastVel) {
                    if(region.vel < 3) {
                        totalPoints.push(acceleration[i] + braking[i]);
                    }
                    else if(region.vel < 6) {
                        totalPoints.push(speed[i] + braking[i]);
                    }
                    else {
                        totalPoints.push(speed[i] + acceleration[i]);
                    }
                }
                else if(region.vel < lastVel) {
                    if(region.vel < 4) {
                        totalPoints.push(acceleration[i] + braking[i]);
                    }
                    else {
                        totalPoints.push(speed[i] + braking[i]);
                    }
                }
            }
            if(int16(control[i]) + int16(int16(region.vel) - int16(lastVel)) * 5 < random) {
                totalPoints[i] = totalPoints[i] / 2;
                controlLosses.push(true);
            }
            else {
                controlLosses.push(false);
            }

            // Points divide
            totalPoints[i] = totalPoints[i] / POINTS_DIV_VALUE;

            // Last region +100 points
            if(isLastRegion) {
                totalPoints[i] += 100;
            }
        }
        return{value: 0, flag: 128}(
            totalPoints,
            region.vel,
            controlLosses,
            regionNumber
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