import { Network, TatumSDK } from "@tatumio/tatum";

export async function initializeWallet(contractAddress: string) {
    const tatum = await TatumSDK.init({
        network: Network.ETHEREUM,
        apiKey: "t-679beee4212b5b9a7790fabd-8f4cab71868f4deb94ffb7a0",
    });

    return {
        getBalance: async (address: string) => {
            try {
                const balance = await tatum.address.getBalance({
                    addresses: [address],
                    tokenTypes: ["native"],
                });
                return balance.data[0];
            } catch (error) {
                console.error("Error fetching balance:", error);
                throw error;
            }
        },
        
        getTokenBalance: async (address: string) => {
            try {
                const balance = await tatum.token.getBalance({
                    addresses: [address],
                    contractAddress: contractAddress,
                });
                return balance.data[0];
            } catch (error) {
                console.error("Error fetching token balance:", error);
                throw error;
            }
        }
    };
}
