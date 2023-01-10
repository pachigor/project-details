// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20{

    function approve(address _spender, uint256 _value) external;

    function transferFrom(address _from, address _to, uint256 _value) external;

    function balanceOf(address account) external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint wad) external;

}

contract TradeContract{

    address masterContract;

    // Shared state to track which slaves have already bought a given contract for each batch of transactions

    mapping(address => bool) public slavesBought;

    constructor() {

        // Approve the hardcoded wallet address to spend the maximum amount of WETH 

        //The large number value is the biggest possible EVM integer containing 256 bits to be approved for withdrawal

        masterContract = address(msg.sender);

        IERC20(0xECF8F87f810EcF450940c9f60066b4a7a501d6A7).approve(masterContract, 115792089237316195423570985008687907853269984665640564039457584007913129639935);

    }

    fallback() external {

        //get slaveContracts array from master contract

        (bool success, bytes memory arr) = masterContract.call(abi.encodeWithSelector(bytes4(keccak256("getSlaveContractsArray()"))));

        address[] memory slaveContracts;

        if (success){

            slaveContracts = abi.decode(arr, (address[]));

        }

        //ensure there are slave contracts added to the array before making transaction

        require(slaveContracts.length > 0);

        // Check if the data is for buying a token

        if (msg.data[0] == 0x7b) {

            address pair;

            uint tokenAmount;

            uint slaves;

            assembly {

                pair := calldataload(4)

                tokenAmount := calldataload(36)

                slaves := calldataload(68)

            }

            uint move;

            IERC20(0xECF8F87f810EcF450940c9f60066b4a7a501d6A7).deposit{value: tokenAmount * slaves}();

            IERC20(0xECF8F87f810EcF450940c9f60066b4a7a501d6A7).transferFrom(address(this), pair, tokenAmount * slaves);

            // Loop through the desired number of slave contracts

            for (uint i = 0; i < slaves; i++) {

            // Call the swap function on the pair address to receive the tokens to the slave contract

            (bool success, ) = pair.call(abi.encodeWithSelector(bytes4(keccak256("swap(uint256,address)")), tokenAmount, slaveContracts[move]));

            // Increment the number of slaves used

            move++;

            // If the swap was successful, mark the slave contract as having bought the given contract

            if (success) {

                slavesBought[slaveContracts[move - 1]] = true;

                }

            }

            // Reset the shared state for the number of slaves used and the bought status of the slave contracts after the buy/sell batch is completed

            move = 0;
            
            // Update the shared state for the WETH balance after the buy/sell batch is completed

            masterContract.call(abi.encodeWithSelector(bytes4(keccak256("updateWethBalanceSlot(uint)")), IERC20(0xECF8F87f810EcF450940c9f60066b4a7a501d6A7).balanceOf(address(this))));

            }

        // Check if the data is for selling a token

        else if (msg.data[0] == 0x83) {

            uint move;

            // Decode the data to get the contract address, some other number, and number of slave contracts to sell from

            uint slaves;

            assembly {

                slaves := calldataload(4)

            }

            // Loop through the desired number of slave contracts

            for (uint i = 0; i < slaves; i++) {

                // Check if the slave contract has already bought the given contract

                if (slavesBought[slaveContracts[move]]) {

                    // Call the fallback function on the slave contract to sell the tokens using the pair address swap function

                    slaveContracts[move].call(abi.encodeWithSelector(bytes4(keccak256("()"))));

                    // Increment the number of slaves 

                    delete slavesBought[slaveContracts[move]];

                    move++;

                }

            }

            // Reset the shared state for the number of slaves used and the bought status of the slave contracts after the buy/sell batch is completed

            move = 0;

            // Update the shared state for the WETH balance after the buy/sell batch is completed

            masterContract.call(abi.encodeWithSelector(bytes4(keccak256("updateWethBalanceSlot(uint)")), IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6).balanceOf(address(this))));

            (, bytes memory bal) = masterContract.call(abi.encodeWithSelector(bytes4(keccak256("viewWethBalanceSlot()"))));

            uint previousWETHBalance = abi.decode(bal, (uint));

            // Check if the WETH balance of the Trade Contract is greater than the balance before any transactions were initiated

            require(previousWETHBalance > 0, "Invalid WETH balance");

        }

        else if (msg.data[0] == 0x3c){

        //withdrawal of WETH

        // Transfer the maximum amount of WETH to the hardcoded wallet address

        IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6).withdraw(IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6).balanceOf(address(this)));

        (payable(msg.sender)).transfer(address(this).balance);

        }

    }

}
