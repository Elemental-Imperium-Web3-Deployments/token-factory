import { Network, TatumSDK, Ethereum, ApiVersion } from "@tatumio/tatum";

export async function initializeWallet(contractAddress: string) {
    if (!process.env.TATUM_API_KEY) {
        throw new Error("TATUM_API_KEY environment variable is not set");
    }

    const tatum = await TatumSDK.init<Ethereum>({
        network: Network.ETHEREUM,
        apiKey: process.env.TATUM_API_KEY,
        version: ApiVersion.V4,
    });

    return {
        getBalance: async (address: string) => {
            try {
                const balance = await tatum.rpc.getBalance(address);
                return balance;
            } catch (error) {
                console.error("Error fetching balance:", error);
                throw error;
            }
        },
        
        getTokenBalance: async (address: string) => {
            try {
                const balance = await tatum.token.getBalance({
                    addresses: [address],
                    page: 1,
                    pageSize: 1
                });
                return balance.data[0];
            } catch (error) {
                console.error("Error fetching token balance:", error);
                throw error;
            }
        },

        destroy: async () => {
            await tatum.destroy();
        }
    };
}
