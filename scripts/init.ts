import { AptosAccount, AptosClient, HexString } from "aptos";
import {
  AccountAddress,
  ChainId,
  RawTransaction,
  ScriptFunction,
  TransactionPayloadScriptFunction,
} from "aptos/dist/transaction_builder/aptos_types";

const contractAddress =
  "459a8b92160d42060a3429884f29b38ab540a93755c5facbe070fdc160c7db63";
const DEVNET_URL = "https://fullnode.devnet.aptoslabs.com/v1";
const ADMIN_PRIV_KEY = new HexString(
  "0x87855d731f1f9e75d59b93f0d7cffb6893e17fd1b89b8dc4ce67f32c7ff103f6"
).toUint8Array();

const init = async () => {
  const aptosClient = new AptosClient(DEVNET_URL);
  const admin = new AptosAccount(ADMIN_PRIV_KEY);

  const scriptFunctionPayload = new TransactionPayloadScriptFunction(
    ScriptFunction.natural(`${contractAddress}::test`, "init", [], [])
  );
  const [{ sequence_number: sequenceNumber }, chainId] = await Promise.all([
    aptosClient.getAccount(contractAddress),
    aptosClient.getChainId(),
  ]);

  const rawTx = new RawTransaction(
    AccountAddress.fromHex(`0x${contractAddress}`),
    BigInt(sequenceNumber),
    scriptFunctionPayload,
    2000n,
    1n,
    BigInt(Math.floor(Date.now() / 1000) + 10),
    new ChainId(chainId)
  );

  const signedTx = AptosClient.generateBCSTransaction(admin, rawTx);
  const response = await aptosClient.submitSignedBCSTransaction(signedTx);
  await aptosClient.waitForTransaction(response.hash);
};
