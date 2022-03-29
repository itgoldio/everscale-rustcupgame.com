# 🏁RustCupGame

**TODO:** add game description.

## How to play?

First collection is sold out!

Buy car on secondary markets [Rust Cup Game Cars Collection #1](https://grandbazar.io/collection/rust_cup_game_cars)

Open [debot's browser](https://ever.surf/) and run debot: ```0:645ce51da11cb1cddbb0c0de848c4dbda46f75470602bb3e2b6ce9fd28727e8e```

or scan QR code

![DebotQR](img\debotQR.jpg)

## How it work?

All logic inside blockchain on smart contracts

![schema](img\Diagram.png)

### Wallet
It's your wallet, that own your car NFT

### Debot
DeBot technology makes end-to-end decentralization when working with Smart Contracts.
It's decentralized interface for interaction with game smart contracts.

You can see your cars, current tracks and run to race.
### Queue
Queue contract collect cars before race started

### Root
Root contract is waiting request from ``Queue`` with cars and modifications. It's generating new random ``track`` and activate ``track``. 

### Track
Every tracks consist random set of regions. When race on track started:
- Track collects info about regions
- For every regions
- - A random number is thrown from 1 to 100
- - Calculate cars points score for region
- After last region
- - Compare cars points
- - Distributes rewards 
- - Update cars statistics use ``Editor`` contract

### Editor
The ``Editor`` update cars statistics in ``Car parameters`` contracts

### Car parameters
The ``Car parameters`` store statistics for car. 

## How to calculate points
Car contains parameters:
| Name            | Description                                                                                |
|-----------------|--------------------------------------------------------------------------------------------|
| **SPEED**       | The maximum speed at which the cars is moving                                              |
| **ACCELERATION**| The time it takes the cars to accelerate from 0 speed                                      |
| **BRAKING**     | The time it takes the cars to reset the speed to 0                                         |
| **CONTROL**     | A coefficient that allows you to effectively pass turns and difficult sections of the route|

Region contains parameters:

Car contains parameters:
| Name                   | Description                                                                         |
|------------------------|-------------------------------------------------------------------------------------|
| **Control coefficient**| Randomness factor in the game, affects the final points on the site                 |
| **Max input speed**    | Maximum input speed for region                                                      |
| **Max output speed**   | Maximum output speed for region                                                     |

Car points are calculated use a formula. 


