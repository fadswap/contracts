// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./SafeCast.sol";
import "./VirtualVote.sol";
import "./Vote.sol";


library LiquidVoting {
  using SafeMath for uint256;
  using SafeCast for uint256;
  using Vote for Vote.Data;
  using VirtualVote for VirtualVote.Data;

  struct Data {
    VirtualVote.Data data;
    uint256 weightedSum;
    uint256 defaultVote;
    mapping(address => Vote.Data) votes;
  }

  function updateVote(
    LiquidVoting.Data storage self,
    address user,
    Vote.Data memory oldVote,
    Vote.Data memory newVote,
    uint256 balance,
    uint256 totalSupply,
    uint256 defaultVote,
    function(address, uint256, bool, uint256) emitEvent
  ) internal {
    return _update(self, user, oldVote, newVote, balance, balance, totalSupply, defaultVote, emitEvent);
  }

  function updateBalance(
    LiquidVoting.Data storage self,
    address user,
    Vote.Data memory oldVote,
    uint256 oldBalance,
    uint256 newBalance,
    uint256 newTotalSupply,
    uint256 defaultVote,
    function(address, uint256, bool, uint256) emitEvent
  ) internal {
    return _update(self, user, oldVote, newBalance == 0 ? Vote.init() : oldVote, oldBalance, newBalance, newTotalSupply, defaultVote, emitEvent);
  }

  function _update(
    LiquidVoting.Data storage self,
    address user,
    Vote.Data memory oldVote,
    Vote.Data memory newVote,
    uint256 oldBalance,
    uint256 newBalance,
    uint256 totalSupply,
    uint256 defaultVote,
    function(address, uint256, bool, uint256) emitEvent
  ) internal {
    uint256 oldWeightedSum = self.weightedSum;
    uint256 newWeightedSum = oldWeightedSum;
    uint256 oldDefaultVote = self.defaultVote;
    uint256 newDefaultVote = oldDefaultVote;

    if(oldVote.isDefault()) {
      newDefaultVote = newDefaultVote.sub(oldBalance);
    } else {
      newWeightedSum = newWeightedSum.sub(oldBalance.mul(oldVote.get(defaultVote)));
    }

    if(newVote.isDefault()) {
      newDefaultVote = newDefaultVote.add(oldBalance);
    } else {
      newWeightedSum = newWeightedSum.add(newBalance.mul(newVote.get(defaultVote)));
    }

    if(newWeightedSum != oldWeightedSum){
      self.weightedSum = newWeightedSum;
    }

    if(newDefaultVote != oldDefaultVote){
      self.defaultVote = newDefaultVote;
    }

    {
      uint256 newResult = totalSupply == 0 ? defaultVote : newWeightedSum.add(newDefaultVote.mul(defaultVote)).div(totalSupply);
      VirtualVote.Data memory data = self.data;
      if(newResult != data.result){
        VirtualVote.Data memory sdata = self.data;
        (sdata.oldResult, sdata.result, sdata.time) = (
          data.current().toUint104(),
          newResult.toUint104(),
          block.timestamp.toUint48()
        );
      }
    }

    if(!newVote.eq(oldVote)){
      self.votes[user] = newVote;
    }

    emitEvent(user, newVote.get(defaultVote), newVote.isDefault(), newBalance);
  }
}