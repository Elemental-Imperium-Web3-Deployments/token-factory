import { useEffect, useState } from 'react';
import { useWeb3React } from '@web3-react/core';
import TokenFactory from '../components/TokenFactory';
import LiquidityManager from '../components/LiquidityManager';
import CrossChainBridge from '../components/CrossChainBridge';

export default function Home() {
  const { account, chainId } = useWeb3React();
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    setIsConnected(!!account);
  }, [account]);

  return (
    <div className="min-h-screen bg-gray-100 dark:bg-gray-900">
      <main className="container mx-auto px-4 py-8">
        {!isConnected ? (
          <div className="text-center">
            <h1>Please connect your wallet</h1>
          </div>
        ) : (
          <>
            <TokenFactory />
            <LiquidityManager />
            <CrossChainBridge />
          </>
        )}
      </main>
    </div>
  );
}
