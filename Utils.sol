// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Utils {

    // 判断一个address是否为协约地址
    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function encodeMessagep3(address to, uint256 value) internal pure returns (bytes32)
    {
        bytes32 value_b32 = bytes32(value);
        return keccak256(abi.encodePacked(to, value_b32));
    }


    // 将RSV进行切割， RSV中的v必须转换为16进制
    // 0xaf8bc66a51d3ac2798b21e533d0e97baf0ec6f85123967d783dc7cb182bf6db92f8d65d86a7edb2796a5e4f047528f5fdcb39e7cea572702f4b4ff7068a210961c
    bytes public r;
    bytes public s;
    function splitRsv(bytes memory rsv) public returns (bytes32 r_result, bytes32 s_result, uint8 v_result) {
        require(rsv.length == 65);
        r = new bytes(0);
        s = new bytes(0);
        uint8 v;
        for(uint i = 0; i < 32; i++) {
            r.push(rsv[i]);
        }
        for(uint i = 32; i < 64; i++) {
            s.push(rsv[i]);
        }
        for(uint i = 64; i < 65; i++) {
            v = uint8(rsv[i]);
        }
        
        string memory r_str = string(r);
        bytes32 R_;
        assembly {
            R_ := mload(add(r_str, 32))
        }
        
        string memory s_str = string(s);
        bytes32 S_;
        assembly {
            S_ := mload(add(s_str, 32))
        }
        
        return(R_, S_, v);
    }

    // bytes => bytes32
    function bytesToBytes32(bytes memory b, uint offset) private pure returns (bytes32) {
        bytes32 out;
        for (uint i = 0; i < 32; i++) {
        out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    // string => bytes32
    function stringToBytes32(string memory source)
        internal
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    // string => bytes
    function stringToBytes(string memory source)
        internal
        pure
        returns (bytes memory result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        return tempEmptyStringTest;
    }

    // address 转 string
    // 输入 0xXXXYYYZZZ 输出字符串 0xXXXYYYZZZ
    // function addressToString(address _addr) public pure returns(string memory) 
    // {
    //     bytes32 value = bytes32(uint256(_addr));
    //     bytes memory alphabet = "0123456789abcdef";

    //     bytes memory str = new bytes(51);
    //     str[0] = '0';
    //     str[1] = 'x';
    //     for (uint256 i = 0; i < 20; i++) {
    //         str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
    //         str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
    //     }
    //     return string(str);
    // }

    // 将 address 转为： {"event":"toAccountAddr", "accountAddr":"0xXXXXXXXXXX"}
    // function eventToAccountAddrJson(address account) public pure returns(bytes  memory x){
    //     // string memory accountAddr_str = addressToString(account);
    //     bytes memory data1 = "{\"event\":\"toAccountAddr\", \"accountAddr\":\"";
    //     bytes memory data3 = "\"}";
    //     bytes memory accountAddr_byte = bytes(addressToString(account));
    //     bytes memory mid = bytesConcat(data1, accountAddr_byte);
    //     bytes memory ret_json = bytesConcat(mid, data3);
    //     return ret_json;
    // }

    // bytes_all = bytes_1 + bytes_2 连接
    function bytesConcat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        public
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }
}
