// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IERC721LockFirst {
	event Lock(address indexed owner, address indexed to, uint256 indexed tokenId);
	
	event UnLock(uint256 indexed tokenId);
	
    function lock(address to, uint256 tokenId) external;
    
    function unlock(uint256 tokenId) external;
	
    function isLocked(uint256 tokenId) external view returns (bool);
	
    function getLocked(uint256 tokenId) external view returns (address operator);
}