(async () => {
    try {
        
        // Run this to deply a Web3 version of the contract commented below
        console.log('Running deployWithWeb3 script...')
        
        const contractName = 'UnitMarketplace' // Change this for other contract
        const constructorArgs = []    // Put constructor args (if any) here for your contract
    
        // Note that the script needs the ABI which is generated from the compilation artifact.
        // Make sure contract is compiled and artifacts are generated
        const artifactsPath = `artifacts/${contractName}.json` // Change this for different path
        
        const metadata = JSON.parse(await remix.call('fileManager', 'getFile', artifactsPath))
        const accounts = await web3.eth.getAccounts()
        const gasLimit = 6000000
        let contract = new web3.eth.Contract(metadata.abi, {
            gas:gasLimit
        })
    
        contract = contract.deploy({
            data: metadata.data.bytecode.object,
            arguments: constructorArgs
        })
    
        const newContractInstance = await contract.send({
            from: accounts[0],
            gas: 4000000,
            gasPrice: '30000000000'
        })
        console.log('Contract deployed at address: ', newContractInstance.options.address)
    } catch (e) {
        console.log(e.message)
    }
  })()