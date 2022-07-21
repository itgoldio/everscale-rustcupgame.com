# 🏁RustCupGame V2 - Track

## About
This is the `Track` smart-contract on which the points for the race regions are distributed.

## Read `Track`

1. Open [ton.bytie.moe](https://ton.bytie.moe/executor)
2. Click __Connect wallet__.
3. Load ABI: `Track.abi.json`.
4. Paste `Track` address & click __Search__.
5. Run local `getInfo` function.

|Output|Type|Description|
|-|-|-|
___trackRootAddr__|_address_|`TrackRoot` address.|
___trackId__|_uint256_|_Nonce_ for `Track`.|
___formulaAddr__|_address_|`Formula` address.|
___randomGeneratorAddr__|_address_|`RandomGenerator` address.|
___playerRootAddr__|_address_|`PlayerRoot` address.|
___parameterRootAddr__|_address_|`ParameterRoot` address.|
___feeAccumulationAddr__|_address_|Address for withdraw platform fee.|
___regionIndexes__|_uint8[]_|Array of random regions for this race.|
___regionDifficulties__|_uint8[]_|Array of difficulty levels for regions.|
___lobby__|_Struct_|General information about this race. Description of the structure below.|
___regions__|_Struct[]_|A set of all possible regions for this race.|

|Lobby Struct|Type|Description|
|-|-|-|
|__name__|_string_|Name of this lobby.|
|__description__|_string_|Description of this lobby.|
|__maxPlayers__|_uint8_|Players count.|
|__price__|_uint128_|Price for participation.|
|__minRegions__|_uint8_|MIN regions count.|
|__maxRegions__|_uint8_|MAX regions count.|
|__rewardSchema__|_uint8[]_|Array of reward distributions, where the 0th element is the developer reward.|
|__carName__|_string[]_|Array of car names.|
|__playerWalletAddr__|_string[]_|Array of user wallet addresses.|
|__playerStatisticAddr__|_string[]_|Array of `Player` contracts addresses.|
|__carNftAddr__|_string[]_|Array of car NFT addresses.|
|__carNftParametersAddr__|_string[]_|Array of `Parameter` contracts addresses.|
|__speed__|_uint8[]_|Array of boosted car `SPEED` parameters.|
|__acceleration__|_uint8[]_|Array of boosted car `ACCELERATION` parameters.|
|__braking__|_uint8[]_|Array of boosted car `BRAKING` parameters.|
|__control__|_uint8[]_|Array of boosted car `CONTROL` parameters.|
|__boosters__|_Struct[]_|Array of cars boosters.|
|__results__|_uint256[]_|Array of cars points for this race.|

|Booster Struct|Type|Decription|
|-|-|-|
|__name__|_string_|Name of this booster.|
|__speedBooster__|_int8_|Percentage improvement of the `SPEED` parameter.|
|__accelerationBooster__|_int8_|Percentage improvement of the `ACCELERATION` parameter.|
|__brakingBooster__|_int8_|Percentage improvement of the `BRAKING` parameter.|
|__controlBooster__|_int8_|Percentage improvement of the `CONTROL` parameter.|

|Region Struct|Type|Decription|
|-|-|-|
|__name__|_string_|Name of this Region.|
|__vel__|_uint8_|Region velocity parameter.|
6. Event `RegionComplite` for check race step by step:
```
{
    "event": "RegionComplite",
    "input": {
	/// Points before this region
      "beforePoints": [
        "0",
        "0",
        "0",
        "0"
      ],
	/// Points after this region
      "afterPoints": [
        "72",
        "72",
        "44",
        "82"
      ],
	/// Flag of control loss (CRASH)
      "controlLosses": [
        false,
        false,
        true,
        false
      ],
	/// Region difficulty parameter (RND)
      "regionDifficulty": "51",
	/// Region number (RN)
      "regionNumber": "0",
	/// Region struct
      "region": {
		/// name
        "regionName": "Start",
		/// Region velocity parameter
        "vel": "4"
      }
    }
  }
```