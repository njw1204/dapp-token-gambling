pragma solidity ^0.5.0;


contract Util {
    uint256 internal constant UINT256_MAX = ~uint256(0);
    uint256 internal constant UINT250_MAX = UINT256_MAX >> 6;

    function max256(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y) ? x : y;
    }

    function min256(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x < y) ? x : y;
    }

    function dumbRandom256() internal view returns (uint256) {
        // randomly generate uint256, but this is stupid way
        return uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1), block.difficulty,
                    block.timestamp, msg.sender
                )
            )
        );
    }
}