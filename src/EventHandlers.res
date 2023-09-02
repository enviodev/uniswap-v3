Handlers.FactoryContract.PoolCreated.loader((~event, ~context) => {
  context.contractRegistration.addPool(event.params.pool)
  context.factory.factoryLoad(Constants.factoryAddressStr)
  context.token.token0Load(event.params.token0->Ethers.ethAddressToStringLower, ~loaders={})
  context.token.token1Load(event.params.token1->Ethers.ethAddressToStringLower, ~loaders={})
})

Handlers.FactoryContract.PoolCreated.handler((~event, ~context) => {
  let factory = switch context.factory.factory {
  | Some(factory) => factory
  | None =>
    let factory: Types.factoryEntity = {
      id: Constants.factoryAddressStr,
      poolCount: Constants.zero,
      totalVolumeETH: 0.,
      totalVolumeUSD: 0.,
      untrackedVolumeUSD: 0.,
      totalFeesUSD: 0.,
      totalFeesETH: 0.,
      totalValueLockedETH: 0.,
      totalValueLockedUSD: 0.,
      totalValueLockedUSDUntracked: 0.,
      totalValueLockedETHUntracked: 0.,
      txCount: Constants.zero,
      owner: Constants.addressZeroStr,
    }
    let bundle: Types.bundleEntity = {
      id: "1",
      ethPriceUSD: 0.,
    }

    context.bundle.set(bundle)

    factory
  }

  let factory = {
    ...factory,
    poolCount: factory.poolCount->Ethers.BigInt.add(Constants.one),
  }

  let getOrInitializeToken = tokenId =>
    switch context.token.get(tokenId) {
    | Some(token) => token
    | None =>
      // TODO: implement contract function queries to fetch this data
      let decimals = Ethers.BigInt.fromInt(18) //fetchTokenDecimals(event.params.token0)

      let token: Types.tokenEntity = {
        id: tokenId,
        symbol: "TODO", // Load this from the contract.
        name: "TODO",
        totalSupply: Ethers.BigInt.fromStringUnsafe("1000000000000000000000000"), // TODO: load this from the contract.
        decimals,
        derivedETH: 0.,
        volume: 0.,
        volumeUSD: 0.,
        feesUSD: 0.,
        untrackedVolumeUSD: 0.,
        totalValueLocked: 0.,
        totalValueLockedUSD: 0.,
        totalValueLockedUSDUntracked: 0.,
        txCount: Constants.zero,
        poolCount: Constants.zero,
        whitelistPools: [],
      }
      token
    }

  let token0 = getOrInitializeToken(event.params.token0->Ethers.ethAddressToStringLower)
  let token1 = getOrInitializeToken(event.params.token1->Ethers.ethAddressToStringLower)

  let pool: Types.poolEntity = {
    id: event.params.pool->Ethers.ethAddressToString,
    token0: token0.id,
    token1: token1.id,
    feeTier: event.params.fee,
    createdAtTimestamp: event.blockTimestamp,
    createdAtBlockNumber: event.blockNumber,
    liquidityProviderCount: Constants.zero,
    txCount: Constants.zero,
    liquidity: Constants.zero,
    sqrtPrice: Constants.zero,
    feeGrowthGlobal0X128: Constants.zero,
    feeGrowthGlobal1X128: Constants.zero,
    token0Price: 0.,
    token1Price: 0.,
    observationIndex: Constants.zero,
    totalValueLockedToken0: 0.,
    totalValueLockedToken1: 0.,
    totalValueLockedUSD: 0.,
    totalValueLockedETH: 0.,
    totalValueLockedUSDUntracked: 0.,
    volumeToken0: 0.,
    volumeToken1: 0.,
    volumeUSD: 0.,
    feesUSD: 0.,
    untrackedVolumeUSD: 0.,
    tick: None,
    collectedFeesToken0: 0.,
    collectedFeesToken1: 0.,
    collectedFeesUSD: 0.,
  }

  let addWhitelistPoolToToken = (token: Types.tokenEntity) =>
    if (
      Belt.Array.some(Constants.whitelistTokens, tokenOnWhitelist =>
        tokenOnWhitelist == token.id->Js.String2.toLowerCase
      )
    ) {
      {...token, whitelistPools: token.whitelistPools->Belt.Array.concat([pool.id])}
    } else {
      token
    }
  // update white listed pools
  let token0 = addWhitelistPoolToToken(token0)
  let token1 = addWhitelistPoolToToken(token1)

  context.pool.set(pool)

  context.factory.set(factory)

  context.token.set(token0)
  context.token.set(token1)
})
