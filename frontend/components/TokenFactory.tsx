import { useState } from 'react';
import { useWeb3React } from '@web3-react/core';
import { ethers } from 'ethers';
import { TokenFactoryABI } from '../contracts/abis';

enum TokenCategory {
  FIAT,
  COMMODITY,
  EQUITY,
  CRYPTO,
  REAL_ESTATE,
  BOND,
  METAVERSE
}

export default function TokenFactory() {
  const { library, account } = useWeb3React();
  const [tokenName, setTokenName] = useState('');
  const [tokenSymbol, setTokenSymbol] = useState('');
  const [initialSupply, setInitialSupply] = useState('');
  const [category, setCategory] = useState<TokenCategory>(TokenCategory.FIAT);
  const [underlyingAsset, setUnderlyingAsset] = useState('');
  const [oracleAddress, setOracleAddress] = useState('');
  const [error, setError] = useState<string | null>(null);

  const createToken = async () => {
    try {
      setError(null);
      const contract = new ethers.Contract(
        process.env.NEXT_PUBLIC_TOKEN_FACTORY_ADDRESS!,
        TokenFactoryABI,
        library.getSigner()
      );

      const tx = await contract.deployToken(
        tokenName,
        tokenSymbol,
        category,
        underlyingAsset,
        oracleAddress
      );
      await tx.wait();
    } catch (error) {
      console.error('Error creating token:', error);
      setError(error instanceof Error ? error.message : 'Unknown error occurred');
    }
  };

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg p-6 mb-6">
      <h2 className="text-2xl font-bold mb-4">Create New Token</h2>
      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          {error}
        </div>
      )}
      <form onSubmit={(e) => { e.preventDefault(); createToken(); }} className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-1">Token Name</label>
          <input
            type="text"
            value={tokenName}
            onChange={(e) => setTokenName(e.target.value)}
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Token Symbol</label>
          <input
            type="text"
            value={tokenSymbol}
            onChange={(e) => setTokenSymbol(e.target.value)}
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Category</label>
          <select
            value={category}
            onChange={(e) => setCategory(Number(e.target.value))}
            className="w-full p-2 border rounded"
          >
            {Object.entries(TokenCategory)
              .filter(([key]) => isNaN(Number(key)))
              .map(([key, value]) => (
                <option key={key} value={value}>
                  {key}
                </option>
              ))}
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Underlying Asset</label>
          <input
            type="text"
            value={underlyingAsset}
            onChange={(e) => setUnderlyingAsset(e.target.value)}
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Oracle Address</label>
          <input
            type="text"
            value={oracleAddress}
            onChange={(e) => setOracleAddress(e.target.value)}
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <button
          type="submit"
          className="w-full bg-blue-500 text-white p-2 rounded hover:bg-blue-600"
        >
          Create Token
        </button>
      </form>
    </div>
  );
}
