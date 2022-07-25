# 🏁RustCupGame V2 - Player

## About
The `Player` smart-contract is a ___SUB-NFT___ (Owned only by developers) for __Wallet__.

## Resolve `Player` address from `PlayerRoot`

1. Open [ton.bytie.moe](https://ton.bytie.moe/executor)
2. Click __Connect wallet__.
3. Load ABI: `PlayerRoot.abi.json`.
4. Paste `PlayerRoot` address & click __Search__.
5. Run local `resolvePlayer` function.

|Input|Type|Description|
|-|-|-|
__answerId__|_uint32_|Callback `functionId`, use 0 for run local.|
__playerCode__|_TvmCell_|`Player` code, paste data from file `Player.base64`.|
__playerWalletAddr__|_address_|Address of user __Wallet__.|
__playerRootAddr__|_address_|Address of `PlayerRoot` contract.

|Output|Type|Description|
|-|-|-|
__playerAddr__|_address_|`Player` address for this user __Wallet__.|

## Read `Player`

1. Open [ton.bytie.moe](https://ton.bytie.moe/executor)
2. Click __Connect wallet__.
3. Load ABI: `Player.abi.json`.
4. Paste `Player` address & click __Search__.
5. Run local `getInfo` function.

|Input|Type|Description|
|-|-|-|
__answerId__|_uint32_|Callback `functionId`, use 0 for run local.|

|Output|Type|Description|
|-|-|-|
___playerRootAddr__|_address_|`PlayerRoot` address.|
___playerWalletAddr__|_address_|User __Wallet__ address.|
___totalPoints__|_uint256_|_Not available, coming soon (now is 0)_.|
___totalRaces__|_uint32_|All races counter.|
___prizePlaces__|_uint32[]_|__#1__,__#2__ and __#3__ place counter.|


## Events

|Events|Results|Description|
|-|-|-|
__UpdateStatistics__|uint256 totalPoints|_Not available, coming soon (now is 0)_.|
||uint32 place|Prize place from last race.