exports.testTransferToken = async (accounts) => {
    let erc721;
    let marketplaceInstance;
    erc721 = await TestERC721.deployed();
    marketplaceInstance = await TheeNFTMarketplace.deployed();
  
    it('Should transfer token and make listing invalid', async () => {
      const tokenId = 2;
      const listingBefore = await marketplaceInstance.getTokenListing(
        erc721.address,
        tokenId
      );
  
      // @ts-ignore
      await erc721.safeTransferFrom(listingBefore.seller, accounts[1], tokenId, {
        from: listingBefore.seller,
      });
  
      const listingAfter = await marketplaceInstance.getTokenListing(
        erc721.address,
        tokenId
      );
  
      assert.equal(Number(listingAfter.tokenId), 0);
    });
  };
  