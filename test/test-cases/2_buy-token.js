exports.testBuyToken = async (accounts) => {
    let erc721;
    let marketplaceInstance;
  
    before(async () => {
      erc721 = await TestERC721.deployed();
      marketplaceInstance = await TheeNFTMarketplace.deployed();
    });
  
    it('Should pay coin to buy token', async () => {
      const allListings = await marketplaceInstance.getTokenListings(
        erc721.address,
        0,
        10
      );
      const tokenToBuy = allListings[0];
      const allTokenBids = await marketplaceInstance.getTokenBids(
        erc721.address,
        tokenToBuy.tokenId
      );
  
      const receipt = await marketplaceInstance.buyToken(
        erc721.address,
        tokenToBuy.tokenId,
        {
          from: accounts[4],
          value: tokenToBuy.value,
        }
      );
  
      console.log('Buy token gas', receipt.receipt.gasUsed);
  
      const buyLog = receipt.logs.find((log) => log.event === 'TokenBought');
      assert.equal(buyLog.args.tokenId, tokenToBuy.tokenId);
      assert.equal(
        web3.utils.fromWei(buyLog.args.listing.value),
        web3.utils.fromWei(tokenToBuy.value)
      );
      assert.equal(buyLog.args.listing.seller, tokenToBuy.seller);
      console.log('serviceFee', web3.utils.fromWei(buyLog.args.serviceFee));
      console.log('royaltyFee', web3.utils.fromWei(buyLog.args.royaltyFee));
  
      const allListingsAfter = await marketplaceInstance.getTokenListings(
        erc721.address,
        0,
        10
      );
      assert.equal(allListingsAfter.length, allListings.length - 1);
  
      const allTokenBidsAfter = await marketplaceInstance.getTokenBids(
        erc721.address,
        tokenToBuy.tokenId
      );
  
      assert.equal(allTokenBidsAfter.length, allTokenBids.length - 1);
    });
  };
  
  // First time:
  // After: Listings
  // 2-4 => 1ETH => account3-5
  
  // After: Bids
  //
  // 0 => 2ETH => account3
  //
  // 0 => 4ETH => account5
  //
  // 1 => 1ETH => account6
  // 2 => 1ETH => account6
  // 3 => 1ETH => account6
  
  // Second time:
  // After: Listings
  // 3-4 => 1ETH => account4-5
  
  // After: Bids
  // 1 => 1ETH => account6
  // 2 => 1ETH => account6
  // 3 => 1ETH => account6
  