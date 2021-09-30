        //existing folding contracts dont need to be deployed
        // const stratFactory = await ethers.getContractFactory("StrategyBenqiWbtc");
        // deployedStrat = await stratFactory.deploy(governanceAddr, strategistAddr, controllerAddr, timelockAddr);

        // const globeFactory = await ethers.getContractFactory("SnowGlobeBenqiWbtc");
        // deployedGlobe = await globeFactory.deploy(assetAddr, governanceAddr, timelockAddr, controllerAddr);


        let deployedStrat
        let deployedGlobe

                // await controllerContract.connect(timelockSigner).approveStrategy(assetAddr,deployedStrat.address);
        // await controllerContract.connect(strategistSigner).setStrategy(assetAddr,deployedStrat.address);
        // await controllerContract.connect(strategistSigner).setGlobe(assetAddr,snowglobeAddr);