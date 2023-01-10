//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;




contract MasterContract {

  address[] public slaveContracts;

  constructor() {

    assembly {

    //Encoding the contract's initialization of the Trade Contract with the contract's constructor function selector

    let initCode := mload(0x40)

    let selector := and(0xff, shl(mload(0x40), 24))

    mstore(0x40, or(initCode, selector))

    initCode := mload(0x40)




    // Creating the Trade Contract at a brute forced address using the CREATE2 OPCODE

    let salt := 0x0000000000000000000000000000000000000000000000000000000000000001

    let addr := create2(0, add(salt, initCode), 0, 0)

    //Saving the address of the trade contract at slot 0

    sstore(15, addr)

    sstore(10, 0)

    }

  }




  function fetchAddress() public view returns(address){

    assembly{

      let tradeAddress := sload(15)

      mstore(0x80, tradeAddress)

      return(0x80, 32)

    }

  }




  fallback () external {

    

    assembly{




      switch getSelector()




      case 0x35832aef{

        //get array

        return(mload(slaveContracts.slot), 0x20)

      }




      case 0x9d07ab73 {

        //view previous weth balance

        return(10, 0x20)

      }




      case 0xe72c7e37 {

      //update weth balance slot

        sstore(10, calldataload(4))

      }

      

      //Helpers

      function getSelector() -> getSlt{

        getSlt := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)

      }

      

    }

    if (msg.data[0] == 0xdd){

      //create and add slave contract to array

      address newSlaveContract;

      assembly{

        let creationCode := 0x5860208158601c335a63aaf10f428752fa158151803b80938091923cf3

        let init := mload(creationCode)

        // getting salt from calldata

        let salt := calldataload(4)

        newSlaveContract := create2(0, add(0x20, creationCode), init, salt)

      }

      slaveContracts.push(newSlaveContract);

    }

    

  }

}
